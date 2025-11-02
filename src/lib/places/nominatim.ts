/**
 * Shared Nominatim API utilities with rate limiting and retry logic
 * 
 * Rate limit: 1 request per second (Nominatim standard)
 * Includes retry logic with exponential backoff for network reliability
 */

import * as Nominatim from 'nominatim-ts'
import type { JSONPlace, AddressDetails, ExtraTags } from 'nominatim-ts/lib/types'
import type { PlaceDescriptors } from './types'
import { waitForRateLimit, withCache } from './index'

// Re-export nominatim-ts types for convenience
export type { JSONPlace, AddressDetails, ExtraTags }

/**
 * Type for search results with addressdetails and extratags enabled
 */
export type NominatimPlace = JSONPlace<{ addressdetails: 1; extratags: 1 }>

/**
 * Search for places using Nominatim API
 * 
 * @param query - Search query string
 * @param options - Search options (limit, addressdetails, extratags)
 * @returns Array of matching places
 */
export async function searchPlaces(
    query: string,
    options: {
        limit?: number
        addressdetails?: 0 | 1
        extratags?: 0 | 1
    } = {}
): Promise<NominatimPlace[]> {
    if (!query.trim()) {
        return []
    }

    const cacheKey = `nominatim-search:${query}:${JSON.stringify(options)}`

    return withCache(cacheKey, async () => {
        await waitForRateLimit()

        const results = await Nominatim.search({
            q: query,
            format: 'json',
            addressdetails: options.addressdetails ?? 1,
            extratags: options.extratags ?? 1,
            limit: options.limit ?? 5,
            acceptlanguage: 'en', // Force English results for better embeddings
        })
        return results
    }, 600000) // 10 minutes cache for place searches
}

/**
 * Query Nominatim for a single place with retry logic
 * 
 * @param placeName - Name of the place to search for
 * @param maxRetries - Maximum number of retry attempts (default: 3)
 * @returns Place descriptors or null if not found
 */
export async function queryPlaceWithRetry(
    placeName: string,
    maxRetries = 3
): Promise<PlaceDescriptors | null> {
    let lastError: Error | null = null

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            await waitForRateLimit()

            const results = await Nominatim.search({
                q: placeName,
                format: 'json',
                addressdetails: 1,
                extratags: 1,
                limit: 1,
                acceptlanguage: 'en', // Force English results for better embeddings
            })

            if (!results || results.length === 0) {
                return null
            }

            const result = results[0]
            if (!result) {
                return null
            }

            return {
                lat: parseFloat(result.lat),
                lng: parseFloat(result.lon),
                extratags: result.extratags || {},
                address: result.address || {},
                type: result.type || '',
                class: result.class || '',
                country_code: result.address?.country_code?.toLowerCase() || '',
            }
        } catch (error) {
            lastError = error instanceof Error ? error : new Error(String(error))

            const isNetworkError =
                lastError.message.includes('ETIMEDOUT') ||
                lastError.message.includes('EHOSTUNREACH') ||
                lastError.message.includes('ECONNREFUSED')

            if (isNetworkError && attempt < maxRetries) {
                const backoffMs = Math.min(1000 * Math.pow(2, attempt), 10000) // Exponential backoff, max 10s
                console.log('Network error querying place, retrying...', {
                    placeName,
                    attempt,
                    maxRetries,
                    backoffMs,
                })
                await new Promise(resolve => setTimeout(resolve, backoffMs))
            } else if (attempt === maxRetries) {
                console.error(
                    'Failed to query place after multiple attempts:',
                    { placeName, maxRetries, error: lastError }
                )
                throw lastError
            }
        }
    }

    return null
}

/**
 * Extract descriptors from a Nominatim place result
 * 
 * @param place - Nominatim place result
 * @returns Descriptors object for database storage
 */
export function extractDescriptors(place: NominatimPlace): PlaceDescriptors {
    return {
        lat: parseFloat(place.lat),
        lng: parseFloat(place.lon),
        country_code: place.address.country_code || '',
        type: place.type,
        class: place.class,
        address: place.address,
        extratags: place.extratags,
    }
}

// generatePlaceEmbeddingText moved to index.ts for centralized access


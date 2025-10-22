/**
 * Shared Nominatim API utilities with rate limiting and retry logic
 * 
 * Rate limit: 1 request per second (Nominatim standard)
 * Includes retry logic with exponential backoff for network reliability
 */

import * as Nominatim from 'nominatim-ts'
import type { JSONPlace, AddressDetails, ExtraTags } from 'nominatim-ts/lib/types'
import type { PlaceDescriptors } from './types'

// Re-export nominatim-ts types for convenience
export type { JSONPlace, AddressDetails, ExtraTags }

/**
 * Type for search results with addressdetails and extratags enabled
 */
export type NominatimPlace = JSONPlace<{ addressdetails: 1; extratags: 1 }>

// Rate limiting: 1 request per second
let lastRequestTime = 0
const MIN_REQUEST_INTERVAL = 1000

async function waitForRateLimit(): Promise<void> {
    const now = Date.now()
    const timeSinceLastRequest = now - lastRequestTime

    if (timeSinceLastRequest < MIN_REQUEST_INTERVAL) {
        await new Promise(resolve =>
            setTimeout(resolve, MIN_REQUEST_INTERVAL - timeSinceLastRequest)
        )
    }

    lastRequestTime = Date.now()
}

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

    await waitForRateLimit()

    const results = await Nominatim.search({
        q: query,
        format: 'json',
        addressdetails: options.addressdetails ?? 1,
        extratags: options.extratags ?? 1,
        limit: options.limit ?? 5,
    })

    return results as unknown as NominatimPlace[]
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
                console.log(
                    `Network error querying "${placeName}" (attempt ${attempt}/${maxRetries}), retrying in ${backoffMs}ms...`
                )
                await new Promise(resolve => setTimeout(resolve, backoffMs))
            } else if (attempt === maxRetries) {
                console.error(`Failed to query "${placeName}" after ${maxRetries} attempts:`, lastError.message)
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

/**
 * Generate embedding text from place data including enriched fields
 * Used for consistent embedding text generation across seed data and runtime
 * 
 * @param place - Place object with name and descriptors
 * @returns Formatted text string for embedding generation
 */
export function generatePlaceEmbeddingText(place: {
    name: string
    descriptors: Record<string, any>
}): string {
    const parts = [place.name]
    const desc = place.descriptors
    const ext = desc.extratags || {}

    // Basic info
    if (desc.type) {
        parts.push(`Type: ${desc.type}`)
    }
    if (desc.class) {
        parts.push(`Category: ${desc.class}`)
    }

    // Extratags - distinguishing characteristics
    if (ext.year_of_construction) {
        parts.push(`Built: ${ext.year_of_construction}`)
    }
    if (ext.start_date) {
        parts.push(`Built: ${ext.start_date}`)
    }
    if (ext.natural) {
        parts.push(`Natural feature: ${ext.natural}`)
    }
    if (ext.wikipedia) {
        // Extract just the title for embedding
        const wikiTitle = ext.wikipedia.split(':').pop()
        parts.push(`See: ${wikiTitle}`)
    }
    if (ext.architect) {
        parts.push(`Architect: ${ext.architect}`)
    }
    if (ext.heritage) {
        parts.push(`Heritage site`)
    }

    // Enriched elevation/height data
    if (desc.elevation_meters) {
        parts.push(`Elevation: ${desc.elevation_meters} meters`)
    }
    if (desc.height_meters) {
        parts.push(`Height: ${desc.height_meters} meters`)
    }
    if (ext.ele) {
        parts.push(`Elevation: ${ext.ele} meters`)
    }
    if (ext.height) {
        parts.push(`Height: ${ext.height} meters`)
    }

    // Location context
    if (desc.address?.city) {
        parts.push(`City: ${desc.address.city}`)
    }
    if (desc.address?.state) {
        parts.push(`State: ${desc.address.state}`)
    }
    if (desc.address?.country) {
        parts.push(`Country: ${desc.address.country}`)
    }

    return parts.join('. ')
}


/**
 * Overpass API Client
 * 
 * Queries OpenStreetMap data for building heights and detailed OSM tags.
 * Best for buildings, towers, and man-made structures.
 * 
 * @see https://overpass-api.de/
 */

import type { PlaceDescriptors } from './types'

interface OverpassElement {
    tags?: {
        height?: string
        [key: string]: any
    }
    [key: string]: any
}

interface OverpassResponse {
    elements?: OverpassElement[]
}

/**
 * Query Overpass API for building height near coordinates
 * 
 * @param lat - Latitude
 * @param lng - Longitude
 * @param radius - Search radius in meters (default: 20)
 * @returns Height in meters, or null if unavailable
 */
export async function getHeight(
    lat: number,
    lng: number,
    radius = 20
): Promise<number | null> {
    try {
        const query = `
      [out:json];
      (
        node(around:${radius},${lat},${lng})[height];
        way(around:${radius},${lat},${lng})[height];
      );
      out tags;
    `

        const response = await fetch('https://overpass-api.de/api/interpreter', {
            method: 'POST',
            body: query,
        })

        if (!response.ok) {
            console.warn(`Overpass API error: ${response.status} ${response.statusText}`)
            return null
        }

        const data: OverpassResponse = await response.json()

        // Find closest element with height tag
        if (data.elements && data.elements.length > 0) {
            for (const element of data.elements) {
                if (element.tags?.height) {
                    const height = parseFloat(element.tags.height)
                    if (!isNaN(height)) {
                        return height
                    }
                }
            }
        }

        return null
    } catch (error) {
        console.warn('Failed to fetch height:', error instanceof Error ? error.message : error)
        return null
    }
}

/**
 * Enrich a place with building height data
 * Only applies to buildings, towers, and similar structures
 * 
 * @param lat - Latitude
 * @param lng - Longitude
 * @param descriptors - Place descriptors from Nominatim
 * @returns Height in meters, or null if not applicable/unavailable
 */
export async function enrichWithHeight(
    lat: number,
    lng: number,
    descriptors: PlaceDescriptors
): Promise<number | null> {
    // Skip if already has height from OSM extratags
    if (descriptors.extratags?.height) {
        const height = parseFloat(descriptors.extratags.height)
        if (!isNaN(height)) {
            return height
        }
    }

    // Only enrich buildings and towers
    const isBuilding =
        descriptors.class === 'building' ||
        descriptors.type === 'tower' ||
        descriptors.type === 'office' ||
        descriptors.type === 'residential'

    if (!isBuilding) {
        return null
    }

    const height = await getHeight(lat, lng)

    if (height !== null) {
        console.log(`✓ Enriched height: ${height}m`)
    }

    return height
}


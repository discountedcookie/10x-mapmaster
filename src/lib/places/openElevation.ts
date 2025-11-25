/**
 * Open-Elevation API Client
 *
 * Provides elevation data for natural features like mountains, peaks, and hills.
 * Uses Open-Meteo's free elevation API (no authentication required).
 *
 * @see https://open-meteo.com/en/docs
 */

import type { PlaceDescriptors } from './types'

/**
 * Query Open-Elevation API for elevation data
 *
 * @param lat - Latitude
 * @param lng - Longitude
 * @returns Elevation in meters, or null if unavailable
 */
export async function getElevation(lat: number, lng: number): Promise<number | null> {
  try {
    const response = await fetch(
      `https://api.open-meteo.com/v1/elevation?latitude=${lat}&longitude=${lng}`
    )

    if (!response.ok) {
      console.warn(`Elevation API error: ${response.status} ${response.statusText}`)
      return null
    }

    const data = await response.json()

    if (data.elevation && Array.isArray(data.elevation) && data.elevation.length > 0) {
      const elevation = data.elevation[0]
      return elevation
    }

    return null
  } catch (error) {
    console.warn('Failed to fetch elevation:', error instanceof Error ? error.message : error)
    return null
  }
}

/**
 * Enrich a place with elevation data
 * Only applies to natural features (peaks, volcanoes, mountain ranges)
 *
 * @param lat - Latitude
 * @param lng - Longitude
 * @param descriptors - Place descriptors from Nominatim
 * @returns Elevation in meters, or null if not applicable/unavailable
 */
export async function enrichWithElevation(
  lat: number,
  lng: number,
  descriptors: PlaceDescriptors
): Promise<number | null> {
  // Skip if already has elevation from OSM extratags
  if (descriptors.extratags?.ele) {
    const elevation = Number.parseFloat(descriptors.extratags.ele)
    if (!isNaN(elevation)) {
      return elevation
    }
  }

  // Only enrich natural features
  const isNaturalFeature =
    descriptors.class === 'natural' ||
    descriptors.type === 'peak' ||
    descriptors.type === 'volcano' ||
    descriptors.type === 'mountain_range'

  if (!isNaturalFeature) {
    return null
  }

  const elevation = await getElevation(lat, lng)

  if (elevation !== null) {
    console.log(`✓ Enriched elevation: ${elevation}m`)
  }

  return elevation
}

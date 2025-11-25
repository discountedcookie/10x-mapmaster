import { search, lookup, type JSONPlace } from 'nominatim-ts'
import {
  extractTraitsFromNominatim,
  type NormalizedNominatimPlace,
  type TraitCandidate,
} from './traits.ts'

// Type for search results with all requested details including geometry
type SearchResult = JSONPlace<{
  format: 'json'
  addressdetails: 1
  extratags: 1
  namedetails: 1
  polygon_geojson: 1
}>

export interface NormalizedPlace extends NormalizedNominatimPlace {
  lat: number
  lng: number
  display_name: string
  english_name: string
  boundingbox: [string, string, string, string]
  extratags: Record<string, unknown>
  address: Record<string, unknown>
  namedetails: Record<string, unknown>
  osm_type: string
  osm_id: number
  geojson?: {
    type: 'Point' | 'Polygon' | 'MultiPolygon'
    coordinates: unknown
  }
}

function extractPlaceName(displayName: string, namedetails: Record<string, unknown>): string {
  // Try to get English name from namedetails first
  const englishFromDetails =
    (namedetails['name:en'] as string | undefined) ??
    (namedetails['official_name:en'] as string | undefined) ??
    (namedetails['int_name'] as string | undefined)

  if (englishFromDetails && englishFromDetails.trim().length > 0) {
    return englishFromDetails.trim()
  }

  // Fall back to extracting first part of comma-separated display_name
  // e.g., "Eiffel Tower, Paris, France" -> "Eiffel Tower"
  return displayName.split(',')[0].trim()
}

function normalizeResult(result: SearchResult): NormalizedPlace {
  const displayName = result.display_name
  const namedetails = result.namedetails as Record<string, unknown>
  const englishName = extractPlaceName(displayName, namedetails)

  const lat = Number.parseFloat(result.lat)
  const lng = Number.parseFloat(result.lon)

  // boundingbox is CoordinateString[4] from nominatim-ts, which is [string, string, string, string]
  const [minLat, maxLat, minLng, maxLng] = result.boundingbox
  const boundingbox: [string, string, string, string] = [minLat, maxLat, minLng, maxLng]

  // Extract GeoJSON geometry if available (Point, Polygon, MultiPolygon)
  const geojson = result.geojson
    ? {
        type: result.geojson.type as 'Point' | 'Polygon' | 'MultiPolygon',
        coordinates: result.geojson.coordinates,
      }
    : undefined

  return {
    lat,
    lng,
    display_name: displayName,
    english_name: englishName,
    type: result.type,
    class: result.class,
    boundingbox,
    address: result.address as Record<string, unknown>,
    extratags: result.extratags as Record<string, unknown>,
    osm_type: result.osm_type,
    osm_id: Number(result.osm_id),
    namedetails: result.namedetails as Record<string, unknown>,
    geojson,
  }
}

export async function enrichPlace(
  query: string,
  language = 'en', // Default to English
  limit = 1
): Promise<{ place: NormalizedPlace; traits: TraitCandidate[] } | null> {
  if (!query || query.trim().length === 0) {
    return null
  }

  try {
    const results = await search({
      q: query.trim(),
      format: 'json',
      addressdetails: 1,
      extratags: 1,
      namedetails: 1,
      polygon_geojson: 1,
      limit,
      acceptlanguage: language,
    })

    if (!results || results.length === 0) {
      return null
    }

    const normalized = normalizeResult(results[0])
    const traits = extractTraitsFromNominatim(normalized)

    return { place: normalized, traits }
  } catch (error) {
    console.error('Failed to enrich place', error)
    throw error instanceof Error ? error : new Error(String(error))
  }
}

export async function enrichPlaceByOsmId(
  osmId: string
): Promise<{ place: NormalizedPlace; traits: TraitCandidate[] } | null> {
  if (!osmId || osmId.trim().length === 0) {
    return null
  }

  try {
    // Convert "way/5013364" to "W5013364" format for Nominatim lookup API
    const [type, id] = osmId.split('/')
    const osmIdLookup = `${type[0].toUpperCase()}${id}`

    const results = await lookup({
      osm_ids: osmIdLookup,
      format: 'json',
      addressdetails: 1,
      extratags: 1,
      namedetails: 1,
      polygon_geojson: 1,
    })

    if (!results || results.length === 0) {
      return null
    }

    const normalized = normalizeResult(results[0])
    const traits = extractTraitsFromNominatim(normalized)

    return { place: normalized, traits }
  } catch (error) {
    console.error('Failed to enrich place by OSM ID', error)
    throw error instanceof Error ? error : new Error(String(error))
  }
}

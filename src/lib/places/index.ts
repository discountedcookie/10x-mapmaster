/**
 * Place utilities - unified exports
 * 
 * Clean barrel exports for all place-related functionality:
 * - Nominatim API client (search, geocoding, formatting)
 * - Open-Elevation API client (elevation data)
 * - Overpass API client (building heights)
 * - Type definitions
 */

// Nominatim client
export {
    searchPlaces,
    queryPlaceWithRetry,
    extractDescriptors,
    generatePlaceEmbeddingText,
    type NominatimPlace,
    type JSONPlace,
    type AddressDetails,
    type ExtraTags,
} from './nominatim'

// Open-Elevation client
export {
    getElevation,
    enrichWithElevation,
} from './openElevation'

// Overpass client
export {
    getHeight,
    enrichWithHeight,
} from './overpass'

// Types
export type {
    PlaceDescriptors,
} from './types'


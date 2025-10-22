/**
 * Shared types for place-related operations
 */

import type { AddressDetails, ExtraTags } from 'nominatim-ts/lib/types'

/**
 * Place descriptors for database storage
 * Combines Nominatim data with enrichment fields
 */
export interface PlaceDescriptors {
    // From Nominatim
    lat: number
    lng: number
    type: string
    class: string
    country_code: string
    address: AddressDetails
    extratags: ExtraTags
    // From enrichment APIs
    elevation_meters?: number
    height_meters?: number
    enrichment_timestamp?: string
    enrichment_source?: string
}


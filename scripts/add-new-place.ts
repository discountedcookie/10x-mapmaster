#!/usr/bin/env tsx

/**
 * Generate embeddings and enrich data for a new place and add it to the database.
 *
 * This script processes a new place name provided as a command-line argument:
 * 1. Queries Nominatim by name → get lat, lng, extratags
 * 2. Calls Open-Elevation API → get elevation (for natural features)
 * 3. Calls Overpass API → get building height (for structures)
 * 4. Calls Wikipedia API → get summary (rich context for embeddings)
 * 5. Merges data into descriptors JSONB
 * 6. Generates embedding text using enrichment functions
 * 7. Generates embedding via Supabase Edge Function
 * 8. Inserts the new place with all enriched data into the database
 *
 * Rate limit: 1 req/sec (Nominatim standard)
 *
 * Usage: npm run add-place "New Place Name"
 */

import { createClient } from '@supabase/supabase-js'
import type { Database } from '../src/types/database'
import {
    queryPlaceWithRetry,
    enrichWithElevation,
    enrichWithHeight,
    enrichWithWikipedia,
    generatePlaceEmbeddingText,
} from '../src/lib/places'

// Supabase connection
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'http://127.0.0.1:54321'
const supabaseKey = process.env.VITE_SUPABASE_SERVICE_KEY

if (!supabaseKey) {
    throw new Error('VITE_SUPABASE_SERVICE_KEY is required')
}

const supabase = createClient<Database>(supabaseUrl, supabaseKey)

/**
 * Generate embedding via Supabase Edge Function
 */
async function generateEmbedding(text: string): Promise<number[]> {
    const { data, error } = await supabase.functions.invoke('generate-embedding', {
        body: { text },
    })

    if (error) {
        throw new Error(`Failed to generate embedding: ${error.message}`)
    }

    if (!data?.embedding || !Array.isArray(data.embedding)) {
        throw new Error('Invalid embedding response')
    }

    return data.embedding
}

/**
 * Convert embedding array to PostgreSQL vector format
 */
function embeddingToString(embedding: number[]): string {
    return `[${embedding.join(',')}]`
}

/**
 * Process a single new place
 */
async function processNewPlace(placeName: string): Promise<boolean> {
    console.log(`\n📍 Processing: ${placeName}`)

    try {
        // Step 1: Query Nominatim for basic data (with retry logic)
        console.log('  → Querying Nominatim...')
        const nominatimData = await queryPlaceWithRetry(placeName, 3)

        if (!nominatimData) {
            console.error('  ❌ Failed to get data from Nominatim')
            return false
        }

        console.log(`  ✓ Found at: ${nominatimData.lat}, ${nominatimData.lng}`)

        // Step 2: Build initial descriptors
        const descriptors = {
            type: nominatimData.type,
            class: nominatimData.class,
            country_code: nominatimData.country_code,
            address: nominatimData.address,
            extratags: nominatimData.extratags,
        }

        // Step 3: Enrich with Open-Elevation
        console.log('  → Enriching with Open-Elevation...')
        const elevation = await enrichWithElevation(
            nominatimData.lat,
            nominatimData.lng,
            descriptors
        )

        // Step 4: Enrich with Overpass
        console.log('  → Enriching with Overpass...')
        const height = await enrichWithHeight(
            nominatimData.lat,
            nominatimData.lng,
            descriptors
        )

        // Step 5: Enrich with Wikipedia (only if we have Wikidata/Wikipedia identifiers)
        let wikipedia_summary: string | null = null
        if (descriptors.extratags?.wikidata || descriptors.extratags?.wikipedia) {
            console.log('  → Enriching with Wikipedia...')
            try {
                wikipedia_summary = await enrichWithWikipedia(
                    placeName,
                    descriptors.extratags
                )
                if (wikipedia_summary) {
                    console.log('  ✓ Wikipedia summary found')
                } else {
                    console.log('  ⊘ Wikipedia article not found')
                }
            } catch {
                console.log('  ⊘ Wikipedia article not found')
            }
        } else {
            console.log('  ⊘ Skipping Wikipedia (no Wikidata/Wikipedia ID in Nominatim)')
        }

        // Step 6: Merge all enrichment data
        const enrichedDescriptors = {
            ...descriptors,
            ...(elevation !== null && { elevation_meters: elevation }),
            ...(height !== null && { height_meters: height }),
            ...(wikipedia_summary && { wikipedia_summary }),
            enrichment_timestamp: new Date().toISOString(),
        }

        // Step 7: Generate embedding text
        const embeddingText = generatePlaceEmbeddingText({
            name: placeName,
            descriptors: enrichedDescriptors,
            wikipedia_summary,
        })

        console.log(`  → Embedding text: "${embeddingText}"`)

        // Step 8: Generate embedding
        console.log('  → Generating embedding...')
        const embedding = await generateEmbedding(embeddingText)

        // Step 9: Insert new place into database
        console.log('  → Inserting into database...')
        const { error: insertError } = await supabase
            .from('places')
            .insert({
                name: placeName,
                lat: nominatimData.lat,
                lng: nominatimData.lng,
                descriptors: enrichedDescriptors,
                embedding: embeddingToString(embedding) as any,
                embedding_text: embeddingText,
            })

        if (insertError) {
            console.error(`  ❌ Failed to insert place:`, insertError.message)
            return false
        }

        console.log(`  ✅ Successfully added ${placeName}`)
        return true
    } catch (error) {
        console.error(`  ❌ Error processing place:`, error)
        return false
    }
}

/**
 * Main function
 */
async function main() {
    const placeName = process.argv[2]

    if (!placeName) {
        console.error('❌ Please provide a place name as an argument.')
        console.log('Usage: npm run add-place "New Place Name"')
        process.exit(1)
    }

    console.log('🚀 Starting to add new place...')
    console.log(`Supabase URL: ${supabaseUrl}`)

    const success = await processNewPlace(placeName)

    if (success) {
        console.log('\n✅ Place added successfully!')
    } else {
        console.log('\n⚠️  Failed to add place. Review errors above.')
        process.exit(1)
    }
}

main()

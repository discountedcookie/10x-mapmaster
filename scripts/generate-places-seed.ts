#!/usr/bin/env tsx

/**
 * Generate embeddings and enrich data for seed places
 *
 * This script processes all places with NULL embeddings:
 * 1. Queries Nominatim by name → get lat, lng, extratags
 * 2. Calls Open-Elevation API → get elevation (for natural features)
 * 3. Calls Overpass API → get building height (for structures)
 * 4. Calls Wikipedia API → get summary (rich context for embeddings)
 * 5. Merges data into descriptors JSONB
 * 6. Generates embedding text using enrichment functions
 * 7. Generates embedding via Supabase Edge Function
 * 8. Updates place with all enriched data
 *
 * Rate limit: 1 req/sec (Nominatim standard)
 *
 * Usage: npm run seed:places
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
 * Process a single place
 */
async function processPlace(place: { id: string; name: string }): Promise<boolean> {
    console.log(`\n📍 Processing: ${place.name}`)

    try {
        // Step 1: Query Nominatim for basic data (with retry logic)
        console.log('  → Querying Nominatim...')
        const nominatimData = await queryPlaceWithRetry(place.name, 3)

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
                    place.name,
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
            ...(wikipedia_summary && { wikipedia_summary }), // NEW!
            enrichment_timestamp: new Date().toISOString(),
        }

        // Step 7: Generate embedding text (includes wikipedia_summary)
        const embeddingText = generatePlaceEmbeddingText({
            name: place.name,
            descriptors: enrichedDescriptors,
            wikipedia_summary, // NEW!
        })

        console.log(`  → Embedding text: "${embeddingText}"`)

        // Step 7: Generate embedding
        console.log('  → Generating embedding...')
        const embedding = await generateEmbedding(embeddingText)

        // Step 8: Update place in database
        console.log('  → Updating database...')
        const { error: updateError } = await supabase
            .from('places')
            .update({
                lat: nominatimData.lat,
                lng: nominatimData.lng,
                descriptors: enrichedDescriptors,
                embedding: embeddingToString(embedding) as any,
                embedding_text: embeddingText,
            })
            .eq('id', place.id)

        if (updateError) {
            console.error(`  ❌ Failed to update place:`, updateError.message)
            return false
        }

        console.log(`  ✅ Successfully processed ${place.name}`)
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
    console.log('🚀 Starting place seed data generation...')
    console.log(`Supabase URL: ${supabaseUrl}`)
    console.log('\n⚠️  This will take time due to rate limiting (1 req/sec for Nominatim)\n')

    try {
        // Fetch all places without embeddings
        const { data: places, error } = await supabase
            .from('places')
            .select('id, name')
            .is('embedding', null)
            .order('name')

        if (error) {
            throw new Error(`Failed to fetch places: ${error.message}`)
        }

        if (!places || places.length === 0) {
            console.log('✅ All places already have embeddings!')
            return
        }

        console.log(`Found ${places.length} places to process\n`)

        let successCount = 0
        let errorCount = 0

        for (const place of places) {
            const success = await processPlace(place)
            if (success) {
                successCount++
            } else {
                errorCount++
            }

            // Rate limit between places
            await new Promise(resolve => setTimeout(resolve, 100))
        }

        console.log('\n' + '='.repeat(60))
        console.log('📊 Summary:')
        console.log(`  ✅ Successful: ${successCount}`)
        console.log(`  ❌ Failed: ${errorCount}`)
        console.log('='.repeat(60))

        if (errorCount > 0) {
            console.log('\n⚠️  Some places failed to process. Review errors above.')
            process.exit(1)
        }

        console.log('\n✅ All places processed successfully!')
    } catch (error) {
        console.error('\n❌ Fatal error:', error)
        process.exit(1)
    }
}

main()


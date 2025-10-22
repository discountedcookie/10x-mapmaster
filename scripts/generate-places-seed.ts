#!/usr/bin/env tsx

/**
 * Generate embeddings and enrich data for seed places
 * 
 * This script processes all places with NULL embeddings:
 * 1. Queries Nominatim by name → get lat, lng, extratags
 * 2. Calls Open-Elevation API → get elevation (for natural features)
 * 3. Calls Overpass API → get building height (for structures)
 * 4. Merges data into descriptors JSONB
 * 5. Generates embedding text using enrichment functions
 * 6. Generates embedding via Supabase Edge Function
 * 7. Updates place with all enriched data
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
  generatePlaceEmbeddingText,
} from '../src/lib/places'

// Local database connection (where data will be stored)
const localUrl = process.env.VITE_SUPABASE_URL || 'http://127.0.0.1:54321'
const localServiceKey = process.env.VITE_SUPABASE_SERVICE_KEY

// Production function endpoint (where embeddings will be generated)
const prodFunctionsUrl = process.env.VITE_SUPABASE_FUNCTIONS_URL_PROD
const prodAnonKey = process.env.VITE_SUPABASE_ANON_KEY_PROD

if (!localServiceKey) {
    console.error('Error: VITE_SUPABASE_SERVICE_KEY is required')
    console.error('Make sure .env.local is set up correctly')
    process.exit(1)
}

if (!prodFunctionsUrl || !prodAnonKey) {
    console.error('Error: Production Supabase credentials required for embedding generation')
    console.error('Please set VITE_SUPABASE_FUNCTIONS_URL_PROD and VITE_SUPABASE_ANON_KEY_PROD')
    process.exit(1)
}

// Extract base URL from functions URL
const prodUrl = prodFunctionsUrl.replace(/\/functions\/v1$/, '')

const localSupabase = createClient<Database>(localUrl, localServiceKey)
const prodSupabase = createClient(prodUrl, prodAnonKey)


/**
 * Generate embedding for text using production Edge Function
 */
async function generateEmbedding(text: string): Promise<number[]> {
    const { data, error } = await prodSupabase.functions.invoke('generate-embedding', {
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

    // Step 5: Merge all enrichment data
    const enrichedDescriptors = {
      ...descriptors,
      ...(elevation !== null && { elevation_meters: elevation }),
      ...(height !== null && { height_meters: height }),
      enrichment_timestamp: new Date().toISOString(),
    }

    // Step 6: Generate embedding text
    const embeddingText = generatePlaceEmbeddingText({
      name: place.name,
      descriptors: enrichedDescriptors,
    })

    console.log(`  → Embedding text: "${embeddingText}"`)

    // Step 7: Generate embedding
    console.log('  → Generating embedding...')
    const embedding = await generateEmbedding(embeddingText)

    // Step 8: Update place in database
    console.log('  → Updating database...')
        const { error: updateError } = await localSupabase
            .from('places')
            .update({
                lat: nominatimData.lat,
                lng: nominatimData.lng,
                descriptors: enrichedDescriptors,
                embedding: embeddingToString(embedding) as any,
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
    console.log(`Local Database: ${localUrl}`)
    console.log(`Production Edge Function: ${prodFunctionsUrl}/generate-embedding`)
    console.log('\n⚠️  This will take time due to rate limiting (1 req/sec for Nominatim)\n')

    try {
        // Fetch all places without embeddings
        const { data: places, error } = await localSupabase
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


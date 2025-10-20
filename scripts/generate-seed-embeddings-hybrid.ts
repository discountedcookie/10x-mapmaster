#!/usr/bin/env tsx

/**
 * Generate embeddings for seed data (places and questions)
 * Hybrid approach: Local database + Production Edge Function
 * 
 * Usage: PROD_URL=https://xxx.supabase.co PROD_KEY=xxx npm run seed:embeddings:hybrid
 */

import { createClient } from '@supabase/supabase-js'
import type { Database } from '../src/types/database'

// Local database connection (where embeddings will be stored)
const localUrl = process.env.VITE_SUPABASE_URL
const localServiceKey = process.env.VITE_SUPABASE_SERVICE_KEY

// Production function endpoint (where embeddings will be generated)
const prodFunctionsUrl = process.env.VITE_SUPABASE_FUNCTIONS_URL_PROD
const prodKey = process.env.VITE_SUPABASE_ANON_KEY_PROD

if (!localUrl || !localServiceKey) {
    console.error('Error: Missing VITE_SUPABASE_URL or VITE_SUPABASE_SERVICE_KEY environment variables')
    console.error('Make sure .env.local is set up correctly')
    process.exit(1)
}

if (!prodFunctionsUrl || !prodKey) {
    console.error('Error: Missing VITE_SUPABASE_FUNCTIONS_URL_PROD or VITE_SUPABASE_ANON_KEY_PROD environment variables')
    console.error('Make sure .env.local is set up correctly')
    process.exit(1)
}

// Extract base URL from functions URL (remove /functions/v1)
const prodUrl = prodFunctionsUrl.replace(/\/functions\/v1$/, '')

const localSupabase = createClient<Database>(localUrl, localServiceKey)
const prodSupabase = createClient(prodUrl, prodKey)

/**
 * Generate embedding for text using production Edge Function
 */
async function generateEmbedding(text: string): Promise<number[]> {
    console.log(`Generating embedding for: "${text.substring(0, 50)}..."`)

    const { data, error } = await prodSupabase.functions.invoke('generate-embedding', {
        body: { text }
    })

    if (error) {
        throw new Error(`Failed to generate embedding: ${error.message}`)
    }

    if (!data || !Array.isArray(data.embedding)) {
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
 * Generate embeddings for all places
 */
async function generatePlaceEmbeddings() {
    console.log('\n📍 Generating embeddings for places...')

    // Fetch all places without embeddings from LOCAL database
    const { data: places, error } = await localSupabase
        .from('places')
        .select('*')
        .is('embedding', null)

    if (error) {
        throw new Error(`Failed to fetch places: ${error.message}`)
    }

    if (!places || places.length === 0) {
        console.log('✅ All places already have embeddings')
        return
    }

    console.log(`Found ${places.length} places without embeddings`)

    for (const place of places) {
        try {
            // Create descriptive text from place name and descriptors
            const descriptors = place.descriptors as any
            const textParts = [place.name]

            if (descriptors?.type) {
                textParts.push(`Type: ${descriptors.type}`)
            }
            if (descriptors?.class) {
                textParts.push(`Category: ${descriptors.class}`)
            }
            if (descriptors?.address?.city) {
                textParts.push(`City: ${descriptors.address.city}`)
            }
            if (descriptors?.address?.country) {
                textParts.push(`Country: ${descriptors.address.country}`)
            }

            const text = textParts.join('. ')

            // Generate embedding using PRODUCTION Edge Function
            const embedding = await generateEmbedding(text)

            // Update place with embedding in LOCAL database
            const { error: updateError } = await localSupabase
                .from('places')
                .update({ embedding: embeddingToString(embedding) as any })
                .eq('id', place.id)

            if (updateError) {
                console.error(`❌ Failed to update place ${place.name}:`, updateError.message)
                continue
            } else {
                console.log(`✅ Generated embedding for: ${place.name}`)
            }

            // Rate limiting - wait 100ms between requests
            await new Promise(resolve => setTimeout(resolve, 100))
        } catch (error) {
            console.error(`❌ Error processing place ${place.name}:`, error)
        }
    }

    console.log('✅ Place embeddings generated')
}

/**
 * Generate embeddings for all questions
 */
async function generateQuestionEmbeddings() {
    console.log('\n❓ Generating embeddings for questions...')

    // Fetch all questions without embeddings from LOCAL database
    const { data: questions, error } = await localSupabase
        .from('questions')
        .select('*')
        .is('embedding', null)

    if (error) {
        throw new Error(`Failed to fetch questions: ${error.message}`)
    }

    if (!questions || questions.length === 0) {
        console.log('✅ All questions already have embeddings')
        return
    }

    console.log(`Found ${questions.length} questions without embeddings`)

    for (const question of questions) {
        try {
            // Use question text directly for embedding
            const embedding = await generateEmbedding(question.text)

            // Update question with embedding in LOCAL database
            const { error: updateError } = await localSupabase
                .from('questions')
                .update({ embedding: embeddingToString(embedding) as any })
                .eq('id', question.id)

            if (updateError) {
                console.error(`❌ Failed to update question "${question.text}":`, updateError.message)
            } else {
                console.log(`✅ Generated embedding for: "${question.text}"`)
            }

            // Rate limiting - wait 100ms between requests
            await new Promise(resolve => setTimeout(resolve, 100))
        } catch (error) {
            console.error(`❌ Error processing question "${question.text}":`, error)
        }
    }

    console.log('✅ Question embeddings generated')
}

/**
 * Main function
 */
async function main() {
    console.log('🚀 Starting hybrid seed embedding generation...')
    console.log(`Local Database: ${localUrl}`)
    console.log(`Production Edge Function: ${prodFunctionsUrl}/generate-embedding`)

    try {
        await generatePlaceEmbeddings()
        await generateQuestionEmbeddings()

        console.log('\n✅ All embeddings generated successfully!')
        console.log('You can now test the game locally with vector similarity search.')
    } catch (error) {
        console.error('\n❌ Error generating embeddings:', error)
        process.exit(1)
    }
}

main()


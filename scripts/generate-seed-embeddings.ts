#!/usr/bin/env tsx

/**
 * Generate embeddings for seed data (places and questions)
 * Run this script after applying the vector embeddings migration
 * 
 * Usage: npm run seed:embeddings
 */

import { createClient } from '@supabase/supabase-js'
import type { Database } from '../src/types/database'

const supabaseUrl = process.env.VITE_SUPABASE_URL
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
    console.error('Error: Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY environment variables')
    console.error('Make sure .env.local is set up correctly')
    process.exit(1)
}

const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey)

/**
 * Generate embedding for text using the Edge Function
 */
async function generateEmbedding(text: string): Promise<number[]> {
    console.log(`Generating embedding for: "${text.substring(0, 50)}..."`)

    const { data, error } = await supabase.functions.invoke('generate-embedding', {
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

    // Fetch all places without embeddings
    const { data: places, error } = await supabase
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
            const embedding = await generateEmbedding(text)

            // Update place with embedding
            const { error: updateError } = await supabase
                .from('places')
                .update({ embedding: embeddingToString(embedding) as any })
                .eq('id', place.id)

            if (updateError) {
                console.error(`❌ Failed to update place ${place.name}:`, updateError.message)
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

    // Fetch all questions without embeddings
    const { data: questions, error } = await supabase
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

            // Update question with embedding
            const { error: updateError } = await supabase
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
    console.log('🚀 Starting seed embedding generation...')
    console.log(`Using Supabase URL: ${supabaseUrl}`)

    try {
        await generatePlaceEmbeddings()
        await generateQuestionEmbeddings()

        console.log('\n✅ All embeddings generated successfully!')
        console.log('You can now use vector similarity search in the application.')
    } catch (error) {
        console.error('\n❌ Error generating embeddings:', error)
        process.exit(1)
    }
}

main()







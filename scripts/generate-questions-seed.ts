#!/usr/bin/env tsx

/**
 * Generate embeddings for semantic questions
 * 
 * This script processes all semantic questions (question_type = 'semantic'):
 * 1. Generates embedding via Supabase Edge Function using question text
 * 2. Updates question with embedding
 * 
 * Note: Geographic questions don't need embeddings (they use PostGIS)
 * 
 * Usage: npm run seed:questions
 */

import { createClient } from '@supabase/supabase-js'
import type { Database } from '../src/types/database'

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
 * Process a single question
 */
async function processQuestion(question: { id: string; text: string }): Promise<boolean> {
    try {
        console.log(`\n❓ Processing: "${question.text}"`)

        // Generate embedding
        console.log('  → Generating embedding...')
        const embedding = await generateEmbedding(question.text)

        // Update question in database
        console.log('  → Updating database...')
        const { error: updateError } = await localSupabase
            .from('questions')
            .update({
                embedding: embeddingToString(embedding) as any,
            })
            .eq('id', question.id)

        if (updateError) {
            console.error(`  ❌ Failed to update question:`, updateError.message)
            return false
        }

        console.log(`  ✅ Success`)
        return true
    } catch (error) {
        console.error(`  ❌ Error processing question:`, error)
        return false
    }
}

/**
 * Main function
 */
async function main() {
    console.log('🚀 Starting question seed data generation...')
    console.log(`Local Database: ${localUrl}`)
    console.log(`Production Edge Function: ${prodFunctionsUrl}/generate-embedding`)
    console.log()

    try {
        // Fetch all semantic questions without embeddings
        const { data: questions, error } = await localSupabase
            .from('questions')
            .select('id, text')
            .eq('question_type', 'semantic')
            .is('embedding', null)

        if (error) {
            throw new Error(`Failed to fetch questions: ${error.message}`)
        }

        if (!questions || questions.length === 0) {
            console.log('✅ All semantic questions already have embeddings!')
            return
        }

        console.log(`Found ${questions.length} semantic questions to process\n`)

        let successCount = 0
        let errorCount = 0

        for (const question of questions) {
            const success = await processQuestion(question)
            if (success) {
                successCount++
            } else {
                errorCount++
            }

            // Rate limit between requests (100ms)
            await new Promise(resolve => setTimeout(resolve, 100))
        }

        console.log('\n' + '='.repeat(60))
        console.log('📊 Summary:')
        console.log(`  ✅ Successful: ${successCount}`)
        console.log(`  ❌ Failed: ${errorCount}`)
        console.log('='.repeat(60))

        if (errorCount > 0) {
            console.log('\n⚠️  Some questions failed to process. Review errors above.')
            process.exit(1)
        }

        console.log('\n✅ All questions processed successfully!')
    } catch (error) {
        console.error('\n❌ Fatal error:', error)
        process.exit(1)
    }
}

main()


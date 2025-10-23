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

// Supabase connection
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'http://127.0.0.1:54321'
const supabaseKey = process.env.VITE_SUPABASE_SERVICE_KEY

if (!supabaseKey) {
    console.error('Error: VITE_SUPABASE_SERVICE_KEY is required')
    process.exit(1)
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
        const { error: updateError } = await supabase
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
    console.log(`Supabase URL: ${supabaseUrl}`)
    console.log()

    try {
        // Fetch all semantic questions without embeddings
        const { data: questions, error } = await supabase
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


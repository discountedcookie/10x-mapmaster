#!/usr/bin/env tsx

/**
 * Generate SQL migration file with embeddings for seed data (places and questions)
 * Hybrid approach: Local database + Production Edge Function
 *
 * Reads seed data from local database, generates embeddings via production Edge Function,
 * and outputs a reusable SQL migration file.
 *
 * Usage: PROD_URL=https://xxx.supabase.co PROD_KEY=xxx npm run generate:seed-migration
 */

import { createClient } from '@supabase/supabase-js'
import { writeFile } from 'fs/promises'
import { join } from 'path'
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
 * Generate embeddings and SQL statements for all places
 */
async function generatePlaceEmbeddings(): Promise<string[]> {
    console.log('\n📍 Generating embeddings for places...')

    const sqlStatements: string[] = []

    // Fetch all places from LOCAL database
    const { data: places, error } = await localSupabase
        .from('places')
        .select('*')
        .order('name')

    if (error) {
        throw new Error(`Failed to fetch places: ${error.message}`)
    }

    if (!places || places.length === 0) {
        console.log('⚠️  No places found in database')
        return sqlStatements
    }

    console.log(`Found ${places.length} places to process`)

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

            // Create SQL UPDATE statement
            const escapedName = place.name.replace(/'/g, "''")
            const sql = `UPDATE places SET embedding = '${embeddingToString(embedding)}'::vector WHERE name = '${escapedName}';`
            sqlStatements.push(sql)

            console.log(`✅ Generated embedding for: ${place.name}`)

            // Rate limiting - wait 100ms between requests
            await new Promise(resolve => setTimeout(resolve, 100))
        } catch (error) {
            console.error(`❌ Error processing place ${place.name}:`, error)
            throw error // Stop on error to avoid partial migration
        }
    }

    console.log(`✅ Generated ${sqlStatements.length} place embedding statements`)
    return sqlStatements
}

/**
 * Generate embeddings and SQL statements for all questions
 */
async function generateQuestionEmbeddings(): Promise<string[]> {
    console.log('\n❓ Generating embeddings for questions...')

    const sqlStatements: string[] = []

    // Fetch all questions from LOCAL database
    const { data: questions, error } = await localSupabase
        .from('questions')
        .select('*')
        .order('sequence')

    if (error) {
        throw new Error(`Failed to fetch questions: ${error.message}`)
    }

    if (!questions || questions.length === 0) {
        console.log('⚠️  No questions found in database')
        return sqlStatements
    }

    console.log(`Found ${questions.length} questions to process`)

    for (const question of questions) {
        try {
            // Use question text directly for embedding
            const embedding = await generateEmbedding(question.text)

            // Create SQL UPDATE statement
            const escapedText = question.text.replace(/'/g, "''")
            const sql = `UPDATE questions SET embedding = '${embeddingToString(embedding)}'::vector WHERE text = '${escapedText}';`
            sqlStatements.push(sql)

            console.log(`✅ Generated embedding for: "${question.text}"`)

            // Rate limiting - wait 100ms between requests
            await new Promise(resolve => setTimeout(resolve, 100))
        } catch (error) {
            console.error(`❌ Error processing question "${question.text}":`, error)
            throw error // Stop on error to avoid partial migration
        }
    }

    console.log(`✅ Generated ${sqlStatements.length} question embedding statements`)
    return sqlStatements
}

/**
 * Main function
 */
async function main() {
    console.log('🚀 Starting SQL migration generation for seed embeddings...')
    console.log(`Local Database: ${localUrl}`)
    console.log(`Production Edge Function: ${prodFunctionsUrl}/generate-embedding`)

    try {
        const placeStatements = await generatePlaceEmbeddings()
        const questionStatements = await generateQuestionEmbeddings()

        // Build SQL migration file content
        const migrationHeader = `-- Generated seed embeddings for places and questions
-- This migration is generated by scripts/generate-seed-embeddings-hybrid.ts
-- DO NOT manually edit this file - regenerate it using: npm run generate:seed-migration
--
-- Generated: ${new Date().toISOString()}
-- Places: ${placeStatements.length}
-- Questions: ${questionStatements.length}

`

        const placesSection = `-- Update embeddings for seed places
${placeStatements.join('\n')}

`

        const questionsSection = `-- Update embeddings for seed questions
${questionStatements.join('\n')}
`

        const migrationContent = migrationHeader + placesSection + questionsSection

        // Write to migration file
        const migrationPath = join(process.cwd(), 'supabase', 'migrations', '000003_seed_embeddings.sql')
        await writeFile(migrationPath, migrationContent, 'utf-8')

        console.log(`\n✅ Migration file generated successfully!`)
        console.log(`📄 Location: ${migrationPath}`)
        console.log(`📊 Total statements: ${placeStatements.length + questionStatements.length}`)
        console.log(`\n🎯 Next steps:`)
        console.log(`   1. Review the generated SQL file`)
        console.log(`   2. Run: npx supabase db reset`)
        console.log(`   3. Embeddings will be applied automatically via migration`)
    } catch (error) {
        console.error('\n❌ Error generating migration:', error)
        process.exit(1)
    }
}

main()


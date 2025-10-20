/**
 * Generates embeddings for questions and places
 *
 * This script:
 * 1. Generates embeddings for all questions (from question text)
 * 2. Generates embeddings for all places (from descriptor_text)
 *
 * Run with: npm run generate:embeddings
 */

import { createClient } from '@supabase/supabase-js'
import type { Database } from '../src/types/database'

const localUrl = process.env.VITE_SUPABASE_URL || 'http://127.0.0.1:54321'
const localServiceKey = process.env.VITE_SUPABASE_SERVICE_KEY!
const prodUrl = process.env.VITE_SUPABASE_FUNCTIONS_URL_PROD
const prodAnonKey = process.env.VITE_SUPABASE_ANON_KEY_PROD

if (!localServiceKey) {
  console.error('Error: VITE_SUPABASE_SERVICE_KEY is required')
  process.exit(1)
}

if (!prodUrl || !prodAnonKey) {
  console.error('Error: Production Supabase credentials required for embedding generation')
  console.error('Please set VITE_SUPABASE_FUNCTIONS_URL_PROD and VITE_SUPABASE_ANON_KEY_PROD')
  process.exit(1)
}

// Local client for data operations
const supabase = createClient<Database>(localUrl, localServiceKey)

// Production client for Edge Function calls
const baseUrl = prodUrl.replace('/functions/v1', '')
const supabaseProd = createClient(baseUrl, prodAnonKey)

async function generateEmbedding(text: string): Promise<number[]> {
  const { data, error } = await supabaseProd.functions.invoke('generate-embedding', {
    body: { input: text }
  })

  if (error) {
    throw new Error(`Failed to generate embedding: ${error.message}`)
  }

  if (!data || !Array.isArray(data)) {
    throw new Error('Invalid embedding response')
  }

  return data
}

function embeddingToString(embedding: number[]): string {
  return `[${embedding.join(',')}]`
}

async function generateQuestionEmbeddings() {
  console.log('\n📝 Generating question embeddings...\n')

  const { data: questions, error } = await supabase
    .from('questions')
    .select('id, text')
    .order('sequence')

  if (error) {
    console.error('Error fetching questions:', error)
    throw error
  }

  if (!questions || questions.length === 0) {
    console.log('No questions found.')
    return
  }

  let successCount = 0
  let errorCount = 0

  for (const question of questions) {
    try {
      console.log(`Generating embedding for: "${question.text}"`)

      const embedding = await generateEmbedding(question.text)

      const { error: updateError } = await supabase
        .from('questions')
        .update({ embedding: embeddingToString(embedding) })
        .eq('id', question.id)

      if (updateError) {
        throw updateError
      }

      console.log(`  ✅ Success\n`)
      successCount++

      // Rate limit: 1 request per second
      await new Promise(resolve => setTimeout(resolve, 1000))
    } catch (err) {
      console.error(`  ❌ Error:`, err)
      errorCount++
    }
  }

  console.log(`\nQuestion embeddings: ${successCount} succeeded, ${errorCount} failed\n`)
}

async function generatePlaceEmbeddings() {
  console.log('\n🗺️  Generating place embeddings...\n')

  const { data: places, error } = await supabase
    .from('places')
    .select('id, name, descriptor_text')
    .order('name')

  if (error) {
    console.error('Error fetching places:', error)
    throw error
  }

  if (!places || places.length === 0) {
    console.log('No places found.')
    return
  }

  let successCount = 0
  let errorCount = 0

  for (const place of places) {
    try {
      if (!place.descriptor_text) {
        console.log(`⚠️  Skipping ${place.name}: No descriptor_text (run enrich script first)`)
        continue
      }

      console.log(`Generating embedding for: ${place.name}`)
      console.log(`  Using descriptor: "${place.descriptor_text}"`)

      const embedding = await generateEmbedding(place.descriptor_text)

      const { error: updateError } = await supabase
        .from('places')
        .update({ embedding: embeddingToString(embedding) })
        .eq('id', place.id)

      if (updateError) {
        throw updateError
      }

      console.log(`  ✅ Success\n`)
      successCount++

      // Rate limit: 1 request per second
      await new Promise(resolve => setTimeout(resolve, 1000))
    } catch (err) {
      console.error(`  ❌ Error:`, err)
      errorCount++
    }
  }

  console.log(`\nPlace embeddings: ${successCount} succeeded, ${errorCount} failed\n`)
}

async function main() {
  console.log('🚀 Starting embedding generation...')
  console.log('Using production Edge Function for embeddings')
  console.log('Using local database for storage')

  try {
    await generateQuestionEmbeddings()
    await generatePlaceEmbeddings()

    console.log('✨ Done! All embeddings generated.')
  } catch (error) {
    console.error('Fatal error:', error)
    process.exit(1)
  }
}

main().catch(console.error)

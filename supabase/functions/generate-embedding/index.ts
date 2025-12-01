import { Ollama } from 'npm:ollama@0.5.9'
import { GenerateEmbeddingRequest } from '../types/schemas.ts'

console.log('✓ Module loading started')

// Spec: 384d embeddings (gte-small compatible)
// Development: Ollama with all-minilm (384d)
// Production: Supabase gte-small (384d)
const EMBEDDING_PROVIDER = Deno.env.get('EMBEDDING_PROVIDER') || 'ollama'
const OLLAMA_HOST = Deno.env.get('OLLAMA_HOST') || 'http://host.docker.internal:11434'
const OLLAMA_MODEL = Deno.env.get('OLLAMA_EMBEDDING_MODEL') || 'all-minilm'
const EXPECTED_DIMENSIONS = 384

console.log(`✓ Constants initialized (provider: ${EMBEDDING_PROVIDER}, model: ${OLLAMA_MODEL})`)

Deno.serve(async (request: Request) => {
  console.log('✓ Handler invoked')
  try {
    console.log(`✓ Request method: ${request.method}`)

    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    console.log('✓ About to parse request body')
    const body = await request.json()
    console.log('✓ Request body parsed successfully')

    // Validate request with Zod schema
    let validated
    try {
      validated = GenerateEmbeddingRequest.parse(body)
    } catch (error) {
      console.log(
        '✗ Request validation failed:',
        error instanceof Error ? error.message : String(error)
      )
      return new Response(
        JSON.stringify({
          error:
            'Invalid request: text field is required and must be a non-empty string (max 10000 chars)',
        }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    const { text } = validated
    console.log(`✓ Text received: "${text.slice(0, 30)}..."`)
    console.log(`Generating ${EXPECTED_DIMENSIONS}d embedding for text: "${text.slice(0, 50)}..."`)

    console.log('✓ About to call Ollama API via ollama-js library')
    const ollama = new Ollama({ host: OLLAMA_HOST })

    const response = await ollama.embeddings({
      model: OLLAMA_MODEL,
      prompt: text.trim(),
    })

    console.log(`✓ Ollama API responded successfully`)

    const embedding = response.embedding

    if (!embedding || !Array.isArray(embedding)) {
      throw new Error('Invalid response from Ollama API: missing or invalid embedding')
    }

    if (embedding.length !== EXPECTED_DIMENSIONS) {
      throw new Error(
        `Invalid embedding dimensions: expected ${EXPECTED_DIMENSIONS}, got ${embedding.length}. ` +
          `Ensure OLLAMA_EMBEDDING_MODEL is set to a 384d model (e.g., all-minilm)`
      )
    }

    console.log(`Successfully generated ${embedding.length}-dimensional embedding`)

    return new Response(JSON.stringify({ embedding }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('✗ Error generating embedding:', error)
    console.error('✗ Error stack:', error instanceof Error ? error.stack : 'No stack trace')
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  }
})

console.log('✓ Deno.serve registered - module loaded successfully')

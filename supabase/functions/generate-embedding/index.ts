import { GenerateEmbeddingRequest } from '../types/schemas.ts'

console.log('✓ Module loading started')

// Hugging Face all-MiniLM-L6-v2 (384d)
// Symmetric model - no prefix needed, best English discrimination
const HF_TOKEN = Deno.env.get('HF_TOKEN') || ''
const HF_MODEL = 'sentence-transformers/all-MiniLM-L6-v2'
const HF_API_URL = `https://router.huggingface.co/hf-inference/models/${HF_MODEL}/pipeline/feature-extraction`
const EXPECTED_DIMENSIONS = 384

console.log(`✓ Constants initialized (model: ${HF_MODEL})`)

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

    if (!HF_TOKEN) {
      throw new Error('HF_TOKEN environment variable is required')
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

    const { text, inputType } = validated
    console.log(`✓ Text received: "${text.slice(0, 30)}..."`)
    console.log(`✓ Input type: ${inputType}`)
    console.log(`Generating ${EXPECTED_DIMENSIONS}d embedding for text: "${text.slice(0, 50)}..."`)

    // GTE is symmetric - no prefix needed
    const prefixedText = text.trim()

    console.log('✓ About to call Hugging Face API')
    const response = await fetch(HF_API_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${HF_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        inputs: prefixedText,
      }),
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`Hugging Face API error (${response.status}): ${errorText}`)
    }

    const result = await response.json()
    console.log(`✓ Hugging Face API responded successfully`)

    // HF returns array directly for single input
    const embedding = Array.isArray(result) ? result : result.embeddings?.[0]

    if (!embedding || !Array.isArray(embedding)) {
      throw new Error(
        `Invalid response from Hugging Face API: ${JSON.stringify(result).slice(0, 200)}`
      )
    }

    if (embedding.length !== EXPECTED_DIMENSIONS) {
      throw new Error(
        `Invalid embedding dimensions: expected ${EXPECTED_DIMENSIONS}, got ${embedding.length}`
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

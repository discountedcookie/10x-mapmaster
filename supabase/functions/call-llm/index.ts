import { Ollama } from 'npm:ollama@0.5.9'

console.log('✓ call-llm module loading started')

const OLLAMA_HOST = Deno.env.get('OLLAMA_HOST') || 'http://host.docker.internal:11434'

console.log('✓ Constants initialized')

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
    const { prompt, format, model, options } = await request.json()
    console.log('✓ Request body parsed successfully')

    if (!prompt || typeof prompt !== 'string' || prompt.trim().length === 0) {
      console.log('✗ prompt validation failed')
      return new Response(
        JSON.stringify({ error: 'prompt field is required and must be non-empty string' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    const modelOptions = options || {}

    console.log('✓ Input validated')
    console.log('=== PROMPT BEING SENT TO LLM ===')
    console.log(prompt)
    console.log('=== END PROMPT ===')
    console.log(`Model: ${model}`)
    console.log(`Format: ${format || 'none'}`)
    console.log(`Options: ${JSON.stringify(modelOptions, null, 2)}`)

    const ollama = new Ollama({ host: OLLAMA_HOST })

    const response = await ollama.generate({
      model,
      prompt: prompt.trim(),
      stream: false,
      format: format || undefined,
      options: modelOptions,
    })

    console.log('✓ Ollama API responded successfully')
    console.log('=== RAW LLM RESPONSE ===')
    console.log(response.response)
    console.log('=== END RESPONSE ===')

    return new Response(
      JSON.stringify({
        response: response.response,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('✗ Error calling LLM:', error)
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

console.log('✓ Deno.serve registered - call-llm module loaded successfully')

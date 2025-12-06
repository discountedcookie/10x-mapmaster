import OpenAI from 'https://deno.land/x/openai@v4.24.0/mod.ts'
import { CallLlmRequest, CallLlmRequestType } from '../types/schemas.ts'

console.log('✓ call-llm module loading started')

/**
 * Sanitize LLM output by removing HTML tags, artifacts, and normalizing whitespace
 */
function sanitizeOutput(text: string): string {
  if (!text) return ''

  // Remove HTML tags (e.g., <s>, </s>, <br>, etc.)
  let result = text.replace(/<[^>]*>/g, '')

  // Remove common LLM artifacts
  const artifacts = [
    /\[OUT\]/g,
    /\[\/OUT\]/g,
    /\[INST\]/g,
    /\[\/INST\]/g,
    /<\|im_start\|>/g,
    /<\|im_end\|>/g,
    /<\|endoftext\|>/g,
  ]

  for (const pattern of artifacts) {
    result = result.replace(pattern, '')
  }

  // Normalize whitespace: collapse multiple spaces and newlines
  result = result.replace(/\s+/g, ' ')

  // Trim leading/trailing whitespace
  result = result.trim()

  return result
}

/**
 * Recursively sanitize string values in a JSON object
 */
function sanitizeJsonObject(obj: unknown): unknown {
  if (typeof obj === 'string') {
    return sanitizeOutput(obj)
  } else if (Array.isArray(obj)) {
    return obj.map((item) => sanitizeJsonObject(item))
  } else if (obj !== null && typeof obj === 'object') {
    const sanitized: Record<string, unknown> = {}
    for (const [key, value] of Object.entries(obj)) {
      sanitized[key] = sanitizeJsonObject(value)
    }
    return sanitized
  }
  return obj
}

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

    // Check API key early (inside handler to avoid module-level crash)
    const apiKey = Deno.env.get('OPENROUTER_API_KEY')
    if (!apiKey) {
      console.error('✗ OPENROUTER_API_KEY is not set')
      return new Response(
        JSON.stringify({ error: 'OPENROUTER_API_KEY is not configured on the server' }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    console.log('✓ About to parse request body')
    const body = await request.json()
    console.log('✓ Request body parsed successfully')

    // Validate request with Zod schema
    let validated: CallLlmRequestType
    try {
      validated = CallLlmRequest.parse(body)
    } catch (error) {
      console.log(
        '✗ Request validation failed:',
        error instanceof Error ? error.message : String(error)
      )
      return new Response(
        JSON.stringify({
          error: 'Invalid request: prompt field is required and must be a non-empty string',
        }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    const { prompt, format, model, options, systemPrompt, jsonSchema } = validated
    const modelOptions = (options || {}) as Record<string, unknown>

    if (!model) {
      return new Response(JSON.stringify({ error: 'model field is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    console.log('✓ Input validated')
    console.log('=== PROMPT BEING SENT TO LLM ===')
    console.log(prompt)
    console.log('=== END PROMPT ===')
    console.log(`Model: ${model}`)
    console.log(`Format: ${format || 'none'}`)
    console.log(`JSON Schema: ${jsonSchema ? 'provided' : 'none'}`)
    console.log(`Options: ${JSON.stringify(modelOptions, null, 2)}`)

    // Initialize OpenAI client lazily (avoids module-level crash if key is missing)
    const openai = new OpenAI({
      apiKey,
      baseURL: 'https://openrouter.ai/api/v1',
    })

    const messages: OpenAI.ChatCompletionMessageParam[] = []

    if (systemPrompt) {
      messages.push({ role: 'system', content: systemPrompt })
    }

    messages.push({ role: 'user', content: prompt.trim() })

    // Build response_format: structured outputs > simple JSON mode > none
    let responseFormat:
      | { type: 'json_object' }
      | { type: 'json_schema'; json_schema: object }
      | undefined
    if (jsonSchema) {
      responseFormat = {
        type: 'json_schema',
        json_schema: jsonSchema,
      }
    } else if (format === 'json') {
      responseFormat = { type: 'json_object' }
    }

    // Build request params - pass through all options directly
    // OpenRouter accepts any valid parameter and ignores unsupported ones
    const { stop, ...restOptions } = modelOptions
    const requestParams: Record<string, unknown> = {
      model,
      messages,
      ...restOptions,
    }

    // Only include stop if non-empty array
    if (Array.isArray(stop) && stop.length > 0) {
      requestParams.stop = stop
    }

    // Add response_format if configured
    if (responseFormat) {
      requestParams.response_format = responseFormat
    }

    // @ts-ignore - OpenRouter accepts additional params beyond OpenAI SDK types
    const response = await openai.chat.completions.create(requestParams)

    const choice = response.choices?.[0]
    const content = choice?.message?.content

    if (!content) {
      console.error('✗ OpenRouter returned empty content', JSON.stringify(response))
      return new Response(JSON.stringify({ error: 'LLM returned empty response' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    console.log('✓ OpenRouter API responded successfully')
    console.log('=== RAW LLM RESPONSE ===')
    console.log(content)
    console.log('=== END RESPONSE ===')

    // Sanitize the response based on format
    let sanitized = content
    if (format === 'json' || jsonSchema) {
      // For JSON responses, sanitize the entire JSON string first, then parse and re-stringify
      try {
        const parsed = JSON.parse(content)
        // Recursively sanitize string values in the JSON object
        const sanitizedJson = sanitizeJsonObject(parsed)
        sanitized = JSON.stringify(sanitizedJson)
      } catch {
        // If JSON parsing fails, just sanitize as text
        sanitized = sanitizeOutput(content)
      }
    } else {
      // For text responses, apply standard sanitization
      sanitized = sanitizeOutput(content)
    }

    console.log('=== SANITIZED RESPONSE ===')
    console.log(sanitized)
    console.log('=== END SANITIZED RESPONSE ===')

    return new Response(
      JSON.stringify({
        response: sanitized,
        model: response.model,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('✗ Error calling LLM via OpenRouter:', error)
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

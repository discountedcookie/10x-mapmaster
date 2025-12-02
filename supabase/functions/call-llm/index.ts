import OpenAI from 'https://deno.land/x/openai@v4.24.0/mod.ts'
import { CallLlmRequest, CallLlmRequestType } from '../types/schemas.ts'

console.log('✓ call-llm module loading started')

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

    const response = await openai.chat.completions.create({
      model,
      messages,
      temperature:
        typeof modelOptions.temperature === 'number' ? modelOptions.temperature : undefined,
      max_tokens:
        typeof modelOptions.num_predict === 'number' ? modelOptions.num_predict : undefined,
      top_p: typeof modelOptions.top_p === 'number' ? modelOptions.top_p : undefined,
      stop:
        Array.isArray(modelOptions.stop) && modelOptions.stop.length > 0
          ? (modelOptions.stop as string[])
          : undefined,
      frequency_penalty:
        typeof modelOptions.frequency_penalty === 'number'
          ? modelOptions.frequency_penalty
          : undefined,
      presence_penalty:
        typeof modelOptions.presence_penalty === 'number'
          ? modelOptions.presence_penalty
          : undefined,
      // @ts-ignore - OpenRouter supports this but OpenAI SDK doesn't have it typed
      repetition_penalty:
        typeof modelOptions.repetition_penalty === 'number'
          ? modelOptions.repetition_penalty
          : undefined,
      // @ts-ignore - response_format with json_schema
      response_format: responseFormat,
    })

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

    return new Response(
      JSON.stringify({
        response: content,
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

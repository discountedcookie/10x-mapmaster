import { enrichPlace } from '../_shared/enrichment.ts'

console.log('✓ place-enrichment module loading started')

interface PlaceEnrichmentRequest {
  query?: string
  name?: string
  language?: string
  limit?: number
}

const JSON_HEADERS = {
  'Content-Type': 'application/json',
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: JSON_HEADERS,
  })
}

Deno.serve(async (request: Request) => {
  console.log('✓ Handler invoked')
  try {
    console.log(`✓ Request method: ${request.method}`)

    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405)
    }

    console.log('✓ About to parse request body')
    let payload: PlaceEnrichmentRequest
    try {
      payload = await request.json()
      console.log('✓ Request body parsed successfully')
    } catch {
      console.log('✗ JSON parsing failed')
      return jsonResponse({ error: 'Invalid JSON payload' }, 400)
    }

    const query =
      typeof payload.query === 'string'
        ? payload.query
        : typeof payload.name === 'string'
          ? payload.name
          : undefined

    if (!query || query.trim().length === 0) {
      console.log('✗ Query validation failed')
      return jsonResponse({ error: 'query or name field is required and must be non-empty' }, 400)
    }

    console.log(`✓ Enriching place: "${query.trim()}"`)
    console.log(`✓ Language: ${payload.language || 'en'}, Limit: ${payload.limit ?? 1}`)

    try {
      const result = await enrichPlace(query.trim(), payload.language, payload.limit ?? 1)

      if (!result) {
        console.log('✗ No results found')
        return jsonResponse({ error: 'No results found' }, 404)
      }

      console.log('✓ Place enriched successfully')
      return jsonResponse(result)
    } catch (error) {
      console.error('✗ Failed to fetch Nominatim data:', error)
      console.error('✗ Error stack:', error instanceof Error ? error.stack : 'No stack trace')
      return jsonResponse({ error: error instanceof Error ? error.message : 'Unknown error' }, 502)
    }
  } catch (error) {
    console.error('✗ Unexpected error in place-enrichment:', error)
    return jsonResponse({ error: error instanceof Error ? error.message : 'Unknown error' }, 500)
  }
})

console.log('✓ Deno.serve registered - place-enrichment module loaded successfully')

import { enrichPlace } from '../_shared/enrichment.ts'

interface PlaceEnrichmentRequest {
  query?: string
  name?: string
  language?: string
  limit?: number
}

type DenoServe = (handler: (request: Request) => Response | Promise<Response>) => void

const denoGlobal = globalThis as { Deno?: { serve?: DenoServe } }
const serve = denoGlobal.Deno?.serve

if (!serve) {
  throw new Error('Deno runtime is required to run this function')
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

serve(async (request) => {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405)
  }

  let payload: PlaceEnrichmentRequest
  try {
    payload = await request.json()
  } catch {
    return jsonResponse({ error: 'Invalid JSON payload' }, 400)
  }

  const query =
    typeof payload.query === 'string'
      ? payload.query
      : typeof payload.name === 'string'
        ? payload.name
        : undefined

  if (!query || query.trim().length === 0) {
    return jsonResponse({ error: 'query is required' }, 400)
  }

  try {
    const result = await enrichPlace(query.trim(), payload.language, payload.limit ?? 1)

    if (!result) {
      return jsonResponse({ error: 'No results found' }, 404)
    }

    return jsonResponse(result)
  } catch (error) {
    console.error('Failed to fetch Nominatim data', error)
    return jsonResponse({ error: error instanceof Error ? error.message : 'Unknown error' }, 502)
  }
})

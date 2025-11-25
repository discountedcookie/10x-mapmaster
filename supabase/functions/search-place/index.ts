import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

// Helper functions (previously in _shared)
function validateRequestMethod(request: Request, allowedMethods: string[]): void {
  if (!allowedMethods.includes(request.method)) {
    throw new Response(`Method ${request.method} not allowed`, { status: 405 })
  }
}

function jsonResponse(data: any, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function jsonErrorResponse(message: string, status = 500): Response {
  return jsonResponse({ error: message }, status)
}

function requireAuth(request: Request): void {
  const authHeader = request.headers.get('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Response('Unauthorized', { status: 401 })
  }
}

console.log('Search-place function starting...')

// Use the standard Deno.serve approach
const handler = async (request: Request): Promise<Response> => {
  try {
    validateRequestMethod(request, ['GET'])
    requireAuth(request)

    const url = new URL(request.url)
    const query = url.searchParams.get('q')

    if (!query || typeof query !== 'string' || query.trim().length === 0) {
      return jsonErrorResponse('q query parameter is required', 400)
    }

    // Search Nominatim
    const nominatimResponse = await fetch(
      `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&limit=10`,
      {
        headers: {
          'User-Agent': 'MapMaster-SearchPlace/1.0',
        },
      }
    )

    if (!nominatimResponse.ok) {
      throw new Error(`Nominatim API error: ${nominatimResponse.statusText}`)
    }

    const results = await nominatimResponse.json()

    return jsonResponse({
      query,
      results: results.map((r: any) => ({
        name: r.display_name,
        lat: Number.parseFloat(r.lat),
        lng: Number.parseFloat(r.lon),
        osm_id: r.osm_id,
        type: r.type,
      })),
    })
  } catch (error) {
    console.error('Error searching places:', error)

    if (error instanceof Response) return error
    return jsonErrorResponse(error instanceof Error ? error.message : 'Unknown error', 500)
  }
}

// Export the handler for Supabase
export { handler }

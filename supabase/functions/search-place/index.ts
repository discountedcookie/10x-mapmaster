console.log('✓ search-place module loading started')

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

    if (request.method !== 'GET') {
      return jsonResponse({ error: 'Method not allowed' }, 405)
    }

    const url = new URL(request.url)
    const query = url.searchParams.get('q')

    if (!query || typeof query !== 'string' || query.trim().length === 0) {
      console.log('✗ Query validation failed')
      return jsonResponse({ error: 'q query parameter is required and must be non-empty' }, 400)
    }

    console.log(`✓ Searching for: "${query}"`)

    // Search Nominatim
    const nominatimResponse = await fetch(
      `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query.trim())}&format=json&limit=10`,
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
    console.log(`✓ Found ${results.length} results`)

    return jsonResponse({
      query: query.trim(),
      results: results.map((r: any) => ({
        name: r.display_name,
        lat: Number.parseFloat(r.lat),
        lng: Number.parseFloat(r.lon),
        osm_id: r.osm_id,
        type: r.type,
      })),
    })
  } catch (error) {
    console.error('✗ Error searching places:', error)
    console.error('✗ Error stack:', error instanceof Error ? error.stack : 'No stack trace')
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      500
    )
  }
})

console.log('✓ Deno.serve registered - search-place module loaded successfully')

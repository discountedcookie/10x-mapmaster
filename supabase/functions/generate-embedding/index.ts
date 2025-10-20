import "jsr:@supabase/functions-js/edge-runtime.d.ts"

Deno.serve(async (req) => {
    if (req.method !== 'POST' && req.method !== 'OPTIONS') {
        return new Response('Method Not Allowed', { status: 405 })
    }

    // Handle CORS preflight request
    if (req.method === 'OPTIONS') {
        return new Response('ok', {
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Authorization, Content-Type, x-client-info, apikey',
            },
        })
    }

    try {
        const { text } = await req.json()

        if (!text || typeof text !== 'string' || text.trim().length === 0) {
            return new Response(
                JSON.stringify({ error: 'Text parameter is required' }),
                {
                    status: 400,
                    headers: {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                    },
                }
            )
        }

        // Generate embedding using Supabase AI with gte-small model
        const session = new Supabase.ai.Session('gte-small')
        const embedding = await session.run(text, {
            mean_pool: true,
            normalize: true,
        })

        if (!Array.isArray(embedding) || embedding.length !== 384) {
            throw new Error(`Expected 384-dimensional vector, got ${embedding?.length || 0}`)
        }

        return new Response(
            JSON.stringify({ embedding }),
            {
                status: 200,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                },
            }
        )
    } catch (error) {
        console.error('Error generating embedding:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            {
                status: 500,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                },
            }
        )
    }
})

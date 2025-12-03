/**
 * Async Trait Extraction Processor
 *
 * Processes trait extraction jobs from pgmq queue.
 * Called via pg_net fire-and-forget from database trigger.
 *
 * Request body:
 * {
 *   "function_name": "update_place_traits",
 *   "params": { "p_place_id": "uuid-here" }
 * }
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.76.1'

// Whitelist of allowed functions - security measure
const ALLOWED_FUNCTIONS = ['update_place_traits'] as const

Deno.serve(async (request: Request) => {
  try {
    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(JSON.stringify({ error: 'Supabase configuration missing' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const body = await request.json()
    const { function_name, params } = body

    if (!function_name) {
      return new Response(JSON.stringify({ error: 'function_name is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Security: Only allow whitelisted functions
    if (!ALLOWED_FUNCTIONS.includes(function_name)) {
      console.error(`Blocked attempt to call non-whitelisted function: ${function_name}`)
      return new Response(JSON.stringify({ error: 'Function not allowed' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Validate params for update_place_traits
    const placeId = params?.p_place_id
    if (!placeId) {
      return new Response(JSON.stringify({ error: 'p_place_id is required in params' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    console.log(`Processing: ${function_name}(p_place_id: ${placeId})`)

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Call the RPC function
    const { error: rpcError } = await supabase.rpc(function_name, params)

    if (rpcError) {
      console.error(`RPC ${function_name} failed:`, rpcError.message)
      return new Response(JSON.stringify({ success: false, error: rpcError.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Archive the queue message after successful processing
    const { error: archiveError } = await supabase.rpc('archive_trait_queue_by_place', {
      p_place_id: placeId,
    })

    if (archiveError) {
      // Log but don't fail - message will be cleaned up by backup processor
      console.warn(`Could not archive queue message: ${archiveError.message}`)
    }

    console.log(`Successfully processed: ${function_name}(p_place_id: ${placeId})`)
    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: String(error) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

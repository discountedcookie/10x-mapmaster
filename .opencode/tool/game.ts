import { tool } from "@opencode-ai/plugin"

const PSQL_CONN = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"

// Test user UUID for auth
const TEST_USER_ID = "a1b2c3d4-e5f6-4321-abcd-1234567890ab"

// Helper to run psql with auth context
async function psql(sql: string): Promise<string> {
  const fullSql = `
    SET request.jwt.claim.sub = '${TEST_USER_ID}';
    SET request.jwt.claim.role = 'authenticated';
    SET ROLE authenticated;
    ${sql}
  `
  const result = await Bun.$`psql ${PSQL_CONN} -c ${fullSql}`.text()
  return result.trim()
}

/**
 * Start a new game
 */
export const start = tool({
  description: "Start a new geography guessing game",
  args: {
    description: tool.schema.string().describe("Description of the place (1-200 chars)"),
    lang: tool.schema.string().optional().describe("Language code (default: en)"),
  },
  async execute(args) {
    const lang = args.lang || "en"
    
    // Start game and get session_id
    const startResult = await psql(`SELECT start_game('${args.description}', '${lang}')`)
    const match = startResult.match(/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/i)
    const sessionId = match?.[1]
    
    if (!sessionId) {
      return `Error starting game: ${startResult}`
    }

    // Get initial state
    const state = await psql(`
      SELECT 
        status,
        question->>'text' as question,
        guess->>'place_name' as guess,
        jsonb_array_length(candidates) as candidate_count
      FROM game_session_state 
      WHERE session_id = '${sessionId}'::uuid;
    `)

    const candidates = await psql(`
      SELECT 
        c->>'name' as place,
        round((c->>'confidence')::numeric * 100) || '%' as confidence
      FROM game_session_state gss, 
           jsonb_array_elements(gss.candidates) as c
      WHERE session_id = '${sessionId}'::uuid
      ORDER BY (c->>'confidence')::numeric DESC
      LIMIT 5;
    `)

    return `SESSION: ${sessionId}\n\n${state}\n\nTOP CANDIDATES:\n${candidates}`
  },
})

/**
 * Check current game state
 */
export const state = tool({
  description: "Get current state of a game (question, guess, candidates)",
  args: {
    session_id: tool.schema.string().describe("Game session UUID"),
  },
  async execute(args) {
    const state = await psql(`
      SELECT 
        status,
        question->>'text' as question,
        guess->>'place_name' as guess,
        round((guess->>'confidence')::numeric * 100) || '%' as guess_confidence
      FROM game_session_state 
      WHERE session_id = '${args.session_id}'::uuid;
    `)

    const candidates = await psql(`
      SELECT 
        c->>'name' as place,
        round((c->>'confidence')::numeric * 100) || '%' as confidence
      FROM game_session_state gss, 
           jsonb_array_elements(gss.candidates) as c
      WHERE session_id = '${args.session_id}'::uuid
      ORDER BY (c->>'confidence')::numeric DESC
      LIMIT 5;
    `)

    return `${state}\n\nTOP CANDIDATES:\n${candidates}`
  },
})

/**
 * Play a turn (answer question or confirm/deny guess)
 */
export const turn = tool({
  description: "Answer a question or confirm/deny a guess",
  args: {
    session_id: tool.schema.string().describe("Game session UUID"),
    answer: tool.schema.enum(["yes", "no", "not_sure"]).describe("Your answer"),
  },
  async execute(args) {
    // Play the turn
    await psql(`SELECT play_turn('${args.session_id}'::uuid, '${args.answer}'::answer_value)`)

    // Get new state
    const state = await psql(`
      SELECT 
        status,
        question->>'text' as question,
        guess->>'place_name' as guess,
        round((guess->>'confidence')::numeric * 100) || '%' as guess_confidence
      FROM game_session_state 
      WHERE session_id = '${args.session_id}'::uuid;
    `)

    const candidates = await psql(`
      SELECT 
        c->>'name' as place,
        round((c->>'confidence')::numeric * 100) || '%' as confidence
      FROM game_session_state gss, 
           jsonb_array_elements(gss.candidates) as c
      WHERE session_id = '${args.session_id}'::uuid
      ORDER BY (c->>'confidence')::numeric DESC
      LIMIT 5;
    `)

    return `${state}\n\nTOP CANDIDATES:\n${candidates}`
  },
})

/**
 * Submit the correct place (give up)
 */
export const submit = tool({
  description: "Submit the correct place when giving up",
  args: {
    session_id: tool.schema.string().describe("Game session UUID"),
    osm_id: tool.schema.string().describe("OSM ID of the correct place (use game_find_place to find it)"),
  },
  async execute(args) {
    const result = await psql(`SELECT submit_place('${args.session_id}'::uuid, '${args.osm_id}')`)
    return result
  },
})

/**
 * Search for places by name
 */
export const find_place = tool({
  description: "Search for places by name (to get osm_id for submit)",
  args: {
    name: tool.schema.string().describe("Place name (partial match)"),
  },
  async execute(args) {
    return psql(`
      SELECT osm_id, name
      FROM places
      WHERE name ILIKE '%${args.name}%'
      LIMIT 10;
    `)
  },
})

/**
 * Get full session summary - history, result, place info
 */
export const summary = tool({
  description: "Get full summary of a completed game session",
  args: {
    session_id: tool.schema.string().describe("Game session UUID"),
  },
  async execute(args) {
    const session = await psql(`
      SELECT 
        gs.description,
        gs.status,
        gs.was_correct,
        p.name as place_name,
        (SELECT COUNT(*) FROM place_traits WHERE place_id = gs.place_id) as trait_count
      FROM game_sessions gs
      LEFT JOIN places p ON p.id = gs.place_id
      WHERE gs.id = '${args.session_id}'::uuid;
    `)

    const history = await psql(`
      SELECT 
        ROW_NUMBER() OVER (ORDER BY created_at) as turn,
        question_text,
        answer
      FROM game_answers
      WHERE session_id = '${args.session_id}'::uuid
      ORDER BY created_at;
    `)

    return `=== SESSION ===\n${session}\n\n=== QUESTION HISTORY ===\n${history}`
  },
})

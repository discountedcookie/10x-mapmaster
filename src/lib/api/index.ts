import { supabase } from '@/lib/supabase'
import type { Database, Tables } from '@/types/database'

// Type aliases for clarity
type AnswerValue = Database['public']['Enums']['answer_value']
type GameSessionStateRow = Database['public']['Views']['game_session_state']['Row']
type PlaceWithGeometry = Tables<'places_with_geometry'>

export type Answer = AnswerValue
export type { GameSessionStateRow, PlaceWithGeometry }

/**
 * Game API - All game-related RPC calls and queries
 */
export const gameApi = {
  /**
   * Start a new game with a description
   * @param description - The place description (max 100 chars)
   * @param languageCode - Language code (default: 'en')
   * @returns Session ID
   */
  async startGame(description: string, languageCode: string = 'en'): Promise<string> {
    const { data, error } = await supabase.rpc('start_game', {
      p_description: description,
      p_language_code: languageCode,
    })
    if (error) throw error
    if (!data) throw new Error('No session ID returned from start_game')
    return typeof data === 'string' ? data : String(data)
  },

  /**
   * Play a turn - answer the current question or respond to a guess
   * @param sessionId - Active game session ID
   * @param answer - 'yes', 'no', or 'not_sure'
   */
  async playTurn(sessionId: string, answer: Answer): Promise<void> {
    const { error } = await supabase.rpc('play_turn', {
      p_session_id: sessionId,
      p_answer: answer,
    })
    if (error) throw error
  },

  /**
   * Fetch current game state from game_session_state view
   * Includes candidates in next_turn JSONB
   * @param sessionId - Active game session ID
   * @returns Full game state
   */
  async getGameState(sessionId: string): Promise<GameSessionStateRow> {
    const { data, error } = await supabase
      .from('game_session_state')
      .select('*')
      .eq('session_id', sessionId)
      .single()
    if (error) throw error
    if (!data) throw new Error('No game state found')
    return data
  },

  /**
   * Submit the actual place when game fails to guess
   * Handles place creation/update and session update
   * @param sessionId - Active game session ID
   * @param osm_id - OpenStreetMap ID from Nominatim
   */
  async submitPlace(sessionId: string, osm_id: string): Promise<void> {
    const { error } = await supabase.rpc('submit_place', {
      p_session_id: sessionId,
      p_osm_id: osm_id,
    })
    if (error) throw error
  },
}

/**
 * Places API - All place-related queries
 */
export const placesApi = {
  /**
   * Fetch all places with geometry
   * @returns Array of places with coordinates
   */
  async fetchAll(): Promise<PlaceWithGeometry[]> {
    const { data, error } = await supabase.from('places_with_geometry').select('*').order('name')
    if (error) throw error
    return data || []
  },

  /**
   * Fetch a single place by ID
   * @param id - Place ID
   * @returns Place with geometry
   */
  async fetchById(id: string): Promise<PlaceWithGeometry> {
    const { data, error } = await supabase
      .from('places_with_geometry')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    if (!data) throw new Error('Place not found')
    return data
  },

  /**
   * Fetch multiple places by IDs
   * @param ids - Array of place IDs
   * @returns Array of places
   */
  async fetchByIds(ids: string[]): Promise<PlaceWithGeometry[]> {
    if (ids.length === 0) return []
    const { data, error } = await supabase.from('places_with_geometry').select('*').in('id', ids)
    if (error) throw error
    return data || []
  },
}

/**
 * Statistics API - Game and user statistics
 */
export const statsApi = {
  /**
   * Fetch global game statistics
   * @returns Global stats including win rates, session counts, etc.
   */
  async fetchGlobalStats(): Promise<Tables<'global_stats'>> {
    const { data, error } = await supabase.from('global_stats').select('*').single()
    if (error) throw error
    if (!data) throw new Error('No global stats found')
    return data
  },

  /**
   * Fetch user statistics (requires auth)
   * @returns User stats including games played, win rate, etc.
   */
  async fetchUserStats(): Promise<Tables<'user_stats'>> {
    const { data, error } = await supabase.from('user_stats').select('*').single()
    if (error) throw error
    if (!data) throw new Error('No user stats found')
    return data
  },
}

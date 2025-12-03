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

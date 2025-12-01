/**
 * Frontend-specific game types that extend database types
 * These types are used for UI state management and don't exist in the database
 */

import type { Database } from './database'

/** Game session status enum from database */
export type GameSessionStatus = Database['public']['Enums']['game_session_status']

/** Place with scoring information (computed by backend, used for UI) */
export interface PlaceWithScore {
  id: string
  name: string
  lat: number
  lng: number
  confidence: number
  description_similarity: number
  affirmed_trait_similarity: number | null
  denied_trait_similarity: number | null
  geographic_distance: number | null
}

/** Chat message for game UI (frontend-only, not persisted) */
export interface ChatMessage {
  id: string
  role: 'system' | 'user'
  type: 'question' | 'guess' | 'answer' | 'message'
  text: string
  timestamp: Date
  metadata?: {
    questionId?: string
    placeId?: string
    confidence?: number
  }
}

/** Frontend game state combining database session with UI state */
export interface GameState {
  sessionId: string
  description: string
  messages: ChatMessage[]
  candidates: PlaceWithScore[]
  confidence: number
  threshold: number
  semanticConstraint: string
  questionCount: number
  wrongGuessCount: number
  status: GameSessionStatus
  result?: {
    correct_place_id?: string
    guessed_correctly?: boolean
  }
}

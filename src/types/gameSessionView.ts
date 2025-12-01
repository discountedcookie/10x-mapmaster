import type { GameSessionStatus, PlaceWithScore } from './game'

export interface QuestionJson {
  id: string | null
  text: string | null
}

export interface GuessJson {
  place_id: string | null
  place_name: string | null
}

export interface PlaceJson {
  id: string
  name: string
  lat: number | null
  lng: number | null
}

// Candidates from backend are effectively PlaceWithScore, with optional geometry for 3D
export type CandidateJson = PlaceWithScore & {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  geometry?: any
}

// Simplified view of the game_session_state row focused on UI needs
export interface GameSessionView {
  session_id: string | null
  description: string | null
  status: GameSessionStatus | null
  question: QuestionJson | null
  guess: GuessJson | null
  place: PlaceJson | null
  candidates: CandidateJson[] | null
  question_count: number | null
}

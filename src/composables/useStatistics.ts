import { ref, computed } from 'vue'
import { logger } from '@/lib/logger'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

export interface GameSessionStats {
  session_id: string
  user_id: string
  place_id: string | null
  was_correct: boolean | null
  description: string | null
  created_at: string
  question_count: number
  wrong_guess_count: number
}

export interface UserStatistics {
  gamesPlayed: number
  gamesWon: number
  gamesLost: number
  successRate: number
  avgQuestionsPerGame: number
  avgWrongGuesses: number
  totalQuestionsAsked: number
  mostRecentGame: string | undefined
}

export function useStatistics() {
  const authStore = useAuthStore()
  const loading = ref(false)
  const error = ref<string | undefined>()
  const sessions = ref<GameSessionStats[]>([])

  const statistics = computed<UserStatistics>(() => {
    if (sessions.value.length === 0) {
      return {
        gamesPlayed: 0,
        gamesWon: 0,
        gamesLost: 0,
        successRate: 0,
        avgQuestionsPerGame: 0,
        avgWrongGuesses: 0,
        totalQuestionsAsked: 0,
        mostRecentGame: undefined,
      }
    }

    const completedGames = sessions.value.filter((s) => s.was_correct !== null)
    const gamesWon = completedGames.filter((s) => s.was_correct === true).length
    const gamesLost = completedGames.filter((s) => s.was_correct === false).length
    const totalQuestions = sessions.value.reduce((sum, s) => sum + s.question_count, 0)
    const totalWrongGuesses = sessions.value.reduce((sum, s) => sum + s.wrong_guess_count, 0)

    return {
      gamesPlayed: sessions.value.length,
      gamesWon,
      gamesLost,
      successRate: completedGames.length > 0 ? (gamesWon / completedGames.length) * 100 : 0,
      avgQuestionsPerGame: sessions.value.length > 0 ? totalQuestions / sessions.value.length : 0,
      avgWrongGuesses: sessions.value.length > 0 ? totalWrongGuesses / sessions.value.length : 0,
      totalQuestionsAsked: totalQuestions,
      mostRecentGame: sessions.value[0]?.created_at,
    }
  })

  async function fetchStatistics() {
    const userId = authStore.user?.id
    if (!userId) {
      error.value = 'User not authenticated'
      return
    }

    try {
      loading.value = true
      error.value = undefined

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const { data, error: fetchError } = await (supabase as any)
        .from('game_session_stats')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })

      if (fetchError) throw fetchError

      sessions.value = (data || []) as GameSessionStats[]
    } catch (error_) {
      logger.error('Failed to fetch statistics:', error_)
      error.value = error_ instanceof Error ? error_.message : 'Failed to load statistics'
    } finally {
      loading.value = false
    }
  }

  return {
    loading,
    error,
    sessions,
    statistics,
    fetchStatistics,
  }
}

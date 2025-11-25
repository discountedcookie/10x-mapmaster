import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useAuthStore } from '@/stores/auth'
import type { Session, User } from '@supabase/supabase-js'

// Mock Supabase auth
vi.mock('@/lib/supabase', () => {
  const mockGetSession = vi.fn()
  const mockOnAuthStateChange = vi.fn()
  const mockSignOut = vi.fn()
  const mockSignInAnonymously = vi.fn()

  return {
    supabase: {
      auth: {
        getSession: mockGetSession,
        onAuthStateChange: mockOnAuthStateChange,
        signOut: mockSignOut,
        signInAnonymously: mockSignInAnonymously,
      },
    },
    mockGetSession,
    mockOnAuthStateChange,
    mockSignOut,
    mockSignInAnonymously,
  }
})

const { mockGetSession, mockOnAuthStateChange, mockSignOut, mockSignInAnonymously } = (await import(
  '@/lib/supabase'
)) as any

describe('useAuthStore', () => {
  let store: ReturnType<typeof useAuthStore>

  const mockUser: User = {
    id: 'user-123',
    email: 'test@example.com',
    aud: 'authenticated',
    role: 'authenticated',
    created_at: '2024-01-01',
    app_metadata: {},
    user_metadata: {},
    is_anonymous: false,
  } as User

  const mockAnonUser: User = {
    ...mockUser,
    id: 'anon-123',
    email: undefined,
    is_anonymous: true,
  } as User

  const mockSession: Session = {
    access_token: 'mock-token',
    refresh_token: 'mock-refresh',
    user: mockUser,
    expires_in: 3600,
    expires_at: Date.now() / 1000 + 3600,
    token_type: 'bearer',
  } as Session

  const mockAnonSession: Session = {
    ...mockSession,
    user: mockAnonUser,
  } as Session

  beforeEach(() => {
    setActivePinia(createPinia())
    store = useAuthStore()
    vi.clearAllMocks()

    // Default mock setup
    mockOnAuthStateChange.mockReturnValue({
      data: { subscription: { unsubscribe: vi.fn() } },
    })
  })

  describe('Initial State', () => {
    it('should initialize with undefined user and loading true', () => {
      expect(store.user).toBeUndefined()
      expect(store.session).toBeUndefined()
      expect(store.loading).toBe(true)
      expect(store.isAuthenticated).toBe(false)
      expect(store.isAnonymous).toBe(false)
    })
  })

  describe('initialize', () => {
    it('should create anonymous session when no session exists', async () => {
      mockGetSession.mockResolvedValueOnce({
        data: { session: null },
        error: null,
      })
      mockSignInAnonymously.mockResolvedValueOnce({
        data: { session: mockAnonSession, user: mockAnonUser },
        error: null,
      })

      await store.initialize()

      expect(mockSignInAnonymously).toHaveBeenCalled()
      expect(mockOnAuthStateChange).toHaveBeenCalled()
      expect(store.loading).toBe(false)
    })

    it('should load existing authenticated session', async () => {
      mockGetSession.mockResolvedValueOnce({
        data: { session: mockSession },
        error: null,
      })

      await store.initialize()

      expect(mockSignInAnonymously).not.toHaveBeenCalled()
      expect(mockOnAuthStateChange).toHaveBeenCalled()
      expect(store.loading).toBe(false)
    })

    it('should handle auth state changes', async () => {
      mockGetSession.mockResolvedValueOnce({
        data: { session: mockAnonSession },
        error: null,
      })

      let authChangeCallback: any
      mockOnAuthStateChange.mockImplementationOnce((callback: any) => {
        authChangeCallback = callback
        return { data: { subscription: { unsubscribe: vi.fn() } } }
      })

      await store.initialize()

      // Simulate user signing in
      authChangeCallback('SIGNED_IN', mockSession)

      expect(store.user).toEqual(mockUser)
      expect(store.session).toEqual(mockSession)
      expect(store.isAuthenticated).toBe(true)
      expect(store.isAnonymous).toBe(false)
    })
  })

  describe('signOut', () => {
    it('should sign out and create new anonymous session', async () => {
      store.user = mockUser
      store.session = mockSession

      mockSignOut.mockResolvedValueOnce({ error: null })
      mockSignInAnonymously.mockResolvedValueOnce({
        data: { session: mockAnonSession, user: mockAnonUser },
        error: null,
      })

      await store.signOut()

      expect(mockSignOut).toHaveBeenCalled()
      expect(mockSignInAnonymously).toHaveBeenCalled()
      expect(store.user).toBeUndefined()
      expect(store.session).toBeUndefined()
    })
  })

  describe('Computed properties', () => {
    it('should correctly identify authenticated users', () => {
      store.user = mockUser
      expect(store.isAuthenticated).toBe(true)
      expect(store.isAnonymous).toBe(false)
    })

    it('should correctly identify anonymous users', () => {
      store.user = mockAnonUser
      expect(store.isAuthenticated).toBe(false)
      expect(store.isAnonymous).toBe(true)
    })

    it('should handle undefined user', () => {
      store.user = undefined
      expect(store.isAuthenticated).toBe(false)
      expect(store.isAnonymous).toBe(false)
    })
  })
})

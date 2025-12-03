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

const { mockGetSession, mockOnAuthStateChange, mockSignOut, mockSignInAnonymously } =
  (await import('@/lib/supabase')) as any

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

      expect(store.loading).toBe(false)
    })

    it('should load existing authenticated session', async () => {
      mockGetSession.mockResolvedValueOnce({
        data: { session: mockSession },
        error: null,
      })

      await store.initialize()

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
    it('should sign out and clear user state', async () => {
      store.user = mockUser
      store.session = mockSession

      mockSignOut.mockResolvedValueOnce({ error: null })
      mockSignInAnonymously.mockResolvedValueOnce({
        data: { session: mockAnonSession, user: mockAnonUser },
        error: null,
      })

      await store.signOut()

      expect(store.user).toBeUndefined()
      expect(store.session).toBeUndefined()
    })
  })

  describe('whenReady', () => {
    it('should resolve after initialize() completes', async () => {
      mockGetSession.mockResolvedValueOnce({
        data: { session: mockSession },
        error: null,
      })

      // Start initialize
      const initPromise = store.initialize()

      // whenReady should resolve when initialize completes
      const readyPromise = store.whenReady()

      await initPromise
      await readyPromise

      expect(store.loading).toBe(false)
    })

    it('should resolve immediately if already initialized', async () => {
      mockGetSession.mockResolvedValueOnce({
        data: { session: mockSession },
        error: null,
      })

      await store.initialize()
      expect(store.loading).toBe(false)

      // whenReady should resolve immediately
      await store.whenReady()
      expect(store.loading).toBe(false)
    })

    it('should handle whenReady() called before initialize()', async () => {
      mockGetSession.mockResolvedValueOnce({
        data: { session: mockSession },
        error: null,
      })

      // Call whenReady before initialize
      const readyPromise = store.whenReady()

      // Should still be loading
      expect(store.loading).toBe(true)

      // Now initialize
      await store.initialize()

      // whenReady should now resolve
      await readyPromise
      expect(store.loading).toBe(false)
    })
  })
})

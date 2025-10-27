import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useAuthStore } from '@/stores/auth'
import type { Session, User } from '@supabase/supabase-js'

// Mock Supabase auth - use factory to avoid hoisting issues
vi.mock('@/lib/supabase', () => {
    const mockGetSession = vi.fn()
    const mockOnAuthStateChange = vi.fn()
    const mockSignInWithPassword = vi.fn()
    const mockSignUp = vi.fn()
    const mockSignOut = vi.fn()
    const mockSignInWithOAuth = vi.fn()

    return {
        supabase: {
            auth: {
                getSession: mockGetSession,
                onAuthStateChange: mockOnAuthStateChange,
                signInWithPassword: mockSignInWithPassword,
                signUp: mockSignUp,
                signOut: mockSignOut,
                signInWithOAuth: mockSignInWithOAuth,
            },
        },
        mockGetSession,
        mockOnAuthStateChange,
        mockSignInWithPassword,
        mockSignUp,
        mockSignOut,
        mockSignInWithOAuth,
    }
})

const { mockGetSession, mockOnAuthStateChange, mockSignInWithPassword, mockSignUp, mockSignOut, mockSignInWithOAuth } = await import('@/lib/supabase') as any

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
    } as User

    const mockSession: Session = {
        access_token: 'mock-token',
        refresh_token: 'mock-refresh',
        user: mockUser,
        expires_in: 3600,
        expires_at: Date.now() / 1000 + 3600,
        token_type: 'bearer',
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
        it('should initialize with null user and session', () => {
            expect(store.user).toBeNull()
            expect(store.session).toBeNull()
            expect(store.loading).toBe(true)
            expect(store.isAuthenticated).toBe(false)
        })
    })

    describe('initialize', () => {
        it('should load existing session', async () => {
            mockGetSession.mockResolvedValueOnce({
                data: { session: mockSession },
                error: null,
            })

            await store.initialize()

            expect(mockGetSession).toHaveBeenCalled()
            expect(store.user).toEqual(mockUser)
            expect(store.session).toEqual(mockSession)
            expect(store.isAuthenticated).toBe(true)
            expect(store.loading).toBe(false)
        })

        it('should handle no session', async () => {
            mockGetSession.mockResolvedValueOnce({
                data: { session: null },
                error: null,
            })

            await store.initialize()

            expect(store.user).toBeNull()
            expect(store.session).toBeNull()
            expect(store.isAuthenticated).toBe(false)
            expect(store.loading).toBe(false)
        })

        it('should set up auth state change listener', async () => {
            mockGetSession.mockResolvedValueOnce({
                data: { session: mockSession },
                error: null,
            })

            await store.initialize()

            expect(mockOnAuthStateChange).toHaveBeenCalled()
        })

        it('should update state when auth changes', async () => {
            mockGetSession.mockResolvedValueOnce({
                data: { session: null },
                error: null,
            })

            let authChangeCallback: any
            mockOnAuthStateChange.mockImplementationOnce((callback: any) => {
                authChangeCallback = callback
                return { data: { subscription: { unsubscribe: vi.fn() } } }
            })

            await store.initialize()

            // Simulate auth state change
            authChangeCallback('SIGNED_IN', mockSession)

            expect(store.user).toEqual(mockUser)
            expect(store.session).toEqual(mockSession)
            expect(store.isAuthenticated).toBe(true)
        })

        it('should set loading to false even on error', async () => {
            mockGetSession.mockRejectedValueOnce(new Error('Network error'))

            try {
                await store.initialize()
            }
            catch {
                // Expected
            }

            expect(store.loading).toBe(false)
        })
    })

    describe('signInWithEmail', () => {
        it('should sign in successfully', async () => {
            const mockData = { user: mockUser, session: mockSession }
            mockSignInWithPassword.mockResolvedValueOnce({
                data: mockData,
                error: null,
            })

            const result = await store.signInWithEmail('test@example.com', 'password123')

            expect(mockSignInWithPassword).toHaveBeenCalledWith({
                email: 'test@example.com',
                password: 'password123',
            })
            expect(result).toEqual(mockData)
        })

        it('should throw user-friendly error for unconfirmed email', async () => {
            mockSignInWithPassword.mockResolvedValueOnce({
                data: null,
                error: { message: 'Email not confirmed' },
            })

            await expect(
                store.signInWithEmail('test@example.com', 'password123')
            ).rejects.toThrow('Email not confirmed. Please check your email and click the verification link.')
        })

        it('should throw user-friendly error for invalid credentials', async () => {
            mockSignInWithPassword.mockResolvedValueOnce({
                data: null,
                error: { message: 'Invalid login credentials' },
            })

            await expect(
                store.signInWithEmail('test@example.com', 'wrongpassword')
            ).rejects.toThrow('Invalid login credentials. Please check your email and password.')
        })

        it('should throw generic error for other failures', async () => {
            mockSignInWithPassword.mockResolvedValueOnce({
                data: null,
                error: { message: 'Server error' },
            })

            await expect(
                store.signInWithEmail('test@example.com', 'password123')
            ).rejects.toThrow('Server error')
        })

        it('should handle error without message', async () => {
            mockSignInWithPassword.mockResolvedValueOnce({
                data: null,
                error: { message: '' },
            })

            await expect(
                store.signInWithEmail('test@example.com', 'password123')
            ).rejects.toThrow('Failed to sign in. Please try again.')
        })
    })

    describe('signUpWithEmail', () => {
        it('should sign up successfully', async () => {
            const mockData = { user: mockUser, session: mockSession }
            mockSignUp.mockResolvedValueOnce({
                data: mockData,
                error: null,
            })

            const result = await store.signUpWithEmail('test@example.com', 'password123')

            expect(mockSignUp).toHaveBeenCalledWith({
                email: 'test@example.com',
                password: 'password123',
            })
            expect(result).toEqual(mockData)
        })

        it('should throw error for existing account', async () => {
            mockSignUp.mockResolvedValueOnce({
                data: null,
                error: { message: 'User already registered' },
            })

            await expect(
                store.signUpWithEmail('test@example.com', 'password123')
            ).rejects.toThrow('An account with this email already exists. Please sign in instead.')
        })

        it('should throw password validation error', async () => {
            mockSignUp.mockResolvedValueOnce({
                data: null,
                error: { message: 'Password should be at least 6 characters' },
            })

            await expect(
                store.signUpWithEmail('test@example.com', '123')
            ).rejects.toThrow('Password should be at least 6 characters')
        })

        it('should throw generic error for other failures', async () => {
            mockSignUp.mockResolvedValueOnce({
                data: null,
                error: { message: 'Server error' },
            })

            await expect(
                store.signUpWithEmail('test@example.com', 'password123')
            ).rejects.toThrow('Server error')
        })
    })

    describe('signInWithGitHub', () => {
        it('should initiate GitHub OAuth flow successfully', async () => {
            const mockData = { provider: 'github', url: 'https://github.com/oauth' }
            mockSignInWithOAuth.mockResolvedValueOnce({
                data: mockData,
                error: null,
            })

            const result = await store.signInWithGitHub()

            expect(mockSignInWithOAuth).toHaveBeenCalledWith({
                provider: 'github',
                options: {
                    redirectTo: `${window.location.origin}/game`,
                },
            })
            expect(result).toEqual(mockData)
        })

        it('should throw error on OAuth failure', async () => {
            mockSignInWithOAuth.mockResolvedValueOnce({
                data: null,
                error: new Error('OAuth provider error'),
            })

            await expect(store.signInWithGitHub()).rejects.toThrow('OAuth provider error')
        })

        it('should use correct redirect URL', async () => {
            mockSignInWithOAuth.mockResolvedValueOnce({
                data: { provider: 'github', url: 'https://github.com/oauth' },
                error: null,
            })

            await store.signInWithGitHub()

            const callArgs = mockSignInWithOAuth.mock.calls[0][0]
            expect(callArgs.options.redirectTo).toContain('/game')
        })
    })

    describe('signOut', () => {
        it('should sign out successfully', async () => {
            // Setup initial state with user
            store.user = mockUser
            store.session = mockSession

            mockSignOut.mockResolvedValueOnce({
                error: null,
            })

            await store.signOut()

            expect(mockSignOut).toHaveBeenCalled()
            expect(store.user).toBeNull()
            expect(store.session).toBeNull()
            expect(store.isAuthenticated).toBe(false)
        })

        it('should throw error on signOut failure', async () => {
            mockSignOut.mockResolvedValueOnce({
                error: new Error('Sign out failed'),
            })

            await expect(store.signOut()).rejects.toThrow('Sign out failed')
        })
    })

    describe('isAuthenticated computed', () => {
        it('should be false when user is null', () => {
            store.user = null
            expect(store.isAuthenticated).toBe(false)
        })

        it('should be true when user exists', () => {
            store.user = mockUser
            expect(store.isAuthenticated).toBe(true)
        })
    })
})


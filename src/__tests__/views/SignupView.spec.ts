import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import SignupView from '@/views/SignupView.vue'
import { useAuthStore } from '@/stores/auth'

// Mock vue-router
vi.mock('vue-router', () => ({
    useRouter: () => ({
        push: vi.fn(),
    }),
    useRoute: () => ({
        query: {},
    }),
}))

// Mock vue-sonner
vi.mock('vue-sonner', () => ({
    toast: {
        success: vi.fn(),
        error: vi.fn(),
    },
}))

// Mock vue-i18n
vi.mock('vue-i18n', () => ({
    useI18n: () => ({
        t: (key: string) => key,
    }),
}))

// Mock Supabase
vi.mock('@/lib/supabase', () => ({
    supabase: {
        auth: {
            getSession: vi.fn().mockResolvedValue({ data: { session: null }, error: null }),
            onAuthStateChange: vi.fn().mockReturnValue({ data: { subscription: { unsubscribe: vi.fn() } } }),
            signInWithPassword: vi.fn(),
            signInWithOAuth: vi.fn(),
            signUp: vi.fn(),
            signOut: vi.fn(),
        },
    },
}))

describe('SignupView', () => {
    beforeEach(() => {
        setActivePinia(createPinia())
    })

    it('renders GitHub login button', () => {
        const wrapper = mount(SignupView)
        const githubButton = wrapper.find('[type="button"]')
        expect(githubButton.exists()).toBe(true)
        expect(githubButton.text()).toContain('GitHub')
    })

    it('calls signInWithGitHub when GitHub button is clicked', async () => {
        const wrapper = mount(SignupView)
        const authStore = useAuthStore()
        const signInWithGitHubSpy = vi.spyOn(authStore, 'signInWithGitHub').mockResolvedValue({} as any)

        const githubButton = wrapper.find('[type="button"]')
        await githubButton.trigger('click')

        expect(signInWithGitHubSpy).toHaveBeenCalled()
    })
})

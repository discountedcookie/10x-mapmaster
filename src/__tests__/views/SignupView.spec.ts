import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import SignupView from '@/views/SignupView.vue'

// Mock supabase
vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: vi.fn().mockResolvedValue({ data: { session: null }, error: null }),
      onAuthStateChange: vi
        .fn()
        .mockReturnValue({ data: { subscription: { unsubscribe: vi.fn() } } }),
      signUp: vi.fn(),
      signInWithOAuth: vi.fn(),
      signInAnonymously: vi.fn(),
      signOut: vi.fn(),
    },
  },
}))

// Mock router
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
})

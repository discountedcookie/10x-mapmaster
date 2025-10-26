import { beforeEach, vi, expect } from 'vitest'
import { createI18n } from 'vue-i18n'
import en from '../i18n/locales/en'
import { messageCompiler } from '../i18n/compiler'
import { axe, toHaveNoViolations } from 'vitest-axe'

// Extend Vitest's expect with axe matchers
expect.extend(toHaveNoViolations)

// Export axe for use in tests
export { axe }

// Mock vue-maplibre-gl to prevent initialization errors
vi.mock('@indoorequal/vue-maplibre-gl', () => ({
  default: {},
  MglMap: { name: 'MglMap' },
  MglMarker: { name: 'MglMarker' },
  MglPopup: { name: 'MglPopup' },
}))

// Mock Supabase globally to prevent initialization errors in tests
vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: vi.fn(),
      onAuthStateChange: vi.fn(() => ({
        data: { subscription: { unsubscribe: vi.fn() } },
      })),
      signInWithPassword: vi.fn(),
      signUp: vi.fn(),
      signOut: vi.fn(),
    },
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          single: vi.fn(),
        })),
      })),
      insert: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
    })),
    rpc: vi.fn(),
    channel: vi.fn(() => ({
      on: vi.fn(function(this: any) { return this }),
      subscribe: vi.fn(() => {}),
    })),
    removeChannel: vi.fn(),
  },
}))

export const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messageCompiler, // Use ICU MessageFormat for advanced formatting
  messages: {
    en,
  },
})

// Suppress Vue warnings in tests (they're often intentional for testing edge cases)
const originalConsoleWarn = console.warn
const originalConsoleError = console.error

beforeEach(() => {
    // Suppress Vue-specific warnings
    console.warn = (...args: any[]) => {
        const message = args[0]?.toString() || ''
        if (message.includes('[Vue warn]')) {
            return // Suppress Vue warnings
        }
        originalConsoleWarn(...args)
    }

    // Keep console.error for real errors, but suppress expected test errors
    console.error = (...args: any[]) => {
        const message = args[0]?.toString() || ''
        // Suppress expected error messages from tests
        if (
            message.includes('Error fetching places') ||
            message.includes('Failed to enrich') ||
            message.includes('Error loading')
        ) {
            return
        }
        originalConsoleError(...args)
    }
})


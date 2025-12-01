import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useTheme } from '@/composables/useTheme'

// Mock VueUse composables
const mockColorMode = { value: 'light' }
const mockStorage = { value: 'auto' }

vi.mock('@vueuse/core', () => ({
  useColorMode: vi.fn(() => mockColorMode),
  useStorage: vi.fn(() => mockStorage),
}))

// Mock window.matchMedia
const mockMatchMedia = vi.fn()

describe('useTheme', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockColorMode.value = 'light'
    mockStorage.value = 'auto'

    // Setup window.matchMedia mock
    Object.defineProperty(globalThis, 'matchMedia', {
      writable: true,
      value: mockMatchMedia,
    })
  })

  describe('Initialization', () => {
    it('should initialize with auto preference', () => {
      mockMatchMedia.mockReturnValue({
        matches: false,
        media: '(prefers-color-scheme: dark)',
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })

      const { preference, resolvedTheme } = useTheme()

      expect(preference.value).toBe('auto')
      expect(resolvedTheme.value).toBe('light')
    })

    it('should detect system dark mode when auto', () => {
      mockMatchMedia.mockReturnValue({
        matches: true,
        media: '(prefers-color-scheme: dark)',
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })

      const { resolvedTheme } = useTheme()

      expect(resolvedTheme.value).toBe('dark')
    })
  })

  describe('setLight', () => {
    it('should set theme to light', () => {
      mockMatchMedia.mockReturnValue({
        matches: false,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })

      const { setLight, preference, resolvedTheme } = useTheme()

      setLight()

      expect(preference.value).toBe('light')
      expect(resolvedTheme.value).toBe('light')
      expect(mockColorMode.value).toBe('light')
    })
  })

  describe('setDark', () => {
    it('should set theme to dark', () => {
      mockMatchMedia.mockReturnValue({
        matches: false,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })

      const { setDark, preference, resolvedTheme } = useTheme()

      setDark()

      expect(preference.value).toBe('dark')
      expect(resolvedTheme.value).toBe('dark')
      expect(mockColorMode.value).toBe('dark')
    })
  })

  describe('setAuto', () => {
    it('should set theme to auto and follow system preference (light)', () => {
      mockMatchMedia.mockReturnValue({
        matches: false,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })

      const { setAuto, preference, resolvedTheme } = useTheme()

      setAuto()

      expect(preference.value).toBe('auto')
      expect(resolvedTheme.value).toBe('light')
      expect(mockColorMode.value).toBe('light')
    })

    it('should set theme to auto and follow system preference (dark)', () => {
      mockMatchMedia.mockReturnValue({
        matches: true,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })

      const { setAuto, preference, resolvedTheme } = useTheme()

      setAuto()

      expect(preference.value).toBe('auto')
      expect(resolvedTheme.value).toBe('dark')
      expect(mockColorMode.value).toBe('dark')
    })
  })

  describe('resolvedTheme computed', () => {
    it('should return preference when not auto', () => {
      mockMatchMedia.mockReturnValue({
        matches: true, // System is dark
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })

      const { setLight, resolvedTheme } = useTheme()

      setLight()

      // Even though system is dark, should show light because preference is explicit
      expect(resolvedTheme.value).toBe('light')
    })

    it('should follow system when preference is auto', () => {
      mockMatchMedia.mockReturnValue({
        matches: true,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })

      const { setAuto, resolvedTheme } = useTheme()

      setAuto()

      expect(resolvedTheme.value).toBe('dark')
    })
  })

  describe('Theme Switching', () => {
    it('should call setter functions', () => {
      mockMatchMedia.mockReturnValue({
        matches: false,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })

      const { setLight, setDark, setAuto, preference } = useTheme()

      setLight()
      expect(preference.value).toBe('light')

      setDark()
      expect(preference.value).toBe('dark')

      setAuto()
      expect(preference.value).toBe('auto')
    })

    it('should update colorMode when switching themes', () => {
      mockMatchMedia.mockReturnValue({
        matches: false,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })

      const { setLight, setDark } = useTheme()

      setLight()
      expect(mockColorMode.value).toBe('light')

      setDark()
      expect(mockColorMode.value).toBe('dark')
    })
  })

  describe('Server-Side Rendering', () => {
    it('should handle missing window object', () => {
      // Temporarily remove window
      const originalWindow = globalThis.window
      // @ts-expect-error - window may not exist in this test environment
      delete globalThis.window

      mockMatchMedia.mockReturnValue({
        matches: false,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })

      const { resolvedTheme } = useTheme()

      // Should default to light when window is not available
      expect(resolvedTheme.value).toBe('light')

      // Restore window
      globalThis.window = originalWindow
    })
  })
})

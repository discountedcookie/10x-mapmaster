import { useColorMode, useStorage } from '@vueuse/core'
import { computed } from 'vue'

/**
 * Composable for managing the application theme (light/dark/auto).
 *
 * Manages both:
 * - User preference (light/dark/auto) - persisted to localStorage
 * - Resolved theme (light/dark) - what's actually applied
 *
 * @returns {object} Theme state and setters
 */
export function useTheme() {
  // Store user preference separately (light/dark/auto)
  const preference = useStorage<'light' | 'dark' | 'auto'>('theme-preference', 'auto')

  // Get the actual resolved color mode (light/dark only)
  const colorMode = useColorMode({
    disableTransition: false,
    modes: {
      light: 'light',
      dark: 'dark',
    },
  })

  // Computed to determine if system is in dark mode
  const isSystemDark = computed(() => {
    if (globalThis.window !== undefined) {
      return globalThis.matchMedia('(prefers-color-scheme: dark)').matches
    }
    return false
  })

  // Computed to get the resolved theme (what should actually be applied)
  const resolvedTheme = computed(() => {
    if (preference.value === 'auto') {
      return isSystemDark.value ? 'dark' : 'light'
    }
    return preference.value
  })

  // Watch preference and update colorMode accordingly
  const setTheme = (value: 'light' | 'dark' | 'auto') => {
    preference.value = value
    if (value === 'auto') {
      colorMode.value = isSystemDark.value ? 'dark' : 'light'
    } else {
      colorMode.value = value
    }
  }

  // Initialize on mount
  setTheme(preference.value)

  return {
    /** User's preference: 'light' | 'dark' | 'auto' */
    preference,
    /** Resolved theme actually applied: 'light' | 'dark' */
    resolvedTheme,
    /** Set theme to light mode */
    setLight: () => setTheme('light'),
    /** Set theme to dark mode */
    setDark: () => setTheme('dark'),
    /** Set theme to follow system preferences */
    setAuto: () => setTheme('auto'),
  }
}

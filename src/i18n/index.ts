import { createI18n } from 'vue-i18n'
import en from './locales/en'
import es from './locales/es'
import pl from './locales/pl'
import { messageCompiler } from './compiler'
import type { MessageSchema, SupportedLocale } from './types'

// Supported locale codes (short form)
const supportedLocales: SupportedLocale[] = ['en', 'es', 'pl']

/**
 * Maps a browser locale (e.g., 'en-US', 'es-ES') to our supported short codes.
 * Returns the short code if supported, or undefined if not.
 */
function mapToSupportedLocale(locale: string): SupportedLocale | undefined {
  // Extract the language part (before hyphen or underscore)
  const parts = locale.split(/[-_]/)
  const languageCode = (parts[0] ?? '').toLowerCase()

  // Check if it's a supported locale
  if (supportedLocales.includes(languageCode as SupportedLocale)) {
    return languageCode as SupportedLocale
  }
  return undefined
}

// Get preferred language from localStorage or browser, fallback to 'en'
const savedLocale = localStorage.getItem('preferred-language')
const browserLocale = navigator.language || 'en'

// Determine default locale: saved preference > mapped browser locale > 'en'
const defaultLocale: SupportedLocale =
  (savedLocale && mapToSupportedLocale(savedLocale)) || mapToSupportedLocale(browserLocale) || 'en'

const i18n = createI18n<[MessageSchema], SupportedLocale>({
  legacy: false, // Enable Composition API mode
  locale: defaultLocale,
  fallbackLocale: 'en',
  messageCompiler, // Use ICU MessageFormat for advanced formatting
  messages: {
    en,
    es,
    pl,
  },
})

export default i18n

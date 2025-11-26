import { createI18n } from 'vue-i18n'
import en from './locales/en'
import es from './locales/es'
import pl from './locales/pl'
import { messageCompiler } from './compiler'

// Get preferred language from localStorage or browser, fallback to 'en-US'
const savedLocale = localStorage.getItem('preferred-language')
const browserLocale = navigator.language || 'en-US'
const supportedLocales = ['en-US', 'es-ES', 'pl-PL']
const defaultLocale =
  savedLocale || (supportedLocales.includes(browserLocale) ? browserLocale : 'en-US')

const i18n = createI18n({
  legacy: false, // Enable Composition API mode
  locale: defaultLocale,
  fallbackLocale: 'en-US',
  messageCompiler, // Use ICU MessageFormat for advanced formatting
  messages: {
    'en-US': en,
    'es-ES': es,
    'pl-PL': pl,
  },
})

export default i18n

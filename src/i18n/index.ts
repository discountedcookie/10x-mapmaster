import { createI18n } from 'vue-i18n'
import en from './locales/en'
import es from './locales/es'
import pl from './locales/pl'
import { messageCompiler } from './compiler'

// Get preferred language from localStorage or browser, fallback to 'en'
const savedLocale = localStorage.getItem('preferred-language')
const browserLocale = navigator.language.split('-')[0] || 'en'
const supportedLocales = ['en', 'es', 'pl']
const defaultLocale = savedLocale || (supportedLocales.includes(browserLocale) ? browserLocale : 'en')

const i18n = createI18n({
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


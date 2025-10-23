import { createI18n } from 'vue-i18n'
import en from './locales/en'
import es from './locales/es'
import { messageCompiler } from './compiler'

// Get preferred language from localStorage or browser, fallback to 'en'
const savedLocale = localStorage.getItem('preferred-language')
const browserLocale = navigator.language.split('-')[0] || 'en'
const supportedLocales = ['en', 'es']
const defaultLocale = savedLocale || (supportedLocales.includes(browserLocale) ? browserLocale : 'en')

const i18n = createI18n({
  legacy: false, // Enable Composition API mode
  locale: defaultLocale,
  fallbackLocale: 'en',
  messageCompiler, // Use ICU MessageFormat for advanced formatting
  messages: {
    en,
    es,
  },
})

export default i18n


import { createI18n } from 'vue-i18n'
import en from './locales/en'
import { messageCompiler } from './compiler'

const i18n = createI18n({
  legacy: false, // Enable Composition API mode
  locale: 'en',
  fallbackLocale: 'en',
  messageCompiler, // Use ICU MessageFormat for advanced formatting
  messages: {
    en,
  },
})

export default i18n


import type en from './locales/en'

// Define the message schema based on English messages
export type MessageSchema = typeof en

// Supported locale codes (short form)
export type SupportedLocale = 'en' | 'es' | 'pl'

// Extend vue-i18n module declarations for type safety
declare module 'vue-i18n' {
  // Use interface merging instead of redefining the type
  export interface DefineLocaleMessage extends MessageSchema {}
}

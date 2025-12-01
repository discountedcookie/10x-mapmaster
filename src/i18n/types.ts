import type en from './locales/en'

// Define the message schema based on English messages
export type MessageSchema = typeof en

// Extend vue-i18n module declarations for type safety
declare module 'vue-i18n' {
  export type DefineLocaleMessage = MessageSchema
}

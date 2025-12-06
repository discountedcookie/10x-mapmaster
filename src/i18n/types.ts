import type en from './locales/en'

// Define the message schema based on English messages
export type MessageSchema = typeof en

// Supported locale codes (short form)
export type SupportedLocale = 'en'

// Extend vue-i18n module declarations for type safety
declare module 'vue-i18n' {
  // eslint-disable-next-line @typescript-eslint/no-empty-object-type
  export interface DefineLocaleMessage extends MessageSchema {}
}

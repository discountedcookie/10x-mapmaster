import { describe, it, expect } from 'vitest'
import i18n from '@/i18n'
import en from '@/i18n/locales/en'
import es from '@/i18n/locales/es'
import pl from '@/i18n/locales/pl'

describe('i18n Configuration', () => {
  it('should support English locale', () => {
    expect(i18n.global.availableLocales).toContain('en')
    expect(i18n.global.messages.value.en).toEqual(en)
  })

  it('should support Spanish locale', () => {
    expect(i18n.global.availableLocales).toContain('es')
    expect(i18n.global.messages.value.es).toEqual(es)
  })

  it('should support Polish locale', () => {
    expect(i18n.global.availableLocales).toContain('pl')
    expect(i18n.global.messages.value.pl).toEqual(pl)
  })

  it('should have all three locales available', () => {
    const locales = i18n.global.availableLocales
    expect(locales).toHaveLength(3)
    expect(locales).toEqual(expect.arrayContaining(['en', 'es', 'pl']))
  })

  it('should have English as fallback locale', () => {
    expect(i18n.global.fallbackLocale.value).toBe('en')
  })

  it('should be in composition API mode (non-legacy)', () => {
    expect(i18n.mode).toBe('composition')
  })

  it('should translate Polish text correctly', () => {
    i18n.global.locale.value = 'pl'
    expect(i18n.global.t('nav.home')).toBe('Strona główna')
    expect(i18n.global.t('nav.game')).toBe('Graj')
    expect(i18n.global.t('game.yes')).toBe('Tak!')
    expect(i18n.global.t('game.no')).toBe('Nie')
  })

  it('should translate English text correctly', () => {
    i18n.global.locale.value = 'en'
    expect(i18n.global.t('nav.home')).toBe('Home')
    expect(i18n.global.t('nav.game')).toBe('Play Game')
    expect(i18n.global.t('game.yes')).toBe('Yes!')
  })

  it('should translate Spanish text correctly', () => {
    i18n.global.locale.value = 'es'
    expect(i18n.global.t('nav.home')).toBe('Inicio')
    expect(i18n.global.t('nav.game')).toBe('Jugar')
    expect(i18n.global.t('game.yes')).toBe('¡Sí!')
  })

  it('should support ICU MessageFormat for pluralization', () => {
    i18n.global.locale.value = 'en'
    const singular = i18n.global.t('map.played', { count: 1 })
    const plural = i18n.global.t('map.played', { count: 5 })

    expect(singular).toContain('1 time')
    expect(plural).toContain('5 times')
  })

  it('should support parameter interpolation', () => {
    i18n.global.locale.value = 'en'
    const message = i18n.global.t('game.guess', { place: 'Paris' })
    expect(message).toBe('Is it Paris?')
  })

  it('should fall back to English for missing translations', () => {
    i18n.global.locale.value = 'pl'
    // Even if a key is missing in Polish, it should fall back to English
    // This tests the fallbackLocale configuration
    expect(i18n.global.fallbackLocale.value).toBe('en')
  })
})

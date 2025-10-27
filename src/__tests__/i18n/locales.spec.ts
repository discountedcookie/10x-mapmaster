import { describe, it, expect } from 'vitest'
import en from '@/i18n/locales/en'
import es from '@/i18n/locales/es'
import pl from '@/i18n/locales/pl'

describe('i18n Translation Files', () => {
  const languages = { en, es, pl }
  const languageCodes = Object.keys(languages)

  describe('Translation Completeness', () => {
    it('should have all required languages', () => {
      expect(languageCodes).toContain('en')
      expect(languageCodes).toContain('es')
      expect(languageCodes).toContain('pl')
    })

    it('should have all main sections in each language', () => {
      const expectedSections = [
        'nav',
        'game',
        'common',
        'home',
        'auth',
        'statistics',
        'theme',
        'language',
        'confidence',
        'map',
      ]

      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        expectedSections.forEach((section) => {
          expect(translations).toHaveProperty(section)
        })
      })
    })

    it('should have matching keys across all languages', () => {
      const getKeys = (obj: Record<string, any>, prefix = ''): string[] => {
        return Object.keys(obj).reduce((keys: string[], key) => {
          const fullKey = prefix ? `${prefix}.${key}` : key
          if (typeof obj[key] === 'object' && obj[key] !== null) {
            return [...keys, ...getKeys(obj[key], fullKey)]
          }
          return [...keys, fullKey]
        }, [])
      }

      const enKeys = getKeys(en).sort()
      const esKeys = getKeys(es).sort()
      const plKeys = getKeys(pl).sort()

      expect(esKeys).toEqual(enKeys)
      expect(plKeys).toEqual(enKeys)
    })
  })

  describe('Navigation Translations', () => {
    it('should have all navigation items', () => {
      const navKeys = ['home', 'game', 'statistics', 'login', 'signup', 'logout']

      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        navKeys.forEach((key) => {
          expect(translations.nav).toHaveProperty(key)
          expect(typeof translations.nav[key as keyof typeof translations.nav]).toBe('string')
          expect(translations.nav[key as keyof typeof translations.nav]).toBeTruthy()
        })
      })
    })
  })

  describe('Game Translations', () => {
    it('should have all game sections', () => {
      const gameSections = [
        'validation',
        'toast',
        'loading_overlay',
        'question_card',
        'result_card',
        'place_search',
      ]

      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        gameSections.forEach((section) => {
          expect(translations.game).toHaveProperty(section)
        })
      })
    })

    it('should have validation messages with parameters', () => {
      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        expect(translations.game.validation.min_length).toContain('{length}')
        expect(translations.game.validation.min_length).toContain('{current}')
        expect(translations.game.validation.max_length).toContain('{length}')
      })
    })

    it('should have guess message with place parameter', () => {
      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        expect(translations.game.guess).toContain('{place}')
      })
    })

    it('should have question card translations with parameters', () => {
      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        expect(translations.game.question_card.question_number).toContain('{current}')
        expect(translations.game.question_card.question_number).toContain('{total}')
      })
    })
  })

  describe('Authentication Translations', () => {
    it('should have all auth fields', () => {
      const authFields = [
        'email',
        'password',
        'login_title',
        'signup_title',
        'login_button',
        'signup_button',
        'confirm_password',
      ]

      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        authFields.forEach((field) => {
          expect(translations.auth).toHaveProperty(field)
          expect(typeof translations.auth[field as keyof typeof translations.auth]).toBe('string')
        })
      })
    })

    it('should have auth toast messages', () => {
      const toastKeys = [
        'account_created_title',
        'account_created_body',
        'welcome_back_title',
        'welcome_back_body',
        'signed_out_success',
      ]

      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        toastKeys.forEach((key) => {
          expect(translations.auth.toast).toHaveProperty(key)
        })
      })
    })

    it('should have validation messages with parameters', () => {
      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        expect(translations.auth.validation.password_min_length).toContain('{length}')
      })
    })
  })

  describe('Language Translations', () => {
    it('should have all language names', () => {
      const languageNames = ['english', 'spanish', 'polish']

      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        languageNames.forEach((name) => {
          expect(translations.language).toHaveProperty(name)
        })
      })
    })

    it('should have Polish language translation', () => {
      expect(en.language.polish).toBe('Polski')
      expect(es.language.polish).toBe('Polski')
      expect(pl.language.polish).toBe('Polski')
    })
  })

  describe('Confidence Translations', () => {
    it('should have confidence levels with percent parameter', () => {
      const levels = ['high', 'medium', 'low']

      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        levels.forEach((level) => {
          expect(translations.confidence[level as keyof typeof translations.confidence]).toContain(
            '{percent}'
          )
        })
      })
    })

    it('should have confidence tooltips', () => {
      const tooltips = ['high', 'medium', 'low']

      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        tooltips.forEach((tooltip) => {
          expect(translations.confidence.tooltip).toHaveProperty(tooltip)
        })
      })
    })
  })

  describe('Map Translations', () => {
    it('should have ICU plural format in played message', () => {
      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        expect(translations.map.played).toContain('{count}')
        expect(translations.map.played).toContain('plural')
      })
    })

    it('should have marker aria label with parameters', () => {
      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        expect(translations.map.marker_aria_label).toContain('{name}')
        expect(translations.map.marker_aria_label).toContain('{percent}')
      })
    })
  })

  describe('Polish Language Specific Validations', () => {
    it('should have proper Polish translations', () => {
      // Navigation
      expect(pl.nav.home).toBe('Strona główna')
      expect(pl.nav.game).toBe('Graj')
      expect(pl.nav.statistics).toBe('Statystyki')

      // Common
      expect(pl.common.loading).toBe('Ładowanie...')
      expect(pl.common.error).toBe('Ups, coś poszło nie tak')

      // Game
      expect(pl.game.title).toBe('Gra geograficzna')
      expect(pl.game.yes).toBe('Tak!')
      expect(pl.game.no).toBe('Nie')

      // Auth
      expect(pl.auth.email).toBe('Email')
      expect(pl.auth.password).toBe('Hasło')

      // Language
      expect(pl.language.title).toBe('Język')
      expect(pl.language.current).toBe('Aktualny język')
    })

    it('should have Polish pluralization rules', () => {
      // Polish has complex plural rules (one/few/many)
      expect(pl.map.played).toContain('plural')
      expect(pl.map.played).toContain('raz')
      expect(pl.map.played).toContain('razy')
    })
  })

  describe('Translation String Quality', () => {
    it('should not have empty translation strings', () => {
      const checkEmptyStrings = (obj: Record<string, any>, path = ''): void => {
        Object.keys(obj).forEach((key) => {
          const currentPath = path ? `${path}.${key}` : key
          const value = obj[key]

          if (typeof value === 'object' && value !== null) {
            checkEmptyStrings(value, currentPath)
          } else if (typeof value === 'string') {
            expect(value.trim(), `Empty translation at ${currentPath}`).not.toBe('')
          }
        })
      }

      languageCodes.forEach((lang) => {
        const translations = languages[lang as keyof typeof languages]
        checkEmptyStrings(translations, lang)
      })
    })

    it('should have consistent parameter usage across languages', () => {
      const extractParams = (str: string): string[] => {
        const matches = str.match(/\{[^}]+\}/g)
        return matches ? matches.sort() : []
      }

      const checkParams = (obj: Record<string, any>, basePath = ''): void => {
        Object.keys(obj).forEach((key) => {
          const currentPath = basePath ? `${basePath}.${key}` : key
          const enValue = obj[key]

          if (typeof enValue === 'object' && enValue !== null) {
            checkParams(enValue, currentPath)
          } else if (typeof enValue === 'string') {
            const enParams = extractParams(enValue)

            if (enParams.length > 0) {
              languageCodes.forEach((lang) => {
                if (lang !== 'en') {
                  const translation = languages[lang as keyof typeof languages]
                  const keys = currentPath.split('.')
                  let value: any = translation

                  keys.forEach((k) => {
                    value = value?.[k]
                  })

                  if (typeof value === 'string') {
                    const langParams = extractParams(value)
                    expect(
                      langParams,
                      `Parameter mismatch at ${currentPath} for ${lang}`
                    ).toEqual(enParams)
                  }
                }
              })
            }
          }
        })
      }

      checkParams(en)
    })
  })
})

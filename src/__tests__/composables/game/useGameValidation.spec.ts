import { describe, expect, it, beforeEach, vi } from 'vitest'
import { ref } from 'vue'
import { useGameValidation } from '@/composables/game/useGameValidation'

// Mock i18n
const mockT = vi.fn((key: string, params?: any) => {
  if (key === 'game.validation.min_length') {
    return `At least ${params.length} characters required (${params.current} current)`
  }
  if (key === 'game.validation.max_length') {
    return `Maximum ${params.length} characters allowed`
  }
  return key
})

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: mockT,
  }),
}))

describe('useGameValidation', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('Initial State', () => {
    it('should initialize with empty description', () => {
      const description = ref('')
      const { isDescriptionValid, validationMessage, descriptionLength } = useGameValidation(description)

      expect(descriptionLength.value).toBe(0)
      expect(isDescriptionValid.value).toBe(false)
      expect(validationMessage.value).toBe('')
    })
  })

  describe('Minimum Length Validation', () => {
    it('should be invalid when description is too short', () => {
      const description = ref('Short')
      const { isDescriptionValid, MIN_DESCRIPTION_LENGTH } = useGameValidation(description)

      expect(description.value.length).toBeLessThan(MIN_DESCRIPTION_LENGTH)
      expect(isDescriptionValid.value).toBe(false)
    })

    it('should show validation message when below minimum', () => {
      const description = ref('Test')
      const { validationMessage } = useGameValidation(description)

      expect(validationMessage.value).toContain('At least 10 characters required')
      expect(validationMessage.value).toContain('4 current')
    })

    it('should be valid at exactly minimum length', () => {
      const description = ref('1234567890') // Exactly 10 chars
      const { isDescriptionValid } = useGameValidation(description)

      expect(isDescriptionValid.value).toBe(true)
    })

    it('should not show message for empty description', () => {
      const description = ref('')
      const { validationMessage } = useGameValidation(description)

      expect(validationMessage.value).toBe('')
    })
  })

  describe('Maximum Length Validation', () => {
    it('should be invalid when description is too long', () => {
      const longText = 'x'.repeat(501)
      const description = ref(longText)
      const { isDescriptionValid, MAX_DESCRIPTION_LENGTH } = useGameValidation(description)

      expect(description.value.length).toBeGreaterThan(MAX_DESCRIPTION_LENGTH)
      expect(isDescriptionValid.value).toBe(false)
    })

    it('should show validation message when above maximum', () => {
      const description = ref('x'.repeat(501))
      const { validationMessage } = useGameValidation(description)

      expect(validationMessage.value).toContain('Maximum 500 characters allowed')
    })

    it('should be valid at exactly maximum length', () => {
      const description = ref('x'.repeat(500)) // Exactly 500 chars
      const { isDescriptionValid } = useGameValidation(description)

      expect(isDescriptionValid.value).toBe(true)
    })
  })

  describe('Valid Descriptions', () => {
    it('should be valid for normal description', () => {
      const description = ref('A beautiful city in France with the Eiffel Tower')
      const { isDescriptionValid } = useGameValidation(description)

      expect(isDescriptionValid.value).toBe(true)
    })

    it('should have no validation message for valid description', () => {
      const description = ref('A place with mountains and lakes')
      const { validationMessage } = useGameValidation(description)

      expect(validationMessage.value).toBe('')
    })
  })

  describe('Whitespace Handling', () => {
    it('should trim whitespace for validation', () => {
      const description = ref('   Short   ')
      const { isDescriptionValid } = useGameValidation(description)

      // "Short" is only 5 chars after trim, below minimum
      expect(isDescriptionValid.value).toBe(false)
    })

    it('should be valid if trimmed length meets minimum', () => {
      const description = ref('   Valid description here   ')
      const { isDescriptionValid } = useGameValidation(description)

      // Should be valid as trimmed length > 10
      expect(isDescriptionValid.value).toBe(true)
    })

    it('should count whitespace-only as empty', () => {
      const description = ref('     ')
      const { validationMessage, isDescriptionValid } = useGameValidation(description)

      expect(isDescriptionValid.value).toBe(false)
      expect(validationMessage.value).toBe('') // Empty string shows no message
    })
  })

  describe('Reactivity', () => {
    it('should update validation when description changes', () => {
      const description = ref('Short')
      const { isDescriptionValid } = useGameValidation(description)

      expect(isDescriptionValid.value).toBe(false)

      description.value = 'A valid description with enough characters'
      expect(isDescriptionValid.value).toBe(true)

      description.value = 'x'.repeat(501)
      expect(isDescriptionValid.value).toBe(false)
    })

    it('should update message when description changes', () => {
      const description = ref('Test')
      const { validationMessage } = useGameValidation(description)

      expect(validationMessage.value).toContain('At least 10 characters')

      description.value = 'x'.repeat(501)
      expect(validationMessage.value).toContain('Maximum 500 characters')

      description.value = 'Valid description'
      expect(validationMessage.value).toBe('')
    })

    it('should update length when description changes', () => {
      const description = ref('Test')
      const { descriptionLength } = useGameValidation(description)

      expect(descriptionLength.value).toBe(4)

      description.value = 'Testing'
      expect(descriptionLength.value).toBe(7)
    })
  })

  describe('Edge Cases', () => {
    it('should handle description with special characters', () => {
      const description = ref('City with café, naïve, and émigré')
      const { isDescriptionValid } = useGameValidation(description)

      expect(isDescriptionValid.value).toBe(true)
    })

    it('should handle description with numbers', () => {
      const description = ref('Place with 123 buildings and 456 people')
      const { isDescriptionValid } = useGameValidation(description)

      expect(isDescriptionValid.value).toBe(true)
    })

    it('should handle multiline descriptions', () => {
      const description = ref('A place\nwith multiple\nlines of text here')
      const { isDescriptionValid } = useGameValidation(description)

      expect(isDescriptionValid.value).toBe(true)
    })

    it('should handle description with emojis', () => {
      const description = ref('A beautiful city 🏙️ with the Eiffel Tower 🗼')
      const { isDescriptionValid } = useGameValidation(description)

      expect(isDescriptionValid.value).toBe(true)
    })
  })

  describe('Constants Export', () => {
    it('should export MIN_DESCRIPTION_LENGTH constant', () => {
      const description = ref('')
      const { MIN_DESCRIPTION_LENGTH } = useGameValidation(description)

      expect(MIN_DESCRIPTION_LENGTH).toBe(10)
    })

    it('should export MAX_DESCRIPTION_LENGTH constant', () => {
      const description = ref('')
      const { MAX_DESCRIPTION_LENGTH } = useGameValidation(description)

      expect(MAX_DESCRIPTION_LENGTH).toBe(500)
    })
  })
})

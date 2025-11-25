import { computed, type Ref } from 'vue'
import { useI18n } from 'vue-i18n'

const MIN_DESCRIPTION_LENGTH = 10
const MAX_DESCRIPTION_LENGTH = 100

// Validation patterns for prompt injection detection
const CONTROL_CHARS_PATTERN = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/
const EXCESSIVE_NEWLINES_PATTERN = /\n{3,}/
const ROLE_INJECTION_PATTERN = /(system|assistant|user)\s*:/i
const INSTRUCTION_OVERRIDE_PATTERN = /(ignore|disregard|forget).*(instruction|prompt|rule)/i

export function useGameValidation(description: Ref<string>) {
  const { t } = useI18n()

  const descriptionLength = computed(() => description.value.length)

  const isDescriptionValid = computed(() => {
    const trimmed = description.value.trim()

    // Length validation
    if (trimmed.length < MIN_DESCRIPTION_LENGTH || trimmed.length > MAX_DESCRIPTION_LENGTH) {
      return false
    }

    // Content validation
    if (CONTROL_CHARS_PATTERN.test(trimmed)) {
      return false
    }

    if (EXCESSIVE_NEWLINES_PATTERN.test(trimmed)) {
      return false
    }

    if (ROLE_INJECTION_PATTERN.test(trimmed)) {
      return false
    }

    if (INSTRUCTION_OVERRIDE_PATTERN.test(trimmed)) {
      return false
    }

    return true
  })

  const validationMessage = computed(() => {
    const trimmed = description.value.trim()
    if (trimmed.length === 0) return ''

    // Length validation messages
    if (trimmed.length < MIN_DESCRIPTION_LENGTH) {
      return t('game.validation.min_length', {
        length: MIN_DESCRIPTION_LENGTH,
        current: trimmed.length,
      })
    }
    if (trimmed.length > MAX_DESCRIPTION_LENGTH) {
      return t('game.validation.max_length', { length: MAX_DESCRIPTION_LENGTH })
    }

    // Content validation messages
    if (CONTROL_CHARS_PATTERN.test(trimmed)) {
      return t('game.validation.invalid_characters')
    }

    if (EXCESSIVE_NEWLINES_PATTERN.test(trimmed)) {
      return t('game.validation.excessive_newlines')
    }

    if (ROLE_INJECTION_PATTERN.test(trimmed)) {
      return t('game.validation.invalid_content')
    }

    if (INSTRUCTION_OVERRIDE_PATTERN.test(trimmed)) {
      return t('game.validation.invalid_content')
    }

    return ''
  })

  return {
    isDescriptionValid,
    validationMessage,
    descriptionLength,
    MIN_DESCRIPTION_LENGTH,
    MAX_DESCRIPTION_LENGTH,
  }
}

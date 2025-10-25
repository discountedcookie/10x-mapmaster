import { computed, type Ref } from 'vue'
import { useI18n } from 'vue-i18n'

const MIN_DESCRIPTION_LENGTH = 10
const MAX_DESCRIPTION_LENGTH = 500

export function useGameValidation(description: Ref<string>) {
  const { t } = useI18n()

  const descriptionLength = computed(() => description.value.length)

  const isDescriptionValid = computed(() => {
    const trimmed = description.value.trim()
    return trimmed.length >= MIN_DESCRIPTION_LENGTH && trimmed.length <= MAX_DESCRIPTION_LENGTH
  })

  const validationMessage = computed(() => {
    const trimmed = description.value.trim()
    if (trimmed.length === 0) return ''
    if (trimmed.length < MIN_DESCRIPTION_LENGTH) {
      return t('game.validation.min_length', {
        length: MIN_DESCRIPTION_LENGTH,
        current: trimmed.length
      })
    }
    if (trimmed.length > MAX_DESCRIPTION_LENGTH) {
      return t('game.validation.max_length', { length: MAX_DESCRIPTION_LENGTH })
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
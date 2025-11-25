<script setup lang="ts">
import { ref, computed } from 'vue'
import { Icon } from '@iconify/vue'
import { useI18n } from 'vue-i18n'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'

interface Props {
  placeholder?: string
  disabled?: boolean
  loading?: boolean
  minLength?: number
  maxLength?: number
}

interface Emits {
  (e: 'submit', value: string): void
}

const props = withDefaults(defineProps<Props>(), {
  placeholder: 'Describe a place...',
  disabled: false,
  loading: false,
  minLength: 10,
  maxLength: 200,
})

const emit = defineEmits<Emits>()
const { t } = useI18n()

const inputValue = ref('')

const isValid = computed(() => {
  const length = inputValue.value.length
  return length >= props.minLength && length <= props.maxLength
})

const validationMessage = computed(() => {
  const length = inputValue.value.length
  if (length === 0) return ''
  if (length < props.minLength) {
    return `At least ${props.minLength} characters required`
  }
  if (length > props.maxLength) {
    return `Maximum ${props.maxLength} characters`
  }
  return ''
})

function handleSubmit() {
  if (!isValid.value || props.disabled || props.loading) return
  emit('submit', inputValue.value)
  inputValue.value = ''
}

function handleKeydown(event: KeyboardEvent) {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault()
    handleSubmit()
  }
}
</script>

<template>
  <Card class="p-4 shadow-lg">
    <div class="space-y-3">
      <!-- Input area -->
      <div class="relative">
        <Input
          v-model="inputValue"
          :placeholder="placeholder"
          :disabled="disabled || loading"
          :maxlength="maxLength"
          class="pr-12 h-12 text-base"
          @keydown="handleKeydown"
        />
        <Button
          size="icon"
          class="absolute right-1 top-1 h-10 w-10 rounded-full"
          :disabled="!isValid || disabled || loading"
          @click="handleSubmit"
        >
          <Icon v-if="loading" icon="radix-icons:update" class="h-5 w-5 animate-spin" />
          <Icon v-else icon="radix-icons:paper-plane" class="h-5 w-5" />
        </Button>
      </div>

      <!-- Validation message and character count -->
      <div class="flex justify-between items-center text-xs">
        <p v-if="validationMessage" class="text-destructive">
          {{ validationMessage }}
        </p>
        <p v-else class="text-muted-foreground">{{ minLength }}-{{ maxLength }} characters</p>
        <p
          class="text-muted-foreground"
          :class="{ 'text-destructive': inputValue.length > maxLength }"
        >
          {{ inputValue.length }}/{{ maxLength }}
        </p>
      </div>
    </div>
  </Card>
</template>

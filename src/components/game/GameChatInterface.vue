<script setup lang="ts">
import { computed, nextTick, ref, watch } from 'vue'
import { useGameStore } from '@/stores/game'
import { Button } from '@/components/ui/button'

import { Card } from '@/components/ui/card'

interface Properties {
  gameState: import('@/stores/game').GameState
}

interface Emits {
  playAgain: []
  submitPlace: []
}

const emit = defineEmits<Emits>()

const props = defineProps<Properties>()

const gameStore = useGameStore()

// Direct computed from prop to ensure reactivity when gameState object is replaced
const messages = computed(() => props.gameState.messages)

const scrollAreaRef = ref<HTMLElement>()

// Auto-scroll to bottom when new messages
const autoScroll = async () => {
  await nextTick()
  if (scrollAreaRef.value) {
    scrollAreaRef.value.scrollTop = scrollAreaRef.value.scrollHeight
  }
}

// Watch for new messages
watch(() => messages.value.length, autoScroll, { immediate: true })

const handleAnswer = async (answer: boolean) => {
  await gameStore.answerQuestion(answer)
}

const handleGuess = async (answer: boolean) => {
  await gameStore.answerQuestion(answer)
}

const handleSubmitPlace = () => {
  // Emit event to show submission dialog
  emit('submitPlace')
}
</script>

<template>
  <Card class="chat-interface h-full flex flex-col">
    <div class="chat-header p-4 border-b">
      <h3 class="text-lg font-semibold">
        {{ gameState.description }}
      </h3>
    </div>

    <div ref="scrollAreaRef" class="flex-1 p-4 overflow-auto">
      <div class="chat-messages space-y-4">
        <div
          v-for="msg in messages"
          :key="msg.id"
          :class="['message', msg.role === 'system' ? 'system-message' : 'user-message']"
        >
          <div
            :class="[
              'message-bubble p-3 rounded-lg max-w-[80%]',
              msg.role === 'system'
                ? 'bg-muted text-muted-foreground'
                : 'bg-primary text-primary-foreground',
            ]"
          >
            {{ msg.text }}
          </div>
        </div>
      </div>
    </div>

    <div class="chat-input p-4 border-t">
      <!-- Show answer buttons if last message is a question -->
      <div v-if="messages[messages.length - 1]?.type === 'question'" class="flex gap-2">
        <Button variant="default" @click="handleAnswer(true)"> Yes </Button>
        <Button variant="outline" @click="handleAnswer(false)"> No </Button>
      </div>

      <!-- Show guess buttons if last message is a guess -->
      <div v-else-if="messages[messages.length - 1]?.type === 'guess'" class="flex gap-2">
        <Button variant="default" @click="handleGuess(true)"> Yes, correct! </Button>
        <Button variant="outline" @click="handleGuess(false)"> No, try again </Button>
      </div>

      <!-- Show submit button if needs submission -->
      <div v-else-if="props.gameState.status === 'needs_submission'" class="flex gap-2">
        <Button variant="default" @click="handleSubmitPlace"> Submit this place </Button>
      </div>

      <!-- Show play again button if game is won -->
      <div v-else-if="props.gameState.status === 'won'" class="flex gap-2">
        <Button variant="default" @click="$emit('playAgain')"> Play Again </Button>
      </div>
    </div>
  </Card>
</template>

<style scoped>
.system-message {
  @apply flex justify-start;
}

.user-message {
  @apply flex justify-end;
}
</style>

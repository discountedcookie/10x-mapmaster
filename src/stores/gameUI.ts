import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { ChatMessage } from '@/types/game'

export const useGameUIStore = defineStore('gameUI', () => {
  // State
  const messages = ref<ChatMessage[]>([])
  const hoveredPlaceId = ref<string | undefined>()

  /**
   * Add message to UI
   */
  function addMessage(
    role: 'system' | 'user',
    text: string,
    type: string,
    metadata?: ChatMessage['metadata']
  ): void {
    const message: ChatMessage = {
      id: `${type}-${Date.now()}`,
      role,
      type: type as ChatMessage['type'],
      text,
      timestamp: new Date(),
      metadata,
    }
    messages.value.push(message)
  }

  /**
   * Clear all messages
   */
  function clearMessages(): void {
    messages.value = []
  }

  /**
   * Set hovered place ID
   */
  function setHoveredPlace(placeId: string | undefined): void {
    hoveredPlaceId.value = placeId
  }

  return {
    messages,
    hoveredPlaceId,
    addMessage,
    clearMessages,
    setHoveredPlace,
  }
})

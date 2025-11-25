<script setup lang="ts">
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from '@/components/ui/sheet'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { History, TrendingUp, TrendingDown } from 'lucide-vue-next'

interface ChatMessage {
  id: string
  role: 'system' | 'user'
  type: 'question' | 'guess' | 'answer' | 'message'
  text: string
  timestamp: Date
}

interface Props {
  history: ChatMessage[]
  questionCount: number
}

const props = defineProps<Props>()

// Get user messages from history
const userHistory = props.history.filter((msg) => msg.type === 'question' || msg.type === 'answer')
</script>

<template>
  <Sheet>
    <SheetTrigger as-child>
      <Button variant="ghost" size="sm" class="w-full md:hidden gap-2">
        <History class="w-4 h-4" />
        View Journey (Q {{ questionCount }})
      </Button>
    </SheetTrigger>
    <SheetContent side="bottom" class="h-[60vh]">
      <SheetHeader>
        <SheetTitle class="flex items-center gap-2">
          <History class="w-5 h-5" />
          Your Search Journey
        </SheetTitle>
      </SheetHeader>

      <div class="mt-6 space-y-4 overflow-y-auto max-h-[calc(60vh-100px)] pb-4">
        <div v-if="userHistory.length > 0" class="space-y-4">
          <div v-for="(msg, idx) in userHistory" :key="idx" class="relative pl-8 pb-6 last:pb-0">
            <!-- Timeline line -->
            <div
              v-if="idx < userHistory.length - 1"
              class="absolute left-3 top-6 bottom-0 w-0.5 bg-border"
            />

            <!-- Timeline dot -->
            <div
              class="absolute left-0 top-1 w-6 h-6 rounded-full border-2 border-primary bg-background flex items-center justify-center"
            >
              <div class="w-2 h-2 rounded-full bg-primary" />
            </div>

            <!-- Content -->
            <div class="space-y-2">
              <div class="flex items-center gap-2">
                <Badge variant="default" class="font-mono"
                  >{{ msg.type === 'question' ? 'Q' : 'A' }}{{ idx + 1 }}</Badge
                >
                <span class="text-sm text-muted-foreground">
                  {{ msg.type === 'question' ? 'Question' : 'Answer' }}
                </span>
              </div>
              <p class="text-sm">{{ msg.text }}</p>
            </div>
          </div>
        </div>

        <div v-else class="text-center text-muted-foreground py-8">
          <History class="w-12 h-12 mx-auto mb-3 opacity-20" />
          <p class="text-sm">No history yet</p>
          <p class="text-xs mt-1">Answer questions to build your journey!</p>
        </div>
      </div>
    </SheetContent>
  </Sheet>
</template>

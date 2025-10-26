<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { useI18n } from 'vue-i18n'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Textarea } from '@/components/ui/textarea'

interface Props {
  description: string
  validationMessage: string
  descriptionLength: number
  isValid: boolean
  loading: boolean
  minLength: number
  maxLength: number
}

interface Emits {
  (e: 'update:description', value: string): void
  (e: 'start'): void
  (e: 'goHome'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()
const { t } = useI18n()
</script>

<template>
  <Card
    class="w-full animate-slide-up-fade"
    style="box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(0, 0, 0, 0.05);"
  >
    <CardHeader class="text-center space-y-3">
      <CardTitle class="text-4xl font-bold flex items-center justify-center gap-3">
        <Icon
          icon="radix-icons:pencil-1"
          class="h-10 w-10 text-primary"
        />
        {{ t('game.describe_place_title') }}
      </CardTitle>
      <CardDescription class="text-xl">
        {{ t('game.describe_place_description') }}
      </CardDescription>
    </CardHeader>
    <CardContent class="flex flex-col gap-4">
      <div class="space-y-2">
        <Textarea
          :model-value="description"
          :placeholder="t('game.description_placeholder')"
          rows="4"
          class="resize-none"
          :maxlength="maxLength"
          @update:model-value="emit('update:description', $event)"
        />
        <div class="flex justify-between items-center text-sm gap-2">
          <p
            v-if="validationMessage"
            class="text-destructive flex-1"
          >
            {{ validationMessage }}
          </p>
          <p
            v-else
            class="text-muted-foreground flex-1"
          >
            {{ minLength }}-{{ maxLength }} {{ t('common.characters') }}
          </p>
          <p
            class="text-muted-foreground whitespace-nowrap"
            :class="{ 'text-destructive': descriptionLength > maxLength }"
          >
            {{ descriptionLength }}/{{ maxLength }}
          </p>
        </div>
      </div>
      <Button
        size="lg"
        class="transition-playful"
        :disabled="!isValid || loading"
        @click="emit('start')"
      >
        <Icon
          v-if="!loading"
          icon="radix-icons:play"
          class="h-5 w-5 mr-2"
        />
        {{ loading ? t('game.starting') : t('game.start_game') }}
      </Button>
      <Button
        size="lg"
        variant="outline"
        class="transition-playful"
        @click="emit('goHome')"
      >
        <Icon
          icon="radix-icons:home"
          class="h-5 w-5 mr-2"
        />
        {{ t('common.back_to_home') }}
      </Button>
    </CardContent>
  </Card>
</template>

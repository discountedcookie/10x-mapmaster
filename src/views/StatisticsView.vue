<script setup lang="ts">
import { onMounted } from 'vue'
import { Icon } from '@iconify/vue'

interface Props {
  renderMode?: 'layers' | 'ui'
}

const props = withDefaults(defineProps<Props>(), {
  renderMode: 'ui',
})
import { useI18n } from 'vue-i18n'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { useStatistics } from '@/composables/useStatistics'

const { t } = useI18n()
const { loading, error, statistics, fetchStatistics } = useStatistics()

onMounted(() => {
  fetchStatistics()
})

function formatPercentage(value: number): string {
  return value.toFixed(1)
}

function formatAverage(value: number): string {
  return value.toFixed(1)
}
</script>

<template>
  <!-- No map layers for statistics view -->
  <template v-if="renderMode === 'layers'" />

  <!-- UI - Statistics card over map -->
  <div v-else class="absolute inset-0 flex items-center justify-center pointer-events-none p-4">
    <div class="pointer-events-auto w-full max-w-2xl">
      <Card class="shadow-2xl">
        <CardHeader class="text-center space-y-3">
          <CardTitle class="text-3xl font-bold flex items-center justify-center gap-3">
            <Icon icon="radix-icons:bar-chart" class="h-10 w-10 text-primary" />
            {{ t('statistics.title') }}
          </CardTitle>
          <CardDescription class="text-lg">
            {{ t('statistics.description') }}
          </CardDescription>
        </CardHeader>
        <CardContent class="py-6">
          <!-- Loading State -->
          <div v-if="loading" class="space-y-4">
            <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
              <Skeleton v-for="i in 6" :key="i" class="h-24" />
            </div>
          </div>

          <!-- Error State -->
          <div v-else-if="error" class="text-center py-8 space-y-4">
            <Icon icon="radix-icons:cross-circled" class="h-16 w-16 mx-auto text-destructive" />
            <p class="text-destructive">
              {{ error }}
            </p>
          </div>

          <!-- No Data State -->
          <div v-else-if="statistics.gamesPlayed === 0" class="text-center py-8 space-y-4">
            <Icon icon="radix-icons:info-circled" class="h-16 w-16 mx-auto text-muted-foreground" />
            <p class="text-lg font-medium">
              {{ t('statistics.no_games_yet') }}
            </p>
            <p class="text-sm text-muted-foreground">
              {{ t('statistics.play_first_game') }}
            </p>
          </div>

          <!-- Statistics Display -->
          <div v-else class="space-y-6">
            <!-- Main Stats Grid -->
            <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
              <!-- Games Played -->
              <div class="bg-accent/50 rounded-lg p-4 text-center">
                <Icon icon="radix-icons:target" class="h-8 w-8 mx-auto mb-2 text-primary" />
                <div class="text-3xl font-bold">
                  {{ statistics.gamesPlayed }}
                </div>
                <div class="text-sm text-muted-foreground">
                  {{ t('statistics.games_played') }}
                </div>
              </div>

              <!-- Success Rate -->
              <div class="bg-accent/50 rounded-lg p-4 text-center">
                <Icon
                  icon="radix-icons:check-circled"
                  class="h-8 w-8 mx-auto mb-2 text-green-600 dark:text-green-400"
                />
                <div class="text-3xl font-bold">
                  {{ formatPercentage(statistics.successRate) }}%
                </div>
                <div class="text-sm text-muted-foreground">
                  {{ t('statistics.success_rate') }}
                </div>
              </div>

              <!-- Avg Questions -->
              <div class="bg-accent/50 rounded-lg p-4 text-center">
                <Icon
                  icon="radix-icons:question-mark-circled"
                  class="h-8 w-8 mx-auto mb-2 text-blue-600 dark:text-blue-400"
                />
                <div class="text-3xl font-bold">
                  {{ formatAverage(statistics.avgQuestionsPerGame) }}
                </div>
                <div class="text-sm text-muted-foreground">
                  {{ t('statistics.avg_questions') }}
                </div>
              </div>

              <!-- Games Won -->
              <div class="bg-accent/50 rounded-lg p-4 text-center">
                <Icon
                  icon="radix-icons:checkmark"
                  class="h-8 w-8 mx-auto mb-2 text-green-600 dark:text-green-400"
                />
                <div class="text-3xl font-bold">
                  {{ statistics.gamesWon }}
                </div>
                <div class="text-sm text-muted-foreground">
                  {{ t('statistics.games_won') }}
                </div>
              </div>

              <!-- Games Lost -->
              <div class="bg-accent/50 rounded-lg p-4 text-center">
                <Icon
                  icon="radix-icons:cross-2"
                  class="h-8 w-8 mx-auto mb-2 text-orange-600 dark:text-orange-400"
                />
                <div class="text-3xl font-bold">
                  {{ statistics.gamesLost }}
                </div>
                <div class="text-sm text-muted-foreground">
                  {{ t('statistics.games_lost') }}
                </div>
              </div>

              <!-- Total Questions -->
              <div class="bg-accent/50 rounded-lg p-4 text-center">
                <Icon
                  icon="radix-icons:chat-bubble"
                  class="h-8 w-8 mx-auto mb-2 text-purple-600 dark:text-purple-400"
                />
                <div class="text-3xl font-bold">
                  {{ statistics.totalQuestionsAsked }}
                </div>
                <div class="text-sm text-muted-foreground">
                  {{ t('statistics.total_questions') }}
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</template>

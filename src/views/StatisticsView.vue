<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
</script>

<template>
  <!-- Statistics placeholder - centered card over map -->
  <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
    <div class="pointer-events-auto">
      <Card class="w-full max-w-md mx-4 shadow-2xl">
        <CardHeader class="text-center space-y-3">
          <CardTitle class="text-3xl font-bold flex items-center justify-center gap-3">
            <Icon
              icon="radix-icons:bar-chart"
              class="h-10 w-10 text-primary"
            />
            Statistics
          </CardTitle>
          <CardDescription class="text-lg">
            Your game statistics and achievements
          </CardDescription>
        </CardHeader>
        <CardContent class="text-center py-8">
          <div class="space-y-4">
            <Icon
              icon="radix-icons:info-circled"
              class="h-16 w-16 mx-auto text-muted-foreground"
            />
            <p class="text-muted-foreground">
              Coming Soon
            </p>
            <p class="text-sm text-muted-foreground">
              Track your performance, view your game history, and see how you compare with other players.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</template>

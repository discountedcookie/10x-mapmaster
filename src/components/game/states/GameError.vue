<script setup lang="ts">
import { CardContent } from '@/components/ui/card'

interface Properties {
  error: string
}

defineProps<Properties>()
</script>

<template>
  <CardContent class="py-8">
    <p class="text-center text-destructive">{{ error }}</p>
    <p class="text-center text-muted-foreground text-sm mt-2">Redirecting to home...</p>
  </CardContent>
</template>

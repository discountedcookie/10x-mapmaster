<script setup lang="ts">
import { Card, CardContent } from '@/components/ui/card'

interface Properties {
  title: string
  message: string
}

defineProps<Properties>()
</script>

<template>
  <Card class="w-full md:max-w-md pointer-events-auto">
    <CardContent class="py-8">
      <p class="text-center text-2xl">{{ title }}</p>
      <p class="text-center text-muted-foreground mt-2">{{ message }}</p>
    </CardContent>
  </Card>
</template>

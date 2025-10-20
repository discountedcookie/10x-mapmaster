<script setup lang="ts">
import { useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

const router = useRouter()

const handleGetStarted = () => {
  router.push('/game')
}
</script>

<template>
  <Card class="w-full max-w-md">
    <CardHeader>
      <CardTitle class="text-3xl">
        10x-mapmaster
      </CardTitle>
      <CardDescription class="text-base">
        An intelligent geography guessing game that learns from every session
      </CardDescription>
    </CardHeader>
    <CardContent>
      <Button
        size="lg"
        class="w-full"
        @click="handleGetStarted"
      >
        Get Started
      </Button>
    </CardContent>
  </Card>
</template>

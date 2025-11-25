<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { useI18n } from 'vue-i18n'
import { useTheme } from '@/composables/useTheme'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'

const { setLight, setDark, setAuto } = useTheme()
const { t } = useI18n()
</script>

<template>
  <DropdownMenu>
    <DropdownMenuTrigger as-child>
      <Button variant="outline" size="icon">
        <Icon
          icon="radix-icons:moon"
          class="h-[1.2rem] w-[1.2rem] rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0"
        />
        <Icon
          icon="radix-icons:sun"
          class="absolute h-[1.2rem] w-[1.2rem] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100"
        />
        <span class="sr-only">{{ t('theme.toggle_theme') }}</span>
      </Button>
    </DropdownMenuTrigger>
    <DropdownMenuContent align="end">
      <DropdownMenuItem @click="setLight">
        <Icon icon="radix-icons:sun" class="mr-2 h-4 w-4" />
        {{ t('theme.light') }}
      </DropdownMenuItem>
      <DropdownMenuItem @click="setDark">
        <Icon icon="radix-icons:moon" class="mr-2 h-4 w-4" />
        {{ t('theme.dark') }}
      </DropdownMenuItem>
      <DropdownMenuItem @click="setAuto">
        <Icon icon="radix-icons:desktop" class="mr-2 h-4 w-4" />
        {{ t('theme.system') }}
      </DropdownMenuItem>
    </DropdownMenuContent>
  </DropdownMenu>
</template>

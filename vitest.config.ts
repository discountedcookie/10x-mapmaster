import { fileURLToPath } from 'node:url'
import { mergeConfig, defineConfig, configDefaults } from 'vitest/config'
import viteConfig from './vite.config'

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      environment: 'jsdom',
      exclude: [...configDefaults.exclude, 'e2e/**'],
      root: fileURLToPath(new URL('./', import.meta.url)),
      setupFiles: ['./src/__tests__/setup.ts'],
      coverage: {
        provider: 'v8',
        reporter: ['text', 'json', 'html', 'lcov'],
        exclude: [
          ...configDefaults.exclude,
          'e2e/**',
          'src/__tests__/**',
          '**/*.spec.ts',
          '**/*.test.ts',
          '**/types/**',
          '*.config.ts',
          '*.config.js',
          'src/main.ts',
          'src/i18n/locales/**',
        ],
      },
    },
  }),
)

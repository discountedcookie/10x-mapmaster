import eslintPluginVue from 'eslint-plugin-vue'
import eslintPluginTypescript from 'typescript-eslint'
import eslintConfigPrettier from 'eslint-config-prettier'
import vueParser from 'vue-eslint-parser'

export default [
  {
    ignores: ['dist/**', 'coverage/**', 'supabase/functions/**'],
  },
  ...eslintPluginVue.configs['flat/recommended'],
  ...eslintPluginTypescript.configs.recommended,
  {
    files: ['**/*.vue'],
    languageOptions: {
      parser: vueParser,
      parserOptions: {
        parser: eslintPluginTypescript.parser,
        ecmaVersion: 'latest',
        extraFileExtensions: ['.vue'],
      },
    },
  },
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      ecmaVersion: 'latest',
      parser: eslintPluginTypescript.parser,
    },
  },
  {
    rules: {
      'max-lines': ['warn', { max: 200, skipBlankLines: true, skipComments: true }],
    },
  },
  {
    files: [
      'src/types/database.ts',
      'src/composables/map/useMapCamera.ts',
      'src/views/LoginView.vue',
      'src/views/SignupView.vue',
      'src/views/PlaceView.vue',
    ],
    rules: {
      'max-lines': 'off',
    },
  },
  {
    files: ['src/__tests__/**/*.ts'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off', // Tests need flexible mocking
    },
  },
  {
    files: ['scripts/**/*.ts'],
    rules: {
      'max-lines': 'off', // Scripts can be longer
      '@typescript-eslint/no-explicit-any': 'off', // Scripts use dynamic data
    },
  },
  {
    files: ['src/components/ui/**/*.vue'],
    rules: {
      'vue/multi-word-component-names': 'off', // shadcn-vue uses single-word names
      'vue/require-default-prop': 'off', // shadcn-vue handles defaults internally
    },
  },
  eslintConfigPrettier,
]

import { defineConfig } from 'eslint/config'
import eslintPluginVue from 'eslint-plugin-vue'
import stylistic from '@stylistic/eslint-plugin'
import eslintPluginTypescript from 'typescript-eslint'
import eslintPluginUnicorn from 'eslint-plugin-unicorn'

export default defineConfig([
  {
    ignores: [
      'dist/**',
      'coverage/**',
    ],
  },
  eslintPluginUnicorn.configs.recommended,
  eslintPluginVue.configs['flat/recommended'],
  stylistic.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 'latest',
      parserOptions: {
        parser: eslintPluginTypescript.parser,
      },
    },
    rules: {
      'unicorn/filename-case': 'off',
      'unicorn/prevent-abbreviations': 'off',
      'vue/multi-word-component-names': 'off',
      'vue/require-default-prop': 'off',
    },
  },
])
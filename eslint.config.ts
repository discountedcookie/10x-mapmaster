import { defineConfig } from 'eslint/config'
import eslintPluginVue from 'eslint-plugin-vue'
import eslintPluginTypescript from 'typescript-eslint'
import eslintPluginUnicorn from 'eslint-plugin-unicorn'
import eslintConfigPrettier from 'eslint-config-prettier'

export default defineConfig([
  {
    ignores: ['dist/**', 'coverage/**'],
  },
  eslintPluginUnicorn.configs.recommended,
  eslintPluginVue.configs['flat/recommended'],
  ...eslintPluginTypescript.configs.recommended,
  {
    files: ['**/*.vue'],
    languageOptions: {
      parserOptions: {
        parser: eslintPluginTypescript.parser,
        ecmaVersion: 'latest',
      },
    },
  },
  {
    languageOptions: {
      ecmaVersion: 'latest',
      parserOptions: {
        parser: eslintPluginTypescript.parser,
      },
    },
    rules: {
      'max-lines': ['warn', { max: 200, skipBlankLines: true, skipComments: false }],
      'unicorn/filename-case': 'off',
    },
  },
  {
    files: ['e2e/**/*.ts'],
    languageOptions: {
      ecmaVersion: 'latest',
      parserOptions: {
        parser: eslintPluginTypescript.parser,
      },
    },
    rules: {
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': 'error',
    },
  },
  eslintConfigPrettier,
])

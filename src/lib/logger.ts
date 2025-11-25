import { createConsola } from 'consola'

export const logger = createConsola({
  level: import.meta.env.DEV ? 4 : 1,
  formatOptions: {
    date: true,
    colors: import.meta.env.DEV,
  },
})

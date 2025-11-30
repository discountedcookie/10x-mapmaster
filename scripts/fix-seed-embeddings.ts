#!/usr/bin/env tsx
import { readFileSync, writeFileSync } from 'node:fs'
import path from 'node:path'

const seedPath = path.join(process.cwd(), 'supabase/seeds/01_embedding_data.sql')
let content = readFileSync(seedPath, 'utf8')

// Find all ARRAY[...] patterns and truncate to first 384 values
content = content.replaceAll(/ARRAY\[([-\d.,\s]+)\]::vector\(384\)/g, (_match, values) => {
  const nums = values
    .split(',')
    .map((s: string) => s.trim())
    .slice(0, 384)
  if (nums.length < 384) {
    // Pad with zeros if needed
    while (nums.length < 384) {
      nums.push('0.0')
    }
  }
  return `ARRAY[${nums.join(', ')}]::vector(384)`
})

writeFileSync(seedPath, content)
console.log('Fixed embeddings to 384 dimensions')

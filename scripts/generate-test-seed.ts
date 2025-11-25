#!/usr/bin/env tsx
/* eslint-disable max-lines */

import { readFileSync, writeFileSync } from 'node:fs'
import path from 'node:path'
import { enrichPlaceByOsmId } from '../supabase/functions/_shared/enrichment.ts'
import type { TraitCandidate } from '../supabase/functions/_shared/traits.ts'
import type { TablesInsert } from '../src/types/database.ts'

type PlaceData = Partial<TablesInsert<'places'>> & {
  id: string
  name?: string
  osm_id?: string
  bbox?: string[]
  embedding_text?: string
  embedding_vector?: string
}

const placesData: PlaceData[] = JSON.parse(
  readFileSync(path.join(process.cwd(), 'scripts', 'seed-data', 'places.json'), 'utf8')
)

const RATE_LIMIT_MS = 2000
let lastRequestTime = 0

async function waitForRateLimit() {
  const now = Date.now()
  const timeSinceLastRequest = now - lastRequestTime
  if (timeSinceLastRequest < RATE_LIMIT_MS) {
    await new Promise((resolve) => {
      setTimeout(resolve, RATE_LIMIT_MS - timeSinceLastRequest)
    })
  }
  lastRequestTime = Date.now()
}

function escapeSqlString(value: string): string {
  // eslint-disable-next-line unicorn/prefer-string-replace-all
  return value.replace(/'/g, "''")
}

function formatJson(value: unknown): string {
  return JSON.stringify(value ?? {})
}

function formatJsonb(value: unknown): string {
  return `'${escapeSqlString(formatJson(value))}'::jsonb`
}

function formatTextArray(values: string[]): string {
  if (values.length === 0) {
    return `'{}'::text[]`
  }
  const items = values.map((value) => `'${escapeSqlString(value)}'`).join(', ')
  return `ARRAY[${items}]::text[]`
}

async function fetchByOsmId(osmId: string, maxRetries = 3) {
  let lastError: Error | undefined

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await waitForRateLimit()
      const result = await enrichPlaceByOsmId(osmId)
      if (result) {
        return result
      }
      console.warn(`No results found for OSM ID: ${osmId}`)
      return
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error))
      if (attempt < maxRetries) {
        const backoffMs = Math.min(1000 * 2 ** attempt, 10_000)
        console.log(`Retry ${attempt}/${maxRetries} for ${osmId} after ${backoffMs}ms...`)
        await new Promise((resolve) => {
          setTimeout(resolve, backoffMs)
        })
      } else {
        console.error(`Failed to fetch ${osmId} after ${maxRetries} attempts:`, lastError)
      }
    }
  }
}

async function generateEmbedding(text: string): Promise<number[]> {
  const response = await fetch('http://localhost:11434/api/embeddings', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: 'mxbai-embed-large', prompt: text }),
  })

  if (!response.ok) {
    throw new Error(`Ollama API error: ${response.status} ${response.statusText}`)
  }

  const data = await response.json()
  return data.embedding
}

function formatEmbedding(embedding: number[]): string {
  return `ARRAY[${embedding.map((value) => value.toFixed(6)).join(', ')}]::vector(1024)`
}

console.log('Fetching real Nominatim data and generating embeddings for seed data...')

const traitDefinitions = new Map<string, { clause: string; category: string }>()
const traitLinks: Array<{
  placeId: string
  traitId: string
  sourceMetadata: Record<string, unknown>
}> = []

for (let index = 0; index < placesData.length; index++) {
  const place = placesData[index]

  if (!place.osm_id) {
    console.warn(`[${index + 1}/${placesData.length}] Skipping place without OSM ID`)
    continue
  }

  console.log(`[${index + 1}/${placesData.length}] ${place.osm_id}`)

  const enrichment = await fetchByOsmId(place.osm_id)
  const normalized = enrichment?.place
  const traitCandidates: TraitCandidate[] = enrichment?.traits ?? []

  if (normalized) {
    place.name = normalized.english_name
    place.osm_id = `${normalized.osm_type}/${normalized.osm_id}`
    place.lat = normalized.lat
    place.lng = normalized.lng

    // Store bbox for geometry
    if (normalized.boundingbox && normalized.boundingbox.length === 4) {
      place.bbox = normalized.boundingbox
    }

    console.log(`  ✓ ${normalized.display_name}`)
  } else {
    console.log(`  ⚠ Using fallback data for ${place.name}`)
  }

  const traitIds = traitCandidates.map((trait) => trait.id)
  place.traits = traitIds

  if (traitCandidates.length > 0) {
    const traitText = traitCandidates.map((trait) => trait.clause).join(' ')
    const embedding = await generateEmbedding(traitText)
    place.embedding_text = traitText
    place.embedding_vector = formatEmbedding(embedding)
    console.log(`  🏷️  ${traitCandidates.length} traits extracted`)

    for (const trait of traitCandidates) {
      if (!traitDefinitions.has(trait.id)) {
        traitDefinitions.set(trait.id, {
          clause: trait.clause,
          category: trait.category,
        })
      }
      traitLinks.push({
        placeId: place.id,
        traitId: trait.id,
        sourceMetadata: { sourceKey: trait.sourceKey, value: trait.value },
      })
    }
  } else {
    console.log(`  ⚠️  No traits extracted`)
  }
}

let sql = `-- Generated embedding seed data
-- This file is auto-generated by scripts/generate-test-seed.ts
-- Do not edit manually - regenerate using the script instead

SET search_path = public, extensions;

`

if (traitDefinitions.size > 0) {
  sql += `-- Upsert canonical place traits\n`
  sql += `INSERT INTO place_traits (id, clause, category) VALUES\n`
  sql += [...traitDefinitions.entries()]
    .map(
      ([id, definition]) =>
        `  ('${escapeSqlString(id)}', '${escapeSqlString(definition.clause)}', '${escapeSqlString(definition.category)}')`
    )
    .join(',\n')
  sql += `\nON CONFLICT (id) DO UPDATE SET clause = EXCLUDED.clause, category = EXCLUDED.category;\n\n`
}

// Deduplicate embeddings - multiple places can share the same embedding
const uniqueEmbeddings = new Map<string, string>() // text -> embedding_vector
placesData
  .filter((place) => place.embedding_text)
  .forEach((place) => {
    const text = place.embedding_text!
    if (!uniqueEmbeddings.has(text)) {
      uniqueEmbeddings.set(text, place.embedding_vector!)
    }
  })

sql += `-- Insert unique embeddings (shared by multiple places)\n`
sql += `INSERT INTO embeddings (text, text_hash, embedding) VALUES\n`

const embeddingsToInsert = Array.from(uniqueEmbeddings.entries()).map(([text, embedding]) => {
  const escapedText = escapeSqlString(text)
  return `  ('${escapedText}', encode(digest('${escapedText}', 'sha256'), 'hex'), ${embedding})`
})

sql += embeddingsToInsert.join(',\n')
sql += `\nON CONFLICT (text_hash) DO NOTHING;\n\n`

sql += `-- Insert places with trait-based embeddings\n`
sql += `INSERT INTO places (
  id, name, osm_id, lat, lng, geom, traits, embedding_id
) VALUES\n`

sql += placesData
  .map((place) => {
    const traitsValue = formatTextArray(place.traits ?? [])
    const embeddingId = place.embedding_text
      ? `(SELECT id FROM embeddings WHERE text_hash = encode(digest('${escapeSqlString(place.embedding_text)}', 'sha256'), 'hex'))`
      : 'NULL'

    // Create polygon from bbox if available, otherwise NULL
    let geomValue = 'NULL'
    const bbox = place.bbox
    if (bbox && bbox.length === 4) {
      // bbox format: [min_lat, max_lat, min_lng, max_lng] (strings from Nominatim)
      const [minLat, maxLat, minLng, maxLng] = bbox
      geomValue = `ST_MakeEnvelope(${minLng}, ${minLat}, ${maxLng}, ${maxLat}, 4326)`
    }

    return `  ('${place.id}'::uuid, '${escapeSqlString(place.name ?? 'Unknown')}', '${escapeSqlString(place.osm_id ?? '')}', ${place.lat ?? 0}, ${place.lng ?? 0}, ${geomValue}, ${traitsValue}, ${embeddingId})`
  })
  .join(',\n')

sql += `;\n\n`

if (traitLinks.length > 0) {
  sql += `-- Link places to traits\n`
  sql += `INSERT INTO place_trait_links (place_id, trait_id, source_type, source_metadata) VALUES\n`
  sql += traitLinks
    .map(
      (link) =>
        `  ('${link.placeId}'::uuid, '${escapeSqlString(link.traitId)}', 'nominatim', ${formatJsonb(link.sourceMetadata)})`
    )
    .join(',\n')
  sql += `\nON CONFLICT (place_id, trait_id) DO NOTHING;\n\n`
}

// Questions are now generated on-the-fly from geographic_regions and place_traits
// No need to seed them

const outputPath = path.join(process.cwd(), 'supabase', 'seeds', '01_embedding_data.sql')
writeFileSync(outputPath, sql, 'utf8')
console.log(`Generated seed file: ${outputPath}`)
console.log('Seed data generation complete!')

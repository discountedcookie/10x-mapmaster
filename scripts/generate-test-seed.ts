#!/usr/bin/env tsx

import { readFileSync, writeFileSync, unlinkSync, existsSync } from 'node:fs'
import path from 'node:path'
import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = 'http://localhost:54321'
const SUPABASE_SERVICE_ROLE_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU'

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

type PlaceInput = {
  id: string
  osm_id: string
}

type TestDescription = {
  description: string
  expected_place: string | null
  test_file: string
}

const allPlacesData: PlaceInput[] = JSON.parse(
  readFileSync(path.join(process.cwd(), 'scripts', 'seed-data', 'places.json'), 'utf8')
)

// Limit places to avoid rate limits during development (set to 0 for all)
const PLACE_LIMIT = process.env.PLACE_LIMIT !== undefined ? Number(process.env.PLACE_LIMIT) : 1
const placesData = PLACE_LIMIT > 0 ? allPlacesData.slice(0, PLACE_LIMIT) : allPlacesData

const testDescriptions: TestDescription[] = JSON.parse(
  readFileSync(path.join(process.cwd(), 'scripts', 'seed-data', 'test-descriptions.json'), 'utf8')
)

const RATE_LIMIT_MS = 1100 // Nominatim requires 1 req/sec
let lastRequestTime = 0

async function waitForRateLimit() {
  const now = Date.now()
  const timeSinceLastRequest = now - lastRequestTime
  if (timeSinceLastRequest < RATE_LIMIT_MS) {
    await new Promise((resolve) => setTimeout(resolve, RATE_LIMIT_MS - timeSinceLastRequest))
  }
  lastRequestTime = Date.now()
}

function escapeSqlString(value: string): string {
  return value.split("'").join("''")
}

function formatEmbedding(embedding: number[] | string): string {
  // Handle case where embedding comes as string from Supabase (e.g., "[0.1,0.2,...]")
  if (typeof embedding === 'string') {
    // It's already in vector format, just wrap it
    return `'${embedding}'::vector(384)`
  }
  if (!Array.isArray(embedding)) {
    throw new TypeError(`Unexpected embedding type: ${typeof embedding}`)
  }
  return `ARRAY[${embedding.map((v) => v.toFixed(6)).join(', ')}]::vector(384)`
}

// Create temporary public wrappers for game_logic functions
async function createWrappers() {
  const { execSync } = await import('node:child_process')
  execSync(`psql "postgresql://postgres:postgres@localhost:54322/postgres" -c "
    CREATE OR REPLACE FUNCTION public.fetch_nominatim_place(p_osm_id TEXT) RETURNS JSONB 
    LANGUAGE sql SECURITY DEFINER SET search_path = public, game_logic AS \\$\\$ SELECT game_logic.fetch_nominatim_place(p_osm_id); \\$\\$;
    
    CREATE OR REPLACE FUNCTION public.extract_traits_from_nominatim(p_nominatim_data JSONB) RETURNS JSONB 
    LANGUAGE sql SECURITY DEFINER SET search_path = public, game_logic AS \\$\\$ SELECT game_logic.extract_traits_from_nominatim(p_nominatim_data); \\$\\$;
    
    CREATE OR REPLACE FUNCTION public.create_place_with_traits(p_osm_id TEXT, p_nominatim_data JSONB, p_traits JSONB, p_is_curated BOOLEAN DEFAULT TRUE) RETURNS UUID 
    LANGUAGE sql SECURITY DEFINER SET search_path = public, game_logic AS \\$\\$ SELECT game_logic.create_place_with_traits(p_osm_id, p_nominatim_data, p_traits, p_is_curated); \\$\\$;
    
    CREATE OR REPLACE FUNCTION public.get_embedding(p_text TEXT) RETURNS UUID 
    LANGUAGE sql SECURITY DEFINER SET search_path = public, game_logic AS \\$\\$ SELECT game_logic.get_embedding(p_text); \\$\\$;
    
    CREATE OR REPLACE FUNCTION public.update_place_traits(p_place_id UUID) RETURNS VOID 
    LANGUAGE sql SECURITY DEFINER SET search_path = public, game_logic AS \\$\\$ SELECT game_logic.update_place_traits(p_place_id); \\$\\$;
    
    NOTIFY pgrst, 'reload schema';
  "`)

  // Give PostgREST time to reload
  await new Promise((resolve) => setTimeout(resolve, 2000))
}

async function dropWrappers() {
  const { execSync } = await import('node:child_process')
  try {
    execSync(`psql "postgresql://postgres:postgres@localhost:54322/postgres" -c "
      DROP FUNCTION IF EXISTS public.fetch_nominatim_place(TEXT);
      DROP FUNCTION IF EXISTS public.extract_traits_from_nominatim(JSONB);
      DROP FUNCTION IF EXISTS public.create_place_with_traits(TEXT, JSONB, JSONB, BOOLEAN);
      DROP FUNCTION IF EXISTS public.get_embedding(TEXT);
      DROP FUNCTION IF EXISTS public.update_place_traits(UUID);
    "`)
  } catch {
    // Ignore errors
  }
}

async function callRpc(name: string, parameters: Record<string, unknown>, timeoutMs = 120000) {
  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs)

  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${name}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        apikey: SUPABASE_SERVICE_ROLE_KEY,
      },
      body: JSON.stringify(parameters),
      signal: controller.signal,
    })

    if (!response.ok) {
      const error = await response.text()
      throw new Error(`RPC ${name} failed: ${error}`)
    }

    return await response.json()
  } finally {
    clearTimeout(timeoutId)
  }
}

// Remove old seed file to ensure clean generation
const seedFilePath = path.join(process.cwd(), 'supabase', 'seeds', '01_embedding_data.sql')
if (existsSync(seedFilePath)) {
  unlinkSync(seedFilePath)
  console.log('Removed old seed file: 01_embedding_data.sql')
}

console.log('Generating seed data using database functions...')
console.log('')

// Create wrappers
console.log('Creating temporary public wrappers...')
await createWrappers()

const createdPlaceIds: string[] = []

try {
  for (let index = 0; index < placesData.length; index++) {
    const place = placesData[index]

    if (!place.osm_id) {
      console.warn(`[${index + 1}/${placesData.length}] Skipping place without OSM ID`)
      continue
    }

    console.log(`[${index + 1}/${placesData.length}] ${place.osm_id}`)
    await waitForRateLimit()

    let traitStart = 0
    try {
      // 1. Fetch from Nominatim
      const nominatimData = await callRpc('fetch_nominatim_place', { p_osm_id: place.osm_id })
      console.log(`  ✓ ${nominatimData.display_name}`)

      // 2. Extract traits
      traitStart = Date.now()
      const traits = await callRpc('extract_traits_from_nominatim', {
        p_nominatim_data: nominatimData,
      })
      console.log(
        `  🏷️  ${Array.isArray(traits) ? traits.length : 0} traits (${Date.now() - traitStart}ms)`
      )

      // 3. Create place with traits (this also generates embedding)
      const placeId = await callRpc('create_place_with_traits', {
        p_osm_id: place.osm_id,
        p_nominatim_data: nominatimData,
        p_traits: traits,
        p_is_curated: true,
      })
      createdPlaceIds.push(placeId)
      console.log(`  📍 Created place: ${placeId}`)

      // 4. Call LLM to generate rich traits
      const llmStart = Date.now()
      try {
        await callRpc('update_place_traits', { p_place_id: placeId })
        // Count updated traits
        const { data: updatedTraits } = await supabase
          .from('place_traits')
          .select('trait_id')
          .eq('place_id', placeId)
        console.log(`  🤖 LLM traits: ${updatedTraits?.length || 0} (${Date.now() - llmStart}ms)`)
      } catch (error) {
        console.error(`  ⚠️  LLM trait update failed (${Date.now() - llmStart}ms): ${error}`)
      }
    } catch (error) {
      console.error(`  ✗ Failed (${Date.now() - traitStart}ms): ${error}`)
    }
  }

  // Generate embeddings for test descriptions
  console.log('\nGenerating embeddings for test descriptions...')
  for (const testDesc of testDescriptions) {
    console.log(`  📝 "${testDesc.description}"`)
    try {
      await callRpc('get_embedding', { p_text: testDesc.description })
      console.log(`     ✓ Embedding created`)
    } catch (error) {
      console.error(`     ✗ Failed: ${error}`)
    }
  }

  // Dump tables to SQL
  console.log('\nDumping tables to SQL...')

  const { data: traits } = await supabase.from('traits').select('*')
  const { data: placeTraits } = await supabase.from('place_traits').select('*')
  const { data: embeddings } = await supabase.from('embeddings').select('*')

  // Fetch places with geometry as WKT (PostgREST returns geometry as binary)
  const { execSync } = await import('node:child_process')
  const placesJson =
    execSync(`psql "postgresql://postgres:postgres@localhost:54322/postgres" -t -A -c "
    SELECT json_agg(row_to_json(p)) FROM (
      SELECT id, name, osm_id, lat, lng, ST_AsText(geom) as geom, embedding_id, pending_review 
      FROM places
    ) p;
  "`)
      .toString()
      .trim()
  const places = placesJson && placesJson !== '' ? JSON.parse(placesJson) : []

  let sql = `-- Generated embedding seed data
-- Auto-generated by scripts/generate-test-seed.ts
-- Do not edit manually

SET search_path = public, extensions;

`

  // IMPORTANT: Embeddings must be inserted BEFORE traits (FK constraint)
  if (embeddings && embeddings.length > 0) {
    sql += `-- Embeddings (inserted first due to FK constraints)\n`
    sql += `INSERT INTO embeddings (id, source_text, embedding) VALUES\n`
    sql += embeddings
      .map(
        (e) =>
          `  ('${e.id}'::uuid, '${escapeSqlString(e.source_text)}', ${formatEmbedding(e.embedding)})`
      )
      .join(',\n')
    sql += `\nON CONFLICT (source_text) DO NOTHING;\n\n`
  }

  if (traits && traits.length > 0) {
    sql += `-- Traits\n`
    sql += `INSERT INTO traits (id, clause, embedding_id) VALUES\n`
    sql += traits
      .map((t) => {
        const embeddingId = t.embedding_id ? `'${t.embedding_id}'::uuid` : 'NULL'
        return `  ('${escapeSqlString(t.id)}', '${escapeSqlString(t.clause)}', ${embeddingId})`
      })
      .join(',\n')
    sql += `\nON CONFLICT (id) DO UPDATE SET clause = EXCLUDED.clause, embedding_id = EXCLUDED.embedding_id;\n\n`
  }

  if (places && places.length > 0) {
    sql += `-- Places\n`
    sql += `INSERT INTO places (id, name, osm_id, lat, lng, geom, embedding_id, pending_review) VALUES\n`
    sql += places
      .map(
        (p: {
          id: string
          name: string
          osm_id: string
          lat: number
          lng: number
          geom: string | null
          embedding_id: string | null
          pending_review: boolean
        }) => {
          // geom is now WKT from ST_AsText
          const geom = p.geom ? `ST_GeomFromText('${p.geom}', 4326)` : 'NULL'
          const embeddingId = p.embedding_id ? `'${p.embedding_id}'::uuid` : 'NULL'
          return `  ('${p.id}'::uuid, '${escapeSqlString(p.name)}', '${escapeSqlString(p.osm_id)}', ${p.lat}, ${p.lng}, ${geom}, ${embeddingId}, ${p.pending_review ?? false})`
        }
      )
      .join(',\n')
    sql += `\nON CONFLICT (id) DO NOTHING;\n\n`
  }

  if (placeTraits && placeTraits.length > 0) {
    sql += `-- Place-Trait links\n`
    sql += `INSERT INTO place_traits (place_id, trait_id) VALUES\n`
    sql += placeTraits
      .map((pt) => `  ('${pt.place_id}'::uuid, '${escapeSqlString(pt.trait_id)}')`)
      .join(',\n')
    sql += `\nON CONFLICT (place_id, trait_id) DO NOTHING;\n\n`
  }

  const outputPath = path.join(process.cwd(), 'supabase', 'seeds', '01_embedding_data.sql')
  writeFileSync(outputPath, sql, 'utf8')
  console.log(`\nGenerated: ${outputPath}`)
} finally {
  // Clean up wrappers
  console.log('\nRemoving temporary wrappers...')
  await dropWrappers()
}

console.log('Done!')

#!/usr/bin/env tsx
import { readFileSync } from 'node:fs'
import { execSync } from 'node:child_process'

const PSQL = 'psql "postgresql://postgres:postgres@localhost:54322/postgres"'
const allPlaces = JSON.parse(readFileSync('scripts/seed-data/places.json', 'utf8'))
const PLACE_LIMIT = process.env.PLACE_LIMIT ? Number(process.env.PLACE_LIMIT) : 0
const placesData = PLACE_LIMIT > 0 ? allPlaces.slice(0, PLACE_LIMIT) : allPlaces

function psql(query: string) {
  return execSync(`${PSQL} -t -A -c "${query.replace(/"/g, '\\"')}"`, {
    maxBuffer: 100 * 1024 * 1024,
  })
    .toString()
    .trim()
}

// DUMP_ONLY=1 skips creation, just dumps
if (process.env.DUMP_ONLY !== '1') {
  console.log(`Creating ${placesData.length} places...`)

  for (let i = 0; i < placesData.length; i++) {
    const { osm_id } = placesData[i]
    console.log(`[${i + 1}/${placesData.length}] ${osm_id}`)

    try {
      // Same as submit_place but without session/auth
      const placeId = psql(`
        WITH nominatim AS (SELECT game_logic.fetch_nominatim_place('${osm_id}') as data),
             traits AS (SELECT game_logic.extract_traits_from_nominatim((SELECT data FROM nominatim)) as data)
        SELECT game_logic.create_place_with_traits('${osm_id}', (SELECT data FROM nominatim), (SELECT data FROM traits), true)
      `)
      console.log(`  Created: ${placeId}`)

      psql(`SELECT game_logic.update_place_traits('${placeId}'::uuid)`)
      const count = psql(`SELECT COUNT(*) FROM place_traits WHERE place_id = '${placeId}'`)
      console.log(`  Traits: ${count}`)
    } catch (e: any) {
      console.error(`  Failed: ${e.message?.split('\n')[0]}`)
    }

    execSync('sleep 1.1') // Nominatim rate limit
  }
}

// Dump using pg_dump
console.log('\nDumping to SQL...')
execSync(
  `pg_dump "postgresql://postgres:postgres@localhost:54322/postgres" --data-only --inserts --no-owner --no-privileges --table=game_logic.embeddings --table=public.traits --table=public.places --table=public.place_traits | grep -v '^\\\\' | grep -v '^SELECT pg_catalog' > supabase/seeds/02_dev_data.sql`,
  { maxBuffer: 100 * 1024 * 1024 }
)

console.log(
  `Done! Embeddings: ${psql('SELECT COUNT(*) FROM game_logic.embeddings')}, Traits: ${psql('SELECT COUNT(*) FROM traits')}, Places: ${psql('SELECT COUNT(*) FROM places')}, PlaceTraits: ${psql('SELECT COUNT(*) FROM place_traits')}`
)

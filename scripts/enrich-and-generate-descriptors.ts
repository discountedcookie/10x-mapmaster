/**
 * Enriches place descriptors with semantic data and generates descriptor text for embeddings
 *
 * This script:
 * 1. Enriches existing JSONB descriptors with semantic information
 * 2. Generates natural language descriptor_text for embedding generation
 *
 * Run with: npx tsx scripts/enrich-and-generate-descriptors.ts
 */

import { createClient } from '@supabase/supabase-js'
import type { Database } from '../src/types/database'

const supabaseUrl = process.env.VITE_SUPABASE_URL || 'http://127.0.0.1:54321'
const supabaseServiceKey = process.env.VITE_SUPABASE_SERVICE_KEY!

if (!supabaseServiceKey) {
  console.error('Error: VITE_SUPABASE_SERVICE_KEY is required')
  process.exit(1)
}

const supabase = createClient<Database>(supabaseUrl, supabaseServiceKey)

// Continent mapping by country code
const continentMap: Record<string, string> = {
  // Europe
  fr: 'europe', gb: 'europe', it: 'europe', es: 'europe', de: 'europe',
  gr: 'europe', ch: 'europe', ru: 'europe', pl: 'europe', nl: 'europe',
  be: 'europe', pt: 'europe', se: 'europe', no: 'europe', dk: 'europe',
  fi: 'europe', at: 'europe', ie: 'europe', cz: 'europe', ro: 'europe',
  hu: 'europe', bg: 'europe', hr: 'europe', sk: 'europe', si: 'europe',
  // Asia
  cn: 'asia', jp: 'asia', in: 'asia', np: 'asia', th: 'asia',
  vn: 'asia', id: 'asia', pk: 'asia', bd: 'asia', mm: 'asia',
  ae: 'asia', sa: 'asia', tr: 'asia', il: 'asia', jo: 'asia',
  // North America
  us: 'north_america', ca: 'north_america', mx: 'north_america',
  gt: 'north_america', hn: 'north_america', ni: 'north_america',
  // South America
  br: 'south_america', ar: 'south_america', pe: 'south_america',
  co: 'south_america', ve: 'south_america', cl: 'south_america',
  // Africa
  eg: 'africa', za: 'africa', ke: 'africa', ng: 'africa',
  ma: 'africa', tz: 'africa', ug: 'africa', et: 'africa',
  // Oceania
  au: 'oceania', nz: 'oceania', fj: 'oceania', pg: 'oceania',
}

// Capital cities by city name (lowercase)
const capitalCities = new Set([
  'paris', 'london', 'rome', 'berlin', 'athens', 'moscow', 'madrid',
  'lisbon', 'amsterdam', 'brussels', 'vienna', 'prague', 'budapest',
  'warsaw', 'dublin', 'stockholm', 'copenhagen', 'helsinki', 'oslo',
  'washington', 'beijing', 'tokyo', 'new delhi', 'cairo', 'canberra',
  'brasilia', 'ottawa', 'mexico city', 'buenos aires', 'santiago',
  'lima', 'bogota', 'caracas', 'nairobi', 'pretoria', 'bangkok',
  'hanoi', 'jakarta', 'manila', 'seoul', 'tehran', 'baghdad',
  'riyadh', 'jerusalem', 'amman', 'damascus', 'beirut'
])

// Manual place-specific enrichment data
const placeEnrichment: Record<string, any> = {
  'Eiffel Tower': {
    era: 'modern',
    height_meters: 324,
    materials: ['iron', 'metal'],
    water_proximity: 'river'
  },
  'Big Ben': {
    era: 'modern',
    height_meters: 96,
    materials: ['stone', 'brick'],
    water_proximity: 'river'
  },
  'Tower Bridge': {
    era: 'modern',
    height_meters: 65,
    materials: ['stone', 'steel'],
    water_proximity: 'river'
  },
  'Colosseum': {
    era: 'ancient',
    height_meters: 48,
    materials: ['stone', 'concrete'],
    water_proximity: 'none'
  },
  'Sagrada Familia': {
    era: 'modern',
    height_meters: 172,
    materials: ['stone'],
    water_proximity: 'none'
  },
  'Brandenburg Gate': {
    era: 'modern',
    height_meters: 26,
    materials: ['stone'],
    water_proximity: 'none'
  },
  'Acropolis': {
    era: 'ancient',
    height_meters: 156,
    materials: ['stone', 'marble'],
    water_proximity: 'none'
  },
  'Mount Everest': {
    era: 'ancient',
    height_meters: 8849,
    materials: ['rock', 'snow'],
    water_proximity: 'none'
  },
  'Lake Geneva': {
    era: 'ancient',
    height_meters: 0,
    materials: ['water'],
    water_proximity: 'lake'
  },
  'Mount Fuji': {
    era: 'ancient',
    height_meters: 3776,
    materials: ['rock', 'snow'],
    water_proximity: 'none'
  },
  'Grand Canyon': {
    era: 'ancient',
    height_meters: 1857,
    materials: ['rock', 'stone'],
    water_proximity: 'river'
  },
  'Niagara Falls': {
    era: 'ancient',
    height_meters: 51,
    materials: ['water', 'rock'],
    water_proximity: 'river'
  },
  'Statue of Liberty': {
    era: 'modern',
    height_meters: 93,
    materials: ['copper', 'metal'],
    water_proximity: 'ocean'
  },
  'Sydney Opera House': {
    era: 'modern',
    height_meters: 65,
    materials: ['concrete', 'ceramic'],
    water_proximity: 'ocean'
  },
  'Taj Mahal': {
    era: 'medieval',
    height_meters: 73,
    materials: ['marble', 'stone'],
    water_proximity: 'river'
  },
  'Great Wall of China': {
    era: 'ancient',
    height_meters: 8,
    materials: ['stone', 'brick'],
    water_proximity: 'none'
  },
  'Machu Picchu': {
    era: 'ancient',
    height_meters: 2430,
    materials: ['stone'],
    water_proximity: 'none'
  },
  'Christ the Redeemer': {
    era: 'modern',
    height_meters: 38,
    materials: ['concrete', 'stone'],
    water_proximity: 'ocean'
  },
  'Burj Khalifa': {
    era: 'modern',
    height_meters: 828,
    materials: ['steel', 'glass', 'concrete'],
    water_proximity: 'none'
  },
  'Pyramids of Giza': {
    era: 'ancient',
    height_meters: 146,
    materials: ['stone', 'limestone'],
    water_proximity: 'none'
  }
}

function enrichDescriptors(place: any): any {
  const descriptors = place.descriptors as any
  const enrichment = placeEnrichment[place.name] || {}

  // Determine continent from country code
  const continent = continentMap[descriptors.country_code?.toLowerCase()] || 'unknown'

  // Check if in capital city
  const city = descriptors.address?.city?.toLowerCase()
  const is_capital_city = city ? capitalCities.has(city) : false

  return {
    ...descriptors,
    continent,
    is_capital_city,
    ...enrichment
  }
}

function generateDescriptorText(place: any, enrichedDescriptors: any): string {
  const parts: string[] = []

  // Type and classification
  if (enrichedDescriptors.type) {
    parts.push(`${enrichedDescriptors.type}`)
  }
  if (enrichedDescriptors.class) {
    parts.push(`${enrichedDescriptors.class}`)
  }

  // Location
  if (enrichedDescriptors.address?.city) {
    parts.push(`in ${enrichedDescriptors.address.city}`)
  }
  if (enrichedDescriptors.address?.country) {
    parts.push(`${enrichedDescriptors.address.country}`)
  }
  if (enrichedDescriptors.continent) {
    parts.push(`${enrichedDescriptors.continent}`)
  }

  // Capital city status
  if (enrichedDescriptors.is_capital_city) {
    parts.push('capital city')
  }

  // Era
  if (enrichedDescriptors.era) {
    parts.push(`${enrichedDescriptors.era} era`)
  }

  // Height
  if (enrichedDescriptors.height_meters && enrichedDescriptors.height_meters > 0) {
    if (enrichedDescriptors.height_meters > 500) {
      parts.push(`very tall structure over ${enrichedDescriptors.height_meters} meters`)
    } else if (enrichedDescriptors.height_meters > 200) {
      parts.push(`tall structure ${enrichedDescriptors.height_meters} meters`)
    } else if (enrichedDescriptors.height_meters > 50) {
      parts.push(`${enrichedDescriptors.height_meters} meters high`)
    }
  }

  // Materials
  if (enrichedDescriptors.materials && enrichedDescriptors.materials.length > 0) {
    parts.push(`made of ${enrichedDescriptors.materials.join(' and ')}`)
  }

  // Water proximity
  if (enrichedDescriptors.water_proximity && enrichedDescriptors.water_proximity !== 'none') {
    parts.push(`near ${enrichedDescriptors.water_proximity}`)
  }

  return parts.join('. ') + '.'
}

async function main() {
  console.log('🔍 Fetching places...')

  const { data: places, error } = await supabase
    .from('places')
    .select('*')
    .order('name')

  if (error) {
    console.error('Error fetching places:', error)
    process.exit(1)
  }

  if (!places || places.length === 0) {
    console.log('No places found.')
    return
  }

  console.log(`Found ${places.length} places`)
  console.log('\n🔧 Enriching descriptors and generating text...\n')

  for (const place of places) {
    console.log(`Processing: ${place.name}`)

    // Enrich descriptors
    const enrichedDescriptors = enrichDescriptors(place)

    // Generate descriptor text
    const descriptorText = generateDescriptorText(place, enrichedDescriptors)

    console.log(`  📝 Descriptor: ${descriptorText}`)

    // Update place
    const { error: updateError } = await supabase
      .from('places')
      .update({
        descriptors: enrichedDescriptors,
        descriptor_text: descriptorText
      })
      .eq('id', place.id)

    if (updateError) {
      console.error(`  ❌ Error updating ${place.name}:`, updateError)
    } else {
      console.log(`  ✅ Updated\n`)
    }
  }

  console.log('✨ Done! All places enriched and descriptor text generated.')
}

main().catch(console.error)

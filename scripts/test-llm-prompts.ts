#!/usr/bin/env bun
/**
 * LLM Prompt Testing Script
 *
 * Tests trait extraction and question generation with different configs.
 * Usage:
 *   bun run scripts/test-llm-prompts.ts traits <place_name>
 *   bun run scripts/test-llm-prompts.ts question <trait_clause>
 *   bun run scripts/test-llm-prompts.ts config <key> <value>
 *   bun run scripts/test-llm-prompts.ts list-places
 *   bun run scripts/test-llm-prompts.ts show-config
 */

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.SUPABASE_URL || 'http://127.0.0.1:54321'
const supabaseKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU'

const supabase = createClient(supabaseUrl, supabaseKey)

async function listPlaces() {
  const { data, error } = await supabase.rpc('test_list_places')

  if (error) {
    // Fallback to direct query
    const { data: places, error: queryError } = await supabase
      .from('places')
      .select('id, name, lat, lng')
      .order('name')
      .limit(30)

    if (queryError) {
      console.error('Error listing places:', queryError)
      return
    }

    // Get trait counts separately
    const { data: traitCounts } = await supabase.rpc('test_get_trait_counts')

    const countMap = new Map(
      traitCounts?.map((t: { place_id: string; count: number }) => [t.place_id, t.count]) || []
    )

    console.log('\n📍 Available Places:\n')
    console.log('Name'.padEnd(35) + 'Traits'.padStart(8) + '  ID')
    console.log('-'.repeat(80))

    for (const place of places || []) {
      const count = countMap.get(place.id) || 0
      console.log(`${place.name.padEnd(35)}${String(count).padStart(8)}  ${place.id}`)
    }
  } else {
    console.log('\n📍 Available Places:\n')
    console.log('Name'.padEnd(35) + 'Traits'.padStart(8) + '  ID')
    console.log('-'.repeat(80))
    for (const place of data || []) {
      console.log(`${place.name.padEnd(35)}${String(place.trait_count).padStart(8)}  ${place.id}`)
    }
  }
}

async function showConfig() {
  const { data, error } = await supabase.rpc('test_show_llm_config')

  if (error) {
    // Fallback: use psql
    console.log('\n⚙️  LLM Configuration (use psql for full view):\n')
    console.log(
      'Run: psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "SELECT key, value FROM game_logic.config WHERE key LIKE \'llm.%\' ORDER BY key;"'
    )
    return
  }

  console.log('\n⚙️  LLM Configuration:\n')

  for (const row of data || []) {
    const value = typeof row.value === 'string' ? row.value : JSON.stringify(row.value)
    const displayValue = value.length > 80 ? value.substring(0, 77) + '...' : value
    console.log(`${row.key}:`)
    console.log(`  ${displayValue}\n`)
  }
}

async function updateConfig(key: string, value: string) {
  // Parse value as JSON if possible
  let jsonValue: unknown
  try {
    jsonValue = JSON.parse(value)
  } catch {
    jsonValue = value
  }

  const { error } = await supabase
    .schema('game_logic')
    .from('config')
    .update({ value: jsonValue })
    .eq('key', key)

  if (error) {
    console.error('Error updating config:', error)
    return
  }

  console.log(`✅ Updated ${key}`)
}

async function testTraitExtraction(placeName: string) {
  console.log(`\n🔍 Testing trait extraction for: ${placeName}\n`)

  // Find place
  const { data: places, error: findError } = await supabase
    .from('places')
    .select('id, name')
    .ilike('name', `%${placeName}%`)
    .limit(1)

  if (findError || !places?.length) {
    console.error('Place not found:', placeName)
    return
  }

  const place = places[0]
  console.log(`Found place: ${place.name} (${place.id})\n`)

  // Get current traits
  const { data: currentTraits } = await supabase
    .from('place_traits')
    .select('traits(clause)')
    .eq('place_id', place.id)

  console.log('📋 Current traits:')
  for (const t of currentTraits || []) {
    const traits = t.traits as unknown as { clause: string } | null
    if (traits) console.log(`  - ${traits.clause}`)
  }
  console.log()

  // Call update_place_traits
  console.log('🤖 Calling LLM for trait extraction...\n')
  console.log(
    '(Check docker logs for detailed output: docker logs supabase_edge_runtime --tail 50)\n'
  )

  const { error: rpcError } = await supabase.rpc('update_place_traits', {
    p_place_id: place.id,
  })

  if (rpcError) {
    console.error('Error:', rpcError)
    return
  }

  // Get new traits
  const { data: newTraits } = await supabase
    .from('place_traits')
    .select('traits(clause)')
    .eq('place_id', place.id)

  console.log('✨ New traits:')
  for (const t of newTraits || []) {
    const traits = t.traits as unknown as { clause: string } | null
    if (traits) console.log(`  - ${traits.clause}`)
  }
}

async function testQuestionGeneration(traitClause: string, description?: string) {
  console.log(`\n🔍 Testing question generation for trait: "${traitClause}"\n`)

  // Find or create trait
  const { data: traits, error: findError } = await supabase
    .from('traits')
    .select('id, clause')
    .ilike('clause', `%${traitClause}%`)
    .limit(1)

  if (findError || !traits?.length) {
    console.error('Trait not found. Available traits with this text:')
    const { data: similar } = await supabase
      .from('traits')
      .select('clause')
      .ilike('clause', `%${traitClause.split(' ')[0]}%`)
      .limit(10)

    for (const t of similar || []) {
      console.log(`  - ${t.clause}`)
    }
    return
  }

  const trait = traits[0]
  console.log(`Found trait: ${trait.clause}\n`)

  // Test turn 1 (with description)
  const desc = description || 'A famous landmark'
  console.log(`📝 Testing Turn 1 (with description: "${desc}"):\n`)

  const { data: q1, error: e1 } = await supabase.rpc('generate_question_text', {
    p_trait_id: trait.id,
    p_region_id: null,
    p_language_code: 'en',
    p_user_description: desc,
    p_turn_number: 1,
  })

  if (e1) {
    console.error('Turn 1 error:', e1)
  } else {
    console.log(`  Question: ${q1}\n`)
  }

  // Test turn 2+ (without description context)
  console.log('📝 Testing Turn 2+ (using "it"):')

  const { data: q2, error: e2 } = await supabase.rpc('generate_question_text', {
    p_trait_id: trait.id,
    p_region_id: null,
    p_language_code: 'en',
    p_user_description: desc,
    p_turn_number: 2,
  })

  if (e2) {
    console.error('Turn 2 error:', e2)
  } else {
    console.log(`  Question: ${q2}\n`)
  }
}

async function testRegionQuestion(regionName: string, description?: string) {
  console.log(`\n🔍 Testing region question for: "${regionName}"\n`)

  // Find region
  const { data: regions, error: findError } = await supabase
    .schema('game_logic')
    .from('geographic_regions')
    .select('id, name, level')
    .ilike('name', `%${regionName}%`)
    .limit(1)

  if (findError || !regions?.length) {
    console.error('Region not found')
    return
  }

  const region = regions[0]
  console.log(`Found region: ${region.name} (${region.level})\n`)

  const desc = description || 'A famous landmark'

  // Test turn 1
  console.log(`📝 Testing Turn 1 (with description: "${desc}"):\n`)

  const { data: q1, error: e1 } = await supabase.rpc('generate_question_text', {
    p_trait_id: null,
    p_region_id: region.id,
    p_language_code: 'en',
    p_user_description: desc,
    p_turn_number: 1,
  })

  if (e1) {
    console.error('Turn 1 error:', e1)
  } else {
    console.log(`  Question: ${q1}\n`)
  }

  // Test turn 2
  console.log('📝 Testing Turn 2+ (using "it"):')

  const { data: q2, error: e2 } = await supabase.rpc('generate_question_text', {
    p_trait_id: null,
    p_region_id: region.id,
    p_language_code: 'en',
    p_user_description: desc,
    p_turn_number: 2,
  })

  if (e2) {
    console.error('Turn 2 error:', e2)
  } else {
    console.log(`  Question: ${q2}\n`)
  }
}

// Main
const [command, ...args] = process.argv.slice(2)

switch (command) {
  case 'list-places':
    await listPlaces()
    break

  case 'show-config':
    await showConfig()
    break

  case 'config':
    if (args.length < 2) {
      console.log('Usage: config <key> <value>')
      break
    }
    await updateConfig(args[0], args.slice(1).join(' '))
    break

  case 'traits':
    if (!args[0]) {
      console.log('Usage: traits <place_name>')
      break
    }
    await testTraitExtraction(args[0])
    break

  case 'question':
    if (!args[0]) {
      console.log('Usage: question <trait_clause> [description]')
      break
    }
    await testQuestionGeneration(args[0], args[1])
    break

  case 'region':
    if (!args[0]) {
      console.log('Usage: region <region_name> [description]')
      break
    }
    await testRegionQuestion(args[0], args[1])
    break

  default:
    console.log(`
LLM Prompt Testing Script

Commands:
  list-places              List available places with trait counts
  show-config              Show current LLM configuration
  config <key> <value>     Update a config value
  traits <place_name>      Test trait extraction for a place
  question <trait_clause>  Test question generation for a trait
  region <region_name>     Test region question generation

Examples:
  bun run scripts/test-llm-prompts.ts list-places
  bun run scripts/test-llm-prompts.ts traits "Centennial Hall"
  bun run scripts/test-llm-prompts.ts question "324 meters tall"
  bun run scripts/test-llm-prompts.ts region "Poland" "A royal castle in Warsaw"
  bun run scripts/test-llm-prompts.ts config llm.question.model '"mistralai/mistral-7b-instruct:free"'
`)
}

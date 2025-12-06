#!/usr/bin/env bun
/**
 * LLM Testing Script - TypeScript version
 *
 * Tests LLM functionality including:
 * - Trait extraction for places
 * - Question generation for traits
 * - Region-based questions
 * - LLM configuration management
 *
 * Usage:
 *   bun run scripts/test-llm.ts traits "Eiffel Tower"
 *   bun run scripts/test-llm.ts question "trait clause" "user description"
 *   bun run scripts/test-llm.ts region "Poland" "A royal castle"
 *   bun run scripts/test-llm.ts config
 *   bun run scripts/test-llm.ts set-config "llm.question.model" '"new-model"'
 */

import postgres from 'postgres'

// Connection string to local Supabase database
const connectionString = process.env.DATABASE_URL || 'postgresql://postgres:postgres@127.0.0.1:54322/postgres'
const sql = postgres(connectionString)

function log(emoji: string, message: string) {
  console.log(`${emoji} ${message}`)
}

function logEmpty() {
  console.log('')
}

// Format table output
function formatTable(headers: string[], rows: any[]) {
  if (rows.length === 0) {
    console.log('(no results)')
    return
  }

  const columnWidths = headers.map((h) => h.length)

  rows.forEach((row) => {
    headers.forEach((header, i) => {
      const value = String(row[header] ?? '')
      columnWidths[i] = Math.max(columnWidths[i], value.length)
    })
  })

  // Print header
  const headerRow = headers
    .map((h, i) => h.padEnd(columnWidths[i]))
    .join(' | ')
  console.log(headerRow)
  console.log('-'.repeat(headerRow.length))

  // Print rows
  rows.forEach((row) => {
    const values = headers
      .map((header, i) => {
        const value = String(row[header] ?? '')
        return value.padEnd(columnWidths[i])
      })
      .join(' | ')
    console.log(values)
  })
}

// Command: traits
async function cmdTraits(placeName: string) {
  log('🔍', `Testing trait extraction for: ${placeName}`)
  logEmpty()

  try {
    // Find place and show current traits
    const placeResults = await sql`
      SELECT p.id, p.name, array_agg(t.clause) FILTER (WHERE t.clause IS NOT NULL) as current_traits
      FROM places p
      LEFT JOIN place_traits pt ON pt.place_id = p.id
      LEFT JOIN traits t ON t.id = pt.trait_id
      WHERE p.name ILIKE ${'%' + placeName + '%'}
      GROUP BY p.id, p.name
      LIMIT 1
    `

    if (placeResults.length === 0) {
      log('❌', `Place not found: ${placeName}`)
      process.exit(1)
    }

    const place = placeResults[0]
    console.log(`Place: ${place.name}`)
    console.log(`ID: ${place.id}`)
    console.log(`Current traits: ${place.current_traits?.join(', ') || '(none)'}`)
    logEmpty()

    log('🤖', 'Running trait extraction (check NOTICE output above)...')
    logEmpty()

    // Run extraction
    await sql`SELECT game_logic.update_place_traits(${place.id}::uuid)`

    logEmpty()
    log('✨', 'New traits:')

    const traits = await sql`
      SELECT t.clause
      FROM place_traits pt
      JOIN traits t ON t.id = pt.trait_id
      WHERE pt.place_id = ${place.id}
      ORDER BY t.clause
    `

    if (traits.length === 0) {
      console.log('(no traits)')
    } else {
      traits.forEach((t: any) => {
        console.log(`  - ${t.clause}`)
      })
    }
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : error)
    process.exit(1)
  }
}

// Command: question
async function cmdQuestion(traitClause: string, description: string = 'A famous landmark') {
  log('🔍', `Testing question generation for trait: "${traitClause}"`)
  log('  ', `Description: "${description}"`)
  logEmpty()

  try {
    // Find trait
    const traitResults = await sql`
      SELECT id FROM traits
      WHERE clause ILIKE ${'%' + traitClause + '%'}
      LIMIT 1
    `

    if (traitResults.length === 0) {
      log('❌', `Trait not found. Available traits matching '${traitClause}':`)
      const firstWord = traitClause.split(' ')[0]
      const suggestedTraits = await sql`
        SELECT clause FROM traits
        WHERE clause ILIKE ${'%' + firstWord + '%'}
        LIMIT 10
      `
      suggestedTraits.forEach((t: any) => {
        console.log(`  - ${t.clause}`)
      })
      process.exit(1)
    }

    const trait = traitResults[0]
    log('✓', `Found trait ID: ${trait.id}`)
    logEmpty()

    // Turn 1 question
    log('📝', 'Turn 1 question (extracts noun from description):')
    const q1 = await sql`
      SELECT game_logic.generate_question_text(${trait.id}::uuid, NULL, 'en', ${description}, 1)
    `
    console.log(q1[0])

    logEmpty()

    // Turn 2+ question
    log('📝', 'Turn 2+ question (uses "it"):')
    const q2 = await sql`
      SELECT game_logic.generate_question_text(${trait.id}::uuid, NULL, 'en', ${description}, 2)
    `
    console.log(q2[0])
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : error)
    process.exit(1)
  }
}

// Command: region
async function cmdRegion(regionName: string, description: string = 'A famous landmark') {
  log('🔍', `Testing region question for: "${regionName}"`)
  log('  ', `Description: "${description}"`)
  logEmpty()

  try {
    // Find region
    const regionResults = await sql`
      SELECT id FROM game_logic.geographic_regions
      WHERE name ILIKE ${'%' + regionName + '%'}
      LIMIT 1
    `

    if (regionResults.length === 0) {
      log('❌', `Region not found: ${regionName}`)
      process.exit(1)
    }

    const region = regionResults[0]
    log('✓', `Found region ID: ${region.id}`)
    logEmpty()

    // Turn 1 question
    log('📝', 'Turn 1 question (extracts noun from description):')
    const q1 = await sql`
      SELECT game_logic.generate_question_text(NULL, ${region.id}::uuid, 'en', ${description}, 1)
    `
    console.log(q1[0])

    logEmpty()

    // Turn 2+ question
    log('📝', 'Turn 2+ question (uses "it"):')
    const q2 = await sql`
      SELECT game_logic.generate_question_text(NULL, ${region.id}::uuid, 'en', ${description}, 2)
    `
    console.log(q2[0])
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : error)
    process.exit(1)
  }
}

// Command: config
async function cmdConfig() {
  log('⚙️ ', 'LLM Configuration:')
  logEmpty()

  try {
    const config = await sql`
      SELECT key,
        CASE 
          WHEN length(value::text) > 100 THEN left(value::text, 97) || '...'
          ELSE value::text
        END as value
      FROM game_logic.config 
      WHERE key LIKE 'llm.%' 
      ORDER BY key
    `

    if (config.length === 0) {
      console.log('(no configuration found)')
    } else {
      formatTable(['key', 'value'], config)
    }
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : error)
    process.exit(1)
  }
}

// Command: set-config
async function cmdSetConfig(key: string, value: string) {
  log('⚙️ ', `Setting ${key} = ${value}`)

  try {
    // Parse the value as JSON to ensure it's valid
    const jsonValue = JSON.parse(value)

    await sql`
      UPDATE game_logic.config 
      SET value = ${jsonValue}::jsonb 
      WHERE key = ${key}
    `

    log('✅', 'Done')
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : error)
    process.exit(1)
  }
}

// Command: places
async function cmdPlaces() {
  log('📍', 'Available places with trait counts:')
  logEmpty()

  try {
    const places = await sql`
      SELECT p.name, COUNT(pt.trait_id) as traits
      FROM places p
      LEFT JOIN place_traits pt ON pt.place_id = p.id
      GROUP BY p.id, p.name
      ORDER BY p.name
    `

    if (places.length === 0) {
      console.log('(no places found)')
    } else {
      formatTable(['name', 'traits'], places)
    }
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : error)
    process.exit(1)
  }
}

// Show help
function showHelp() {
  console.log('LLM Testing Script')
  logEmpty()
  console.log('Commands:')
  console.log('  bun run scripts/test-llm.ts places                          List places with trait counts')
  console.log('  bun run scripts/test-llm.ts config                          Show LLM configuration')
  console.log('  bun run scripts/test-llm.ts set-config <key> <json-value>   Update config')
  console.log('  bun run scripts/test-llm.ts traits <place_name>             Test trait extraction')
  console.log('  bun run scripts/test-llm.ts question <trait> [description]  Test question generation')
  console.log('  bun run scripts/test-llm.ts region <region> [description]   Test region question')
  logEmpty()
  console.log('Examples:')
  console.log(`  bun run scripts/test-llm.ts traits 'Centennial Hall'`)
  console.log(`  bun run scripts/test-llm.ts question '330 meters' 'A famous iron tower'`)
  console.log(`  bun run scripts/test-llm.ts region 'Poland' 'A royal castle in Warsaw'`)
  console.log(
    `  bun run scripts/test-llm.ts set-config llm.question.model '"mistralai/mistral-7b-instruct:free"'`
  )
}

// Main
async function main() {
  const [command, ...args] = process.argv.slice(2)

  try {
    switch (command) {
      case 'traits':
        if (!args[0]) {
          console.error('Error: place name required')
          process.exit(1)
        }
        await cmdTraits(args[0])
        break

      case 'question':
        if (!args[0]) {
          console.error('Error: trait clause required')
          process.exit(1)
        }
        await cmdQuestion(args[0], args[1])
        break

      case 'region':
        if (!args[0]) {
          console.error('Error: region name required')
          process.exit(1)
        }
        await cmdRegion(args[0], args[1])
        break

      case 'config':
        await cmdConfig()
        break

      case 'set-config':
        if (!args[0] || !args[1]) {
          console.error('Error: key and value required')
          process.exit(1)
        }
        await cmdSetConfig(args[0], args[1])
        break

      case 'places':
        await cmdPlaces()
        break

      case '--help':
      case '-h':
      case 'help':
      case undefined:
        showHelp()
        break

      default:
        console.error(`Unknown command: ${command}`)
        showHelp()
        process.exit(1)
    }
  } catch (error) {
    console.error('Fatal error:', error instanceof Error ? error.message : error)
    process.exit(1)
  } finally {
    await sql.end()
  }
}

main()

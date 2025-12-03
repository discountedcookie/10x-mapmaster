#!/usr/bin/env bun
/**
 * Build Migration Script
 *
 * Generates Supabase migration files with support for dev and prod modes.
 *
 * DEV MODE (default):
 *   - Deletes all existing migrations
 *   - Creates single clean migration from schema + functions
 *   - Useful for development and testing
 *
 * PROD MODE:
 *   - Keeps existing migrations
 *   - Adds new incremental migration with timestamp
 *   - Suitable for production deployments
 *
 * Usage:
 *   # Dev mode (default)
 *   bun run scripts/build-migration.ts
 *   bun run scripts/build-migration.ts --dev
 *
 *   # Prod mode
 *   bun run scripts/build-migration.ts --prod "description"
 *   BUILD_MODE=prod bun run scripts/build-migration.ts "description"
 */

import { readFileSync, writeFileSync, readdirSync, statSync, rmSync, mkdirSync } from 'node:fs'
import { join, relative } from 'node:path'

// Configuration
const SCHEMA_DIR = 'supabase/db/schema'
const PUBLIC_TABLES_DIR = 'supabase/db/public/tables'
const PUBLIC_VIEWS_DIR = 'supabase/db/public/views'
const PUBLIC_FUNCTIONS_DIR = 'supabase/db/public/functions'
const GAME_LOGIC_TABLES_DIR = 'supabase/db/game_logic/tables'
const GAME_LOGIC_VIEWS_DIR = 'supabase/db/game_logic/views'
const GAME_LOGIC_FUNCTIONS_DIR = 'supabase/db/game_logic/functions'
const GAME_LOGIC_DATA_DIR = 'supabase/db/game_logic/data'
const MIGRATIONS_DIR = 'supabase/migrations'
const DEFAULT_DESCRIPTION = 'update_functions'

// Mode detection
type BuildMode = 'dev' | 'prod'

function detectMode(): BuildMode {
  const environmentMode = process.env.BUILD_MODE?.toLowerCase()
  if (environmentMode === 'prod' || environmentMode === 'production') return 'prod'
  if (environmentMode === 'dev' || environmentMode === 'development') return 'dev'

  const arguments_ = new Set(process.argv.slice(2))
  if (arguments_.has('--prod')) return 'prod'
  if (arguments_.has('--dev')) return 'dev'

  return 'dev'
}

function getTimestamp(): string {
  const now = new Date()
  return `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}`
}

function findSqlFiles(dir: string): string[] {
  const files: string[] = []
  function traverse(currentDir: string) {
    try {
      for (const entry of readdirSync(currentDir)) {
        const fullPath = join(currentDir, entry)
        const stat = statSync(fullPath)
        if (stat.isDirectory()) traverse(fullPath)
        else if (entry.endsWith('.sql')) files.push(fullPath)
      }
    } catch {
      /* directory might not exist */
    }
  }
  traverse(dir)
  return files.sort()
}

function findSchemaFiles(): string[] {
  try {
    return readdirSync(SCHEMA_DIR)
      .filter((e) => e.endsWith('.sql') && e.match(/^(\d+)/)?.[1] === '01')
      .map((e) => join(SCHEMA_DIR, e))
      .sort()
  } catch {
    return []
  }
}

function findTableFiles(): string[] {
  const files: string[] = []
  for (const dir of [PUBLIC_TABLES_DIR, GAME_LOGIC_TABLES_DIR]) {
    try {
      for (const e of readdirSync(dir)) {
        if (e.endsWith('.sql')) files.push(join(dir, e))
      }
    } catch {
      /* directory might not exist */
    }
  }
  // Sort with dependencies first (order matters for FK constraints)
  // Order: embeddings -> geographic_regions -> traits -> places -> game_sessions -> game_answers -> zz_* (deferred FKs)
  return files.sort((a, b) => {
    // Helper to get priority (lower = earlier)
    const getPriority = (path: string): number => {
      // zz_ prefixed files load last (deferred FK constraints)
      if (path.includes('/zz_')) return 100
      if (path.includes('embeddings')) return 1
      if (path.includes('geographic_regions')) return 2
      if (path.includes('traits.sql')) return 3
      if (path.includes('places.sql')) return 4
      if (path.includes('game_sessions')) return 5
      if (path.includes('game_answers')) return 6
      return 50 // default priority
    }
    const priorityA = getPriority(a)
    const priorityB = getPriority(b)
    if (priorityA !== priorityB) return priorityA - priorityB
    return a.localeCompare(b)
  })
}

function findViewFiles(): string[] {
  const files: string[] = []
  for (const dir of [PUBLIC_VIEWS_DIR, GAME_LOGIC_VIEWS_DIR]) {
    try {
      for (const e of readdirSync(dir)) {
        if (e.endsWith('.sql')) files.push(join(dir, e))
      }
    } catch {
      /* directory might not exist */
    }
  }
  return files.sort()
}

function findFunctionFiles(): string[] {
  const files: string[] = []
  // Public functions first (RPC entry points)
  files.push(...findSqlFiles(PUBLIC_FUNCTIONS_DIR))
  // Then game_logic functions
  files.push(...findSqlFiles(GAME_LOGIC_FUNCTIONS_DIR))
  return files
}

function findTriggerFiles(): string[] {
  try {
    return readdirSync(SCHEMA_DIR)
      .filter((e) => e.endsWith('.sql') && e.includes('trigger'))
      .map((e) => join(SCHEMA_DIR, e))
      .sort()
  } catch {
    return []
  }
}

function findDataFiles(): string[] {
  try {
    return readdirSync(GAME_LOGIC_DATA_DIR)
      .filter((e) => e.endsWith('.sql'))
      .map((e) => join(GAME_LOGIC_DATA_DIR, e))
      .sort()
  } catch {
    return []
  }
}

function readFile(filePath: string): string {
  try {
    return readFileSync(filePath, 'utf-8')
  } catch (error) {
    console.error(`Error reading file ${filePath}:`, error)
    throw error
  }
}

function generateDevelopmentMigrationContent(
  schemaFiles: string[],
  tableFiles: string[],
  functionFiles: string[],
  triggerFiles: string[],
  viewFiles: string[],
  dataFiles: string[]
): string {
  const timestamp = new Date().toISOString()
  let content = `-- Migration: Initial Schema and Functions\n`
  content += `-- Generated: ${timestamp}\n`
  content += `-- Mode: DEV (clean rebuild)\n`
  content += `-- Schema: ${schemaFiles.length}, Tables: ${tableFiles.length}, Functions: ${functionFiles.length}, Triggers: ${triggerFiles.length}, Views: ${viewFiles.length}, Data: ${dataFiles.length}\n\n`

  // Extensions
  if (schemaFiles.length > 0) {
    content += `-- ${'='.repeat(76)}\n-- EXTENSIONS AND TYPES\n-- ${'='.repeat(76)}\n\n`
    for (const f of schemaFiles) {
      content += `-- ${'-'.repeat(74)}\n-- ${relative('supabase/db', f)}\n-- ${'-'.repeat(74)}\n\n`
      content += readFile(f).trim() + '\n\n'
    }
  }

  // Tables
  if (tableFiles.length > 0) {
    content += `-- ${'='.repeat(76)}\n-- TABLE DEFINITIONS\n-- ${'='.repeat(76)}\n\n`
    for (const f of tableFiles) {
      content += `-- ${'-'.repeat(74)}\n-- ${relative('supabase/db', f)}\n-- ${'-'.repeat(74)}\n\n`
      content += readFile(f).trim() + '\n\n'
    }
  }

  // Functions
  if (functionFiles.length > 0) {
    content += `-- ${'='.repeat(76)}\n-- FUNCTION DEFINITIONS\n-- ${'='.repeat(76)}\n\n`
    for (const f of functionFiles) {
      content += `-- ${'-'.repeat(74)}\n-- ${relative('supabase/db', f)}\n-- ${'-'.repeat(74)}\n\n`
      content += readFile(f).trim() + '\n\n'
    }
  }

  // Triggers (after functions)
  if (triggerFiles.length > 0) {
    content += `-- ${'='.repeat(76)}\n-- TRIGGER DEFINITIONS\n-- ${'='.repeat(76)}\n\n`
    for (const f of triggerFiles) {
      content += `-- ${'-'.repeat(74)}\n-- ${relative('supabase/db', f)}\n-- ${'-'.repeat(74)}\n\n`
      content += readFile(f).trim() + '\n\n'
    }
  }

  // Views
  if (viewFiles.length > 0) {
    content += `-- ${'='.repeat(76)}\n-- VIEW DEFINITIONS\n-- ${'='.repeat(76)}\n\n`
    for (const f of viewFiles) {
      content += `-- ${'-'.repeat(74)}\n-- ${relative('supabase/db', f)}\n-- ${'-'.repeat(74)}\n\n`
      content += readFile(f).trim() + '\n\n'
    }
  }

  // Data (config, geographic regions, etc.)
  if (dataFiles.length > 0) {
    content += `-- ${'='.repeat(76)}\n-- DATA (CONFIG, GEOGRAPHIC REGIONS)\n-- ${'='.repeat(76)}\n\n`
    for (const f of dataFiles) {
      content += `-- ${'-'.repeat(74)}\n-- ${relative('supabase/db', f)}\n-- ${'-'.repeat(74)}\n\n`
      content += readFile(f).trim() + '\n\n'
    }
  }

  return content
}

function generateProductionMigrationContent(functionFiles: string[], description: string): string {
  const timestamp = new Date().toISOString()
  let content = `-- Migration: ${description}\n`
  content += `-- Generated: ${timestamp}\n`
  content += `-- Mode: PROD (incremental)\n`
  content += `-- Functions: ${functionFiles.length}\n\n`

  for (const f of functionFiles) {
    content += `-- ${'='.repeat(76)}\n-- ${relative('supabase/db', f)}\n-- ${'='.repeat(76)}\n\n`
    content += readFile(f).trim() + '\n\n'
  }

  return content
}

function clearMigrations(): void {
  rmSync(MIGRATIONS_DIR, { recursive: true, force: true })
  mkdirSync(MIGRATIONS_DIR, { recursive: true })
}

function extractDescription(arguments_: string[]): string {
  return arguments_.find((a) => !a.startsWith('--')) || DEFAULT_DESCRIPTION
}

async function main() {
  const mode = detectMode()
  const description = extractDescription(process.argv.slice(2))

  console.log(`\n🔨 Build Migration (${mode.toUpperCase()})`)

  if (mode === 'dev') {
    clearMigrations()

    const schemaFiles = findSchemaFiles()
    const tableFiles = findTableFiles()
    const functionFiles = findFunctionFiles()
    const triggerFiles = findTriggerFiles()
    const viewFiles = findViewFiles()
    const dataFiles = findDataFiles()

    if (functionFiles.length === 0) {
      console.error('❌ No function files found')
      process.exit(1)
    }

    const content = generateDevelopmentMigrationContent(
      schemaFiles,
      tableFiles,
      functionFiles,
      triggerFiles,
      viewFiles,
      dataFiles
    )
    const filename = '00000000000001_initial_schema.sql'
    writeFileSync(join(MIGRATIONS_DIR, filename), content, 'utf-8')

    console.log(`✅ Created: ${filename}`)
    console.log(
      `   Schema: ${schemaFiles.length}, Tables: ${tableFiles.length}, Functions: ${functionFiles.length}, Triggers: ${triggerFiles.length}, Views: ${viewFiles.length}, Data: ${dataFiles.length}`
    )
    console.log(`\n✨ Ready for: supabase db reset\n`)
  } else {
    if (!/^[a-z0-9_]+$/.test(description)) {
      console.error('❌ Invalid description. Use lowercase alphanumeric and underscores.')
      process.exit(1)
    }

    const functionFiles = findFunctionFiles()
    if (functionFiles.length === 0) {
      console.error('❌ No function files found')
      process.exit(1)
    }

    const content = generateProductionMigrationContent(functionFiles, description)
    const filename = `${getTimestamp()}_${description}.sql`
    writeFileSync(join(MIGRATIONS_DIR, filename), content, 'utf-8')

    console.log(`✅ Created: ${filename}`)
    console.log(`   Functions: ${functionFiles.length}`)
    console.log(`\n✨ Ready for: supabase migration up\n`)
  }
}

main()

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
const FUNCTIONS_DIR = 'supabase/db/functions'
const SCHEMA_DIR = 'supabase/db/schema'
const MIGRATIONS_DIR = 'supabase/migrations'
const DEFAULT_DESCRIPTION = 'update_functions'

// Mode detection
type BuildMode = 'dev' | 'prod'

function detectMode(): BuildMode {
  // Check environment variable first
  const environmentMode = process.env.BUILD_MODE?.toLowerCase()
  if (environmentMode === 'prod' || environmentMode === 'production') {
    return 'prod'
  }
  if (environmentMode === 'dev' || environmentMode === 'development') {
    return 'dev'
  }

  // Check CLI arguments
  const arguments_ = new Set(process.argv.slice(2))
  if (arguments_.has('--prod')) {
    return 'prod'
  }
  if (arguments_.has('--dev')) {
    return 'dev'
  }

  // Default to dev mode
  return 'dev'
}

/**
 * Get current timestamp in Supabase migration format (YYYYMMDDHHmmss)
 */
function getTimestamp(): string {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  const hours = String(now.getHours()).padStart(2, '0')
  const minutes = String(now.getMinutes()).padStart(2, '0')
  const seconds = String(now.getSeconds()).padStart(2, '0')

  return `${year}${month}${day}${hours}${minutes}${seconds}`
}

/**
 * Recursively find all .sql files in a directory
 */
function findSqlFiles(dir: string): string[] {
  const files: string[] = []

  function traverse(currentDir: string) {
    try {
      const entries = readdirSync(currentDir)

      for (const entry of entries) {
        const fullPath = join(currentDir, entry)
        const stat = statSync(fullPath)

        if (stat.isDirectory()) {
          traverse(fullPath)
        } else if (entry.endsWith('.sql')) {
          files.push(fullPath)
        }
      }
    } catch (error) {
      console.error(`Error reading directory ${currentDir}:`, error)
    }
  }

  traverse(dir)
  return files.sort() // Sort alphabetically for consistent output
}

/**
 * Find schema files in numeric order (01, 02, 03, etc.)
 * Excludes triggers (05_triggers.sql) which must come after functions
 */
function findSchemaFiles(): string[] {
  try {
    const entries = readdirSync(SCHEMA_DIR)
    const schemaFiles = entries
      .filter((entry) => entry.endsWith('.sql') && !entry.includes('triggers'))
      .map((entry) => join(SCHEMA_DIR, entry))
      .sort((a, b) => {
        // Extract numeric prefix for proper ordering
        const aNumber = Number.parseInt(a.match(/(\d+)/)?.[1] || '999')
        const bNumber = Number.parseInt(b.match(/(\d+)/)?.[1] || '999')
        return aNumber - bNumber
      })

    return schemaFiles
  } catch {
    // Schema directory might not exist, return empty array
    return []
  }
}

/**
 * Find trigger files (must come after functions)
 */
function findTriggerFiles(): string[] {
  try {
    const entries = readdirSync(SCHEMA_DIR)
    const triggerFiles = entries
      .filter((entry) => entry.endsWith('.sql') && entry.includes('triggers'))
      .map((entry) => join(SCHEMA_DIR, entry))
      .sort()

    return triggerFiles
  } catch {
    // Schema directory might not exist, return empty array
    return []
  }
}

/**
 * Read and return file content
 */
function readFile(filePath: string): string {
  try {
    return readFileSync(filePath, 'utf-8')
  } catch (error) {
    console.error(`Error reading file ${filePath}:`, error)
    throw error
  }
}

/**
 * Generate migration content for dev mode (schema + functions + triggers)
 */
function generateDevelopmentMigrationContent(
  schemaFiles: string[],
  functionFiles: string[],
  triggerFiles: string[]
): string {
  const timestamp = new Date().toISOString()
  let content = `-- Migration: Initial Schema and Functions\n`
  content += `-- Generated: ${timestamp}\n`
  content += `-- Mode: DEV (clean rebuild)\n`
  content += `-- Schema files: ${schemaFiles.length}\n`
  content += `-- Function files: ${functionFiles.length}\n`
  content += `-- Trigger files: ${triggerFiles.length}\n\n`

  // Add schema files first (extensions, tables, RLS, indexes)
  if (schemaFiles.length > 0) {
    content += `-- ${'='.repeat(76)}\n`
    content += `-- SCHEMA DEFINITIONS\n`
    content += `-- ${'='.repeat(76)}\n\n`

    for (const filePath of schemaFiles) {
      const relativePath = relative(SCHEMA_DIR, filePath)
      const fileContent = readFile(filePath)

      content += `-- ${'-'.repeat(74)}\n`
      content += `-- Schema: ${relativePath}\n`
      content += `-- ${'-'.repeat(74)}\n\n`
      content += fileContent.trim()
      content += '\n\n'
    }
  }

  // Add function files
  if (functionFiles.length > 0) {
    content += `-- ${'='.repeat(76)}\n`
    content += `-- FUNCTION DEFINITIONS\n`
    content += `-- ${'='.repeat(76)}\n\n`

    for (const filePath of functionFiles) {
      const relativePath = relative(FUNCTIONS_DIR, filePath)
      const fileContent = readFile(filePath)

      content += `-- ${'-'.repeat(74)}\n`
      content += `-- Function: ${relativePath}\n`
      content += `-- ${'-'.repeat(74)}\n\n`
      content += fileContent.trim()
      content += '\n\n'
    }
  }

  // Add trigger files last (after all functions are defined)
  if (triggerFiles.length > 0) {
    content += `-- ${'='.repeat(76)}\n`
    content += `-- TRIGGER DEFINITIONS\n`
    content += `-- ${'='.repeat(76)}\n\n`

    for (const filePath of triggerFiles) {
      const relativePath = relative(SCHEMA_DIR, filePath)
      const fileContent = readFile(filePath)

      content += `-- ${'-'.repeat(74)}\n`
      content += `-- Trigger: ${relativePath}\n`
      content += `-- ${'-'.repeat(74)}\n\n`
      content += fileContent.trim()
      content += '\n\n'
    }
  }

  return content
}

/**
 * Generate migration content for prod mode (functions only)
 */
function generateProductionMigrationContent(functionFiles: string[], description: string): string {
  const timestamp = new Date().toISOString()
  let content = `-- Migration: ${description}\n`
  content += `-- Generated: ${timestamp}\n`
  content += `-- Mode: PROD (incremental)\n`
  content += `-- Source: ${FUNCTIONS_DIR}/\n`
  content += `-- Files: ${functionFiles.length}\n\n`

  for (const filePath of functionFiles) {
    const relativePath = relative(FUNCTIONS_DIR, filePath)
    const fileContent = readFile(filePath)

    content += `-- ${'='.repeat(76)}\n`
    content += `-- Function: ${relativePath}\n`
    content += `-- ${'='.repeat(76)}\n\n`
    content += fileContent.trim()
    content += '\n\n'
  }

  return content
}

/**
 * Clear all migrations in dev mode
 */
function clearMigrations(): void {
  try {
    rmSync(MIGRATIONS_DIR, { recursive: true, force: true })
    mkdirSync(MIGRATIONS_DIR, { recursive: true })
    console.log(`✅ Cleared all existing migrations`)
  } catch (error) {
    console.error(`❌ Error clearing migrations:`, error)
    throw error
  }
}

/**
 * Extract description from CLI arguments, filtering out mode flags
 */
function extractDescription(arguments_: string[]): string {
  // Filter out mode flags and get remaining arguments
  const filtered = arguments_.find((argument) => !argument.startsWith('--'))
  return filtered || DEFAULT_DESCRIPTION
}

/**
 * Main function
 */
async function main() {
  try {
    const mode = detectMode()
    const arguments_ = process.argv.slice(2)
    const description = extractDescription(arguments_)

    console.log(`\n${'='.repeat(76)}`)
    console.log(`🔨 Build Migration Script`)
    console.log(`${'='.repeat(76)}`)
    console.log(`📋 Mode: ${mode.toUpperCase()}`)
    console.log(`${'='.repeat(76)}\n`)

    if (mode === 'dev') {
      // DEV MODE: Clean rebuild
      console.log(`⚠️  DEV MODE: Deleting all existing migrations\n`)

      clearMigrations()

      console.log(`🔍 Scanning for schema and function files...\n`)

      // Find schema files
      const schemaFiles = findSchemaFiles()
      if (schemaFiles.length > 0) {
        console.log(`✅ Found ${schemaFiles.length} schema files:`)
        for (const filePath of schemaFiles) {
          const relativePath = relative(SCHEMA_DIR, filePath)
          console.log(`   - ${relativePath}`)
        }
        console.log()
      }

      // Find function files
      const functionFiles = findSqlFiles(FUNCTIONS_DIR)
      if (functionFiles.length === 0) {
        console.error(`❌ No SQL files found in ${FUNCTIONS_DIR}`)
        process.exit(1)
      }

      console.log(`✅ Found ${functionFiles.length} function files:`)
      for (const filePath of functionFiles) {
        const relativePath = relative(FUNCTIONS_DIR, filePath)
        console.log(`   - ${relativePath}`)
      }
      console.log()

      // Find trigger files
      const triggerFiles = findTriggerFiles()
      if (triggerFiles.length > 0) {
        console.log(`✅ Found ${triggerFiles.length} trigger files:`)
        for (const filePath of triggerFiles) {
          const relativePath = relative(SCHEMA_DIR, filePath)
          console.log(`   - ${relativePath}`)
        }
        console.log()
      }

      // Generate migration content
      const migrationContent = generateDevelopmentMigrationContent(
        schemaFiles,
        functionFiles,
        triggerFiles
      )

      // Create migration file with fixed name for dev mode
      const migrationFilename = `00000000000001_initial_schema.sql`
      const migrationPath = join(MIGRATIONS_DIR, migrationFilename)

      writeFileSync(migrationPath, migrationContent, 'utf-8')

      console.log(`✅ Created migration: ${migrationFilename}`)
      console.log(
        `📁 Included ${schemaFiles.length} schema files and ${functionFiles.length} function files`
      )
      console.log(`📍 Location: ${migrationPath}`)
      console.log(`\n✨ Dev mode complete. Ready for: supabase db reset\n`)
    } else {
      // PROD MODE: Incremental migration
      console.log(`✅ PROD MODE: Adding incremental migration\n`)

      // Validate description format
      if (!/^[a-z0-9_]+$/.test(description)) {
        console.error(
          '❌ Invalid description format. Use lowercase alphanumeric and underscores only.'
        )
        process.exit(1)
      }

      console.log(`🔍 Scanning for SQL function files...\n`)

      // Find function files
      const functionFiles = findSqlFiles(FUNCTIONS_DIR)

      if (functionFiles.length === 0) {
        console.error(`❌ No SQL files found in ${FUNCTIONS_DIR}`)
        process.exit(1)
      }

      console.log(`✅ Found ${functionFiles.length} function files:`)
      for (const filePath of functionFiles) {
        const relativePath = relative(FUNCTIONS_DIR, filePath)
        console.log(`   - ${relativePath}`)
      }
      console.log()

      // Generate migration content
      const migrationContent = generateProductionMigrationContent(functionFiles, description)

      // Generate migration filename with timestamp
      const timestamp = getTimestamp()
      const migrationFilename = `${timestamp}_${description}.sql`
      const migrationPath = join(MIGRATIONS_DIR, migrationFilename)

      writeFileSync(migrationPath, migrationContent, 'utf-8')

      console.log(`✅ Created migration: ${migrationFilename}`)
      console.log(`📁 Included ${functionFiles.length} function files`)
      console.log(`📍 Location: ${migrationPath}`)
      console.log(`\n✨ Prod mode complete. Ready for: supabase migration up\n`)
    }

    console.log(`${'='.repeat(76)}\n`)
  } catch (error) {
    console.error('❌ Build migration failed:', error)
    process.exit(1)
  }
}

main()

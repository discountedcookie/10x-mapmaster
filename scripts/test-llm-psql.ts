#!/usr/bin/env bun
/**
 * Thin Bun wrapper around the psql-based LLM test script.
 *
 * Usage (examples):
 *   bun run scripts/test-llm-psql.ts places
 *   bun run scripts/test-llm-psql.ts config
 *   bun run scripts/test-llm-psql.ts set-config llm.question.model '"mistralai/mistral-7b-instruct:free"'
 *   bun run scripts/test-llm-psql.ts traits "Eiffel Tower"
 *   bun run scripts/test-llm-psql.ts question "330 meters" "A famous iron tower in Paris"
 *   bun run scripts/test-llm-psql.ts region "Poland" "A royal castle in Warsaw"
 *
 * This just forwards all args to ./scripts/test-llm.sh, which does the real work
 * using psql directly against the local Supabase Postgres instance.
 */

const [, , ...args] = process.argv

async function main() {
  if (args.length === 0) {
    console.log(
      `LLM psql test wrapper\n\nUsage: bun run scripts/test-llm-psql.ts <command> [...args]\n\nCommands are the same as ./scripts/test-llm.sh:\n  places                          List places with trait counts\n  config                          Show LLM configuration\n  set-config <key> <json-value>   Update config\n  traits <place_name>             Test trait extraction\n  question <trait> [description]  Test question generation\n  region <region> [description]   Test region question\n`
    )
    return
  }

  // Resolve the shell script path relative to this file
  const scriptUrl = new URL('./test-llm.sh', import.meta.url)

  const proc = Bun.spawn(['bash', scriptUrl.pathname, ...args], {
    stdin: 'inherit',
    stdout: 'inherit',
    stderr: 'inherit',
  })

  const exitCode = await proc.exited
  if (exitCode !== 0) {
    process.exit(exitCode)
  }
}

main().catch((error) => {
  console.error('Error running test-llm-psql wrapper:', error)
  process.exit(1)
})

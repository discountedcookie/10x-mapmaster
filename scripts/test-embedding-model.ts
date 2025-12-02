#!/usr/bin/env bun

const ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'
const ENDPOINT = 'http://127.0.0.1:54321/functions/v1/generate-embedding'

const QUERIES = {
  en: 'famous European tower',
  pl: 'słynna europejska wieża',
}

// Real traits from database - Eiffel Tower (should match)
const EIFFEL_TRAITS = [
  'A tower',
  'Located in France',
  'Completed in 1889',
  '330 meters tall including antenna',
  'Constructed primarily of wrought iron',
  'Recognized globally as a symbol of modern engineering and design',
]

// Real traits from database - Grand Canyon (should NOT match)
const CANYON_TRAITS = [
  'Natural',
  'Valley',
  'United States',
  'Over 1,600 meters deep at its deepest point',
  'Stretches 446 kilometers long',
]

const PASSAGES = [...EIFFEL_TRAITS, ...CANYON_TRAITS]

async function getEmbedding(text: string, inputType: string): Promise<number[]> {
  const res = await fetch(ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${ANON_KEY}`,
    },
    body: JSON.stringify({ text, inputType }),
  })
  const data = await res.json()
  if (!data.embedding) {
    throw new Error(`Failed: ${JSON.stringify(data)}`)
  }
  return data.embedding
}

function cosine(a: number[], b: number[]): number {
  let dot = 0,
    nA = 0,
    nB = 0
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i]
    nA += a[i] * a[i]
    nB += b[i] * b[i]
  }
  return dot / (Math.sqrt(nA) * Math.sqrt(nB))
}

async function main() {
  // Get embeddings for both queries
  const queryEN = await getEmbedding(QUERIES.en, 'query')
  const queryPL = await getEmbedding(QUERIES.pl, 'query')

  // Get embeddings for all passages
  const passageEmbeddings: number[][] = []
  for (const p of PASSAGES) {
    passageEmbeddings.push(await getEmbedding(p, 'passage'))
  }

  // Print header
  const pad = (s: string, n: number) => s.slice(0, n).padEnd(n)
  console.log(`${pad('Passage', 50)} ${pad('EN', 8)} ${pad('PL', 8)} Diff`)
  console.log('-'.repeat(74))

  // Print Eiffel traits (should match)
  console.log('EIFFEL TOWER (should match):')
  for (let i = 0; i < EIFFEL_TRAITS.length; i++) {
    const simEN = cosine(queryEN, passageEmbeddings[i])
    const simPL = cosine(queryPL, passageEmbeddings[i])
    const diff = simEN - simPL
    console.log(
      `${pad(PASSAGES[i], 50)} ${simEN.toFixed(4)}   ${simPL.toFixed(4)}   ${diff > 0 ? '+' : ''}${diff.toFixed(4)}`
    )
  }

  // Print Canyon traits (should NOT match)
  console.log('\nGRAND CANYON (should NOT match):')
  for (let i = EIFFEL_TRAITS.length; i < PASSAGES.length; i++) {
    const simEN = cosine(queryEN, passageEmbeddings[i])
    const simPL = cosine(queryPL, passageEmbeddings[i])
    const diff = simEN - simPL
    console.log(
      `${pad(PASSAGES[i], 50)} ${simEN.toFixed(4)}   ${simPL.toFixed(4)}   ${diff > 0 ? '+' : ''}${diff.toFixed(4)}`
    )
  }

  // Summary
  console.log('-'.repeat(52))
  console.log(`EN query: "${QUERIES.en}"`)
  console.log(`PL query: "${QUERIES.pl}"`)
}

main().catch(console.error)

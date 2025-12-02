#!/usr/bin/env bun

/**
 * Test different embedding + algorithm configurations
 * Goal: Find a config that gives E5 similar discrimination to MiniLM
 */

const ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'
const ENDPOINT = 'http://127.0.0.1:54321/functions/v1/generate-embedding'

// Queries
const QUERY_EN = 'famous European tower'
const QUERY_PL = 'słynna europejska wieża'

// Real traits from database
const EIFFEL_TRAITS = [
  'A tower',
  'Located in France',
  'Completed in 1889',
  '330 meters tall including antenna',
  'Constructed primarily of wrought iron',
  'Recognized globally as a symbol of modern engineering and design',
]

const CANYON_TRAITS = [
  'Natural',
  'Valley',
  'United States',
  'Over 1,600 meters deep at its deepest point',
  'Stretches 446 kilometers long',
]

// Helpers
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
  if (!data.embedding) throw new Error(`Failed: ${JSON.stringify(data)}`)
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

// Aggregation methods
function softmaxAggregate(similarities: number[], temperature: number): number {
  const expSims = similarities.map((s) => Math.exp(s / temperature))
  const sumExp = expSims.reduce((a, b) => a + b, 0)
  const weights = expSims.map((e) => e / sumExp)
  return similarities.reduce((sum, s, i) => sum + weights[i] * s, 0)
}

function maxAggregate(similarities: number[]): number {
  return Math.max(...similarities)
}

function meanAggregate(similarities: number[]): number {
  return similarities.reduce((a, b) => a + b, 0) / similarities.length
}

function topKMeanAggregate(similarities: number[], k: number): number {
  const sorted = [...similarities].sort((a, b) => b - a)
  const topK = sorted.slice(0, k)
  return topK.reduce((a, b) => a + b, 0) / topK.length
}

// Score transformation (to expand compressed E5 scores)
function expandScore(score: number, center: number, scale: number): number {
  // Expand around center point
  return (score - center) * scale + 0.5
}

// Cross-language concept pairs (should be similar)
const SAME_CONCEPT_PAIRS = [
  ['tower', 'wieża'],
  ['beach', 'plaża'],
  ['mountain', 'góra'],
  ['river', 'rzeka'],
  ['A tall iron tower in Europe', 'Wysoka żelazna wieża w Europie'],
  ['Natural rock formation', 'Naturalna formacja skalna'],
]

// Different concepts (should NOT be similar)
const DIFFERENT_CONCEPT_PAIRS = [
  ['tower', 'beach'],
  ['tower', 'plaża'],
  ['mountain', 'river'],
  ['A tall iron tower', 'Natural rock formation'],
]

async function main() {
  console.log('Fetching embeddings...\n')

  // Get query embeddings
  const queryEN = await getEmbedding(QUERY_EN, 'query')
  const queryPL = await getEmbedding(QUERY_PL, 'query')

  // Get individual trait embeddings
  const eiffelEmbeddings: number[][] = []
  for (const t of EIFFEL_TRAITS) {
    eiffelEmbeddings.push(await getEmbedding(t, 'passage'))
  }

  const canyonEmbeddings: number[][] = []
  for (const t of CANYON_TRAITS) {
    canyonEmbeddings.push(await getEmbedding(t, 'passage'))
  }

  // Get combined trait embeddings
  const eiffelCombined = await getEmbedding(EIFFEL_TRAITS.join('. '), 'passage')
  const canyonCombined = await getEmbedding(CANYON_TRAITS.join('. '), 'passage')

  // Calculate raw similarities
  const eiffelSimsEN = eiffelEmbeddings.map((e) => cosine(queryEN, e))
  const eiffelSimsPL = eiffelEmbeddings.map((e) => cosine(queryPL, e))
  const canyonSimsEN = canyonEmbeddings.map((e) => cosine(queryEN, e))
  const canyonSimsPL = canyonEmbeddings.map((e) => cosine(queryPL, e))

  const eiffelCombinedSimEN = cosine(queryEN, eiffelCombined)
  const eiffelCombinedSimPL = cosine(queryPL, eiffelCombined)
  const canyonCombinedSimEN = cosine(queryEN, canyonCombined)
  const canyonCombinedSimPL = cosine(queryPL, canyonCombined)

  // Print raw similarities
  console.log('='.repeat(80))
  console.log('RAW TRAIT SIMILARITIES')
  console.log('='.repeat(80))
  console.log('\nEiffel Tower traits:')
  EIFFEL_TRAITS.forEach((t, i) => {
    console.log(
      `  ${eiffelSimsEN[i].toFixed(4)} EN | ${eiffelSimsPL[i].toFixed(4)} PL | ${t.slice(0, 50)}`
    )
  })
  console.log('\nGrand Canyon traits:')
  CANYON_TRAITS.forEach((t, i) => {
    console.log(
      `  ${canyonSimsEN[i].toFixed(4)} EN | ${canyonSimsPL[i].toFixed(4)} PL | ${t.slice(0, 50)}`
    )
  })

  // Test different configurations
  console.log('\n' + '='.repeat(80))
  console.log('AGGREGATION METHOD COMPARISON')
  console.log('='.repeat(80))
  console.log(
    '\nMethod                          | Eiffel EN | Canyon EN | Spread | Eiffel PL | Canyon PL | Spread'
  )
  console.log('-'.repeat(100))

  const configs: [string, (sims: number[]) => number][] = [
    ['Softmax τ=0.1 (current)', (s) => softmaxAggregate(s, 0.1)],
    ['Softmax τ=0.05', (s) => softmaxAggregate(s, 0.05)],
    ['Softmax τ=0.02', (s) => softmaxAggregate(s, 0.02)],
    ['Softmax τ=0.01', (s) => softmaxAggregate(s, 0.01)],
    ['Max only', maxAggregate],
    ['Mean', meanAggregate],
    ['Top-2 mean', (s) => topKMeanAggregate(s, 2)],
    ['Top-3 mean', (s) => topKMeanAggregate(s, 3)],
  ]

  for (const [name, fn] of configs) {
    const eEN = fn(eiffelSimsEN)
    const cEN = fn(canyonSimsEN)
    const ePL = fn(eiffelSimsPL)
    const cPL = fn(canyonSimsPL)
    const spreadEN = eEN - cEN
    const spreadPL = ePL - cPL
    console.log(
      `${name.padEnd(32)}| ${eEN.toFixed(4)}    | ${cEN.toFixed(4)}    | ${spreadEN.toFixed(4)}  | ${ePL.toFixed(4)}    | ${cPL.toFixed(4)}    | ${spreadPL.toFixed(4)}`
    )
  }

  // Combined embeddings comparison
  console.log('\n' + '='.repeat(80))
  console.log('COMBINED EMBEDDINGS (single embedding per place)')
  console.log('='.repeat(80))
  console.log(
    '\nMethod                          | Eiffel EN | Canyon EN | Spread | Eiffel PL | Canyon PL | Spread'
  )
  console.log('-'.repeat(100))
  const combinedSpreadEN = eiffelCombinedSimEN - canyonCombinedSimEN
  const combinedSpreadPL = eiffelCombinedSimPL - canyonCombinedSimPL
  console.log(
    `${'Combined traits'.padEnd(32)}| ${eiffelCombinedSimEN.toFixed(4)}    | ${canyonCombinedSimEN.toFixed(4)}    | ${combinedSpreadEN.toFixed(4)}  | ${eiffelCombinedSimPL.toFixed(4)}    | ${canyonCombinedSimPL.toFixed(4)}    | ${combinedSpreadPL.toFixed(4)}`
  )

  // Score expansion experiment
  console.log('\n' + '='.repeat(80))
  console.log('SCORE EXPANSION (stretch compressed E5 scores)')
  console.log('='.repeat(80))

  // Find center of E5 score distribution
  const allSims = [...eiffelSimsEN, ...canyonSimsEN]
  const minSim = Math.min(...allSims)
  const maxSim = Math.max(...allSims)
  const centerSim = (minSim + maxSim) / 2

  console.log(
    `\nE5 score range: ${minSim.toFixed(4)} - ${maxSim.toFixed(4)}, center: ${centerSim.toFixed(4)}`
  )
  console.log('\nExpanded scores (center=' + centerSim.toFixed(2) + '):')
  console.log('Scale | Eiffel Max EN | Canyon Max EN | Spread')
  console.log('-'.repeat(60))

  for (const scale of [5, 10, 15, 20]) {
    const eiffelExpanded = eiffelSimsEN.map((s) => expandScore(s, centerSim, scale))
    const canyonExpanded = canyonSimsEN.map((s) => expandScore(s, centerSim, scale))
    const eMax = Math.max(...eiffelExpanded)
    const cMax = Math.max(...canyonExpanded)
    console.log(
      `${scale.toString().padEnd(6)}| ${eMax.toFixed(4)}        | ${cMax.toFixed(4)}        | ${(eMax - cMax).toFixed(4)}`
    )
  }

  // Normalized ranking approach
  console.log('\n' + '='.repeat(80))
  console.log('NORMALIZED RANKING (min-max scale per query)')
  console.log('='.repeat(80))

  function normalizeScores(scores: number[]): number[] {
    const min = Math.min(...scores)
    const max = Math.max(...scores)
    if (max === min) return scores.map(() => 0.5)
    return scores.map((s) => (s - min) / (max - min))
  }

  // Combine all scores for normalization
  const allSimsEN = [...eiffelSimsEN, ...canyonSimsEN]
  const allSimsPL = [...eiffelSimsPL, ...canyonSimsPL]

  const normalizedEN = normalizeScores(allSimsEN)
  const normalizedPL = normalizeScores(allSimsPL)

  const normEiffelEN = normalizedEN.slice(0, EIFFEL_TRAITS.length)
  const normCanyonEN = normalizedEN.slice(EIFFEL_TRAITS.length)
  const normEiffelPL = normalizedPL.slice(0, EIFFEL_TRAITS.length)
  const normCanyonPL = normalizedPL.slice(EIFFEL_TRAITS.length)

  console.log('\nNormalized trait scores (0-1 scale):')
  console.log('\nEiffel Tower:')
  EIFFEL_TRAITS.forEach((t, i) => {
    console.log(
      `  ${normEiffelEN[i].toFixed(4)} EN | ${normEiffelPL[i].toFixed(4)} PL | ${t.slice(0, 40)}`
    )
  })
  console.log('\nGrand Canyon:')
  CANYON_TRAITS.forEach((t, i) => {
    console.log(
      `  ${normCanyonEN[i].toFixed(4)} EN | ${normCanyonPL[i].toFixed(4)} PL | ${t.slice(0, 40)}`
    )
  })

  // Aggregation on normalized scores
  console.log('\nAggregation on normalized scores:')
  console.log(
    'Method                          | Eiffel EN | Canyon EN | Spread | Eiffel PL | Canyon PL | Spread'
  )
  console.log('-'.repeat(100))

  const normConfigs: [string, (sims: number[]) => number][] = [
    ['Max (normalized)', maxAggregate],
    ['Top-2 mean (normalized)', (s) => topKMeanAggregate(s, 2)],
    ['Softmax τ=0.2 (normalized)', (s) => softmaxAggregate(s, 0.2)],
  ]

  for (const [name, fn] of normConfigs) {
    const eEN = fn(normEiffelEN)
    const cEN = fn(normCanyonEN)
    const ePL = fn(normEiffelPL)
    const cPL = fn(normCanyonPL)
    const spreadEN = eEN - cEN
    const spreadPL = ePL - cPL
    console.log(
      `${name.padEnd(32)}| ${eEN.toFixed(4)}    | ${cEN.toFixed(4)}    | ${spreadEN.toFixed(4)}  | ${ePL.toFixed(4)}    | ${cPL.toFixed(4)}    | ${spreadPL.toFixed(4)}`
    )
  }

  // Summary
  console.log('\n' + '='.repeat(80))
  console.log('SUMMARY')
  console.log('='.repeat(80))
  console.log(`
Query EN: "${QUERY_EN}"
Query PL: "${QUERY_PL}"

KEY FINDINGS:
1. Combined embeddings: Best EN spread (0.097) but PL still ~0.02
2. Score expansion: Can artificially increase spread but only for EN
3. Normalized ranking: Converts to relative positions (0-1 scale)

The fundamental issue: E5's Polish query doesn't discriminate well.
Raw PL scores: "Located in France" (0.82) vs "446 km long" (0.80) - too close.

POSSIBLE SOLUTIONS:
A) Use MiniLM for English, E5 for other languages (detect language)
B) Use combined embeddings + accept lower PL discrimination  
C) Translate non-English queries to English before embedding
D) Use normalized ranking (min-max per query) - gives 0.57 EN / 0.28 PL spread!

NOTE: PL normalized scores show "446 km long" (0.73) > "A tower" (0.48)
      Polish query matches numbers/dimensions better than concepts.
      This might be a fundamental limitation of E5's multilingual training.
`)

  // Cross-language concept similarity test
  console.log('\n' + '='.repeat(80))
  console.log('CROSS-LANGUAGE CONCEPT SIMILARITY')
  console.log('='.repeat(80))

  const sameConcepts = [
    ['tower', 'wieża'],
    ['beach', 'plaża'],
    ['mountain', 'góra'],
    ['river', 'rzeka'],
    ['A tall iron tower in Europe', 'Wysoka żelazna wieża w Europie'],
    ['Natural rock formation', 'Naturalna formacja skalna'],
  ]

  const differentConcepts = [
    ['tower', 'beach'],
    ['tower', 'plaża'],
    ['mountain', 'river'],
    ['A tall iron tower', 'Natural rock formation'],
  ]

  console.log('\nSAME concept (should be HIGH similarity):')
  console.log(
    'English                              | Polish/Other                         | Similarity'
  )
  console.log('-'.repeat(95))

  for (const [en, other] of sameConcepts) {
    const embEN = await getEmbedding(en, 'passage')
    const embOther = await getEmbedding(other, 'passage')
    const sim = cosine(embEN, embOther)
    console.log(
      `${en.slice(0, 35).padEnd(37)}| ${other.slice(0, 35).padEnd(37)}| ${sim.toFixed(4)}`
    )
  }

  console.log('\nDIFFERENT concepts (should be LOW similarity):')
  console.log(
    'Concept A                            | Concept B                            | Similarity'
  )
  console.log('-'.repeat(95))

  for (const [a, b] of differentConcepts) {
    const embA = await getEmbedding(a, 'passage')
    const embB = await getEmbedding(b, 'passage')
    const sim = cosine(embA, embB)
    console.log(`${a.slice(0, 35).padEnd(37)}| ${b.slice(0, 35).padEnd(37)}| ${sim.toFixed(4)}`)
  }

  console.log('\nINTERPRETATION:')
  console.log('- Good multilingual: SAME concepts ~0.8+, DIFFERENT concepts <0.5')
  console.log('- Poor multilingual: SAME concepts similar to DIFFERENT concepts')
}

main().catch(console.error)

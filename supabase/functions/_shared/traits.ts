export interface NormalizedNominatimPlace {
  class?: string

  type?: string
  address?: Record<string, unknown>
  extratags?: Record<string, unknown>
}

export interface TraitCandidate {
  id: string
  category: string
  clause: string
  sourceKey: string
  value: string
  metadata?: Record<string, unknown>
}

const PRIMARY_FIELDS: Array<{
  category: string
  sourceKey: string
  template: string
  getValue: (record: NormalizedNominatimPlace) => string | null | undefined
}> = [
  {
    category: 'class',
    sourceKey: 'class',
    template: '{{value}}',
    getValue: (record) => record.class,
  },
  {
    category: 'type',
    sourceKey: 'type',
    template: '{{value}}',
    getValue: (record) => record.type,
  },
  {
    category: 'country',
    sourceKey: 'address.country',
    template: '{{value}}',
    getValue: (record) => {
      const address = record.address as Record<string, unknown>
      return typeof address.country === 'string' ? address.country : null
    },
  },
]

const NUMERIC_EXTRATAG_RULES: Record<string, (value: string) => TraitCandidate | null> = {
  height: (value) => buildHeightTrait('height', value),
  ele: (value) => buildHeightTrait('ele', value),
  'building:height': (value) => buildHeightTrait('building:height', value),
  'building:levels': (value) => buildLevelTrait(value),
  // Removed start_date - too unreliable (BC dates, future dates, etc.)
  // We get better structured data from tags like "historic:era:neolithic"
}

// Categories that help players guess places in the game
const USEFUL_TRAIT_CATEGORIES = new Set([
  'class',
  'type',
  'country', // Primary classification
  'place', // Place types (city, town, village, etc.)
  'height',
  'era',
  'floors', // Size/age
  'material', // Physical traits
  'shape',
  'structure', // Structural features
  'civilization',
  'period', // Historical context
  'building',
  'tower',
  'bridge',
  'monument',
  'tomb',
  'volcano', // Landmark types
  'heritage',
  'tourism',
  'historic', // Cultural significance
  'religion',
  'denomination', // Religious context
  'ruins',
  'ruin_type',
  'archaeological_site', // Archaeological sites
  'landcover',
  'surface', // Terrain
  'barrier',
  'man_made', // Construction type
  'importance', // Significance
])

const EXTRATAG_SKIP_PATTERNS = [
  /url/i,
  /wikidata/i,
  /wikipedia/i,
  /wikimedia/i,
  /website/i,
  /image/i,
  /email/i,
  /operator/i,
  /addr/i,
  /contact/i,
  /ref/i,
  /phone/i,
  /int_name/i,
  /layer/i,
  /opening_hours/i,
  /description/i,
  /inscription/i,
  /panoramax/i,
  /start_date/i, // Skip - unreliable (BC dates, future dates)
  /date/i, // Skip all date fields
]

// Values that are too generic/useless for the guessing game
const USELESS_TRAIT_VALUES = new Set([
  'boundary',
  'administrative',
  'political',
  'postcode',
  'yes',
  'no',
])

const URL_PATTERN = /(https?:\/\/|www\.|@)/i
const LETTER_PATTERN = /[A-Za-z]/
const MAX_TRAIT_VALUE_LENGTH = 100
const MAX_KEY_DEPTH = 2 // Max colons in key (e.g., "building:colour" = 1 colon)

function normalizeId(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '')
}

function humanize(value: string): string {
  return value
    .split(/[_:]/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

function createCandidate(
  category: string,
  sourceKey: string,
  rawValue: string,
  clauseTemplate: string,
  metadata?: Record<string, unknown>
): TraitCandidate | null {
  const normalized = normalizeId(rawValue)
  if (!normalized) return null
  const clause = clauseTemplate.replace('{{value}}', humanize(rawValue))
  return {
    id: `${category}:${normalized}`,
    category,
    clause,
    sourceKey,
    value: rawValue,
    metadata,
  }
}

function buildHeightTrait(sourceKey: string, rawValue: string): TraitCandidate | null {
  const numeric = Number.parseFloat(rawValue)
  if (!Number.isFinite(numeric)) {
    return null
  }
  let bucketId = 'unknown'
  let clause = 'Unspecified height'
  if (numeric < 50) {
    bucketId = 'under_50m'
    clause = 'Under 50m'
  } else if (numeric < 150) {
    bucketId = '50_to_150m'
    clause = '50-150m tall'
  } else if (numeric < 300) {
    bucketId = '150_to_300m'
    clause = '150-300m tall'
  } else {
    bucketId = 'over_300m'
    clause = 'Over 300m tall'
  }
  return {
    id: `height:${bucketId}`,
    category: 'height',
    clause,
    sourceKey,
    value: rawValue,
    metadata: { meters: numeric },
  }
}

function buildLevelTrait(rawValue: string): TraitCandidate | null {
  const levels = Number.parseInt(rawValue, 10)
  if (!Number.isFinite(levels)) {
    return null
  }
  const clause = `${levels} floors`
  return {
    id: `floors:${normalizeId(String(levels))}`,
    category: 'floors',
    clause,
    sourceKey: 'building:levels',
    value: rawValue,
    metadata: { levels },
  }
}

// Era trait function currently unused but kept for potential future use
// function buildEraTrait(rawValue: string): TraitCandidate | null {
//   const match = rawValue.match(/(\d{4})/)
//   if (!match) return null
//   const year = Number.parseInt(match[1], 10)
//   if (!Number.isFinite(year)) {
//     return null
//   }
//   let bucket = 'contemporary'
//   let clause = `Contemporary (${year})`
//   if (year < 1500) {
//     bucket = 'ancient'
//     clause = `Ancient (${year})`
//   } else if (year < 1900) {
//     bucket = 'historic'
//     clause = `Historic (${year})`
//   } else if (year < 2000) {
//     bucket = 'modern'
//     clause = `Modern (${year})`
//   }
//   return {
//     id: `era:${bucket}`,
//     category: 'era',
//     clause,
//     sourceKey: 'start_date',
//     value: rawValue,
//     metadata: { year },
//   }
// }

function shouldSkipExtratag(key: string, value: unknown): boolean {
  if (typeof value !== 'string') {
    return true
  }

  // Skip values that are too long (likely descriptions/URLs)
  if (value.length > MAX_TRAIT_VALUE_LENGTH) {
    return true
  }

  // Skip nested language keys (e.g., "wheelchair:description:de:...")
  const keyDepth = (key.match(/:/g) || []).length
  if (keyDepth > MAX_KEY_DEPTH) {
    return true
  }

  // Skip URLs
  if (URL_PATTERN.test(value)) {
    return true
  }

  // Skip values without letters (unless it's a numeric rule)
  if (!LETTER_PATTERN.test(value) && !(key in NUMERIC_EXTRATAG_RULES)) {
    return true
  }

  // Skip known useless patterns
  return EXTRATAG_SKIP_PATTERNS.some((pattern) => pattern.test(key))
}

function shouldKeepTrait(candidate: TraitCandidate): boolean {
  // Only keep traits in useful categories
  if (!USEFUL_TRAIT_CATEGORIES.has(candidate.category)) {
    return false
  }

  // Filter out useless values (e.g., "boundary", "administrative")
  const normalizedValue = normalizeId(candidate.value)
  if (USELESS_TRAIT_VALUES.has(normalizedValue)) {
    return false
  }

  return true
}

function deriveCategoryFromKey(key: string): string {
  const segments = key.split(':')
  if (segments.length === 1) {
    return segments[0]
  }
  return segments[segments.length - 1]
}

function buildGeneralExtratagTrait(key: string, value: string): TraitCandidate | null {
  if (!LETTER_PATTERN.test(value)) {
    return null
  }

  // Skip hex colors and other technical values
  if (value.startsWith('#') || value.match(/^[0-9a-f]{6}$/i)) {
    return null
  }

  const category = deriveCategoryFromKey(key)
  const normalizedValue = normalizeId(value)
  if (!normalizedValue) return null

  // Handle boolean tags (e.g., "building:yes" -> just "building")
  if (value.toLowerCase() === 'yes' || value.toLowerCase() === 'true') {
    return {
      id: key,
      category,
      clause: humanize(key),
      sourceKey: key,
      value,
      metadata: { key, boolean: true },
    }
  }

  // For "no" values, skip them entirely - they don't add useful information
  if (value.toLowerCase() === 'no' || value.toLowerCase() === 'false') {
    return null
  }

  // For everything else: just "humanized value" (e.g., "Limestone", "Auguste Bartholdi")
  return {
    id: `${key}:${normalizedValue}`,
    category,
    clause: humanize(value),
    sourceKey: key,
    value,
    metadata: { key },
  }
}

export function extractTraitsFromNominatim(record: NormalizedNominatimPlace): TraitCandidate[] {
  const candidates: TraitCandidate[] = []

  for (const field of PRIMARY_FIELDS) {
    const value = field.getValue(record)
    if (typeof value === 'string' && value.trim().length > 0) {
      const candidate = createCandidate(field.category, field.sourceKey, value, field.template)
      if (candidate && shouldKeepTrait(candidate)) {
        candidates.push(candidate)
      }
    }
  }

  const extratags = (record.extratags ?? {}) as Record<string, unknown>
  for (const [key, rawValue] of Object.entries(extratags)) {
    if (key in NUMERIC_EXTRATAG_RULES && typeof rawValue === 'string') {
      const numericTrait = NUMERIC_EXTRATAG_RULES[key](rawValue)
      if (numericTrait) {
        candidates.push(numericTrait)
        continue
      }
    }

    if (shouldSkipExtratag(key, rawValue)) {
      continue
    }

    if (typeof rawValue === 'string') {
      const trait = buildGeneralExtratagTrait(key, rawValue)
      if (trait && shouldKeepTrait(trait)) {
        candidates.push(trait)
      }
    }
  }

  return candidates
}

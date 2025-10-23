# Technical: External APIs

## Nominatim (Geocoding)

**Purpose:** Convert place names to coordinates + metadata

**Base URL:** `https://nominatim.openstreetmap.org/`

**Rate Limit:** 1 request per second

**Implementation:**
```typescript
// src/lib/places/nominatim.ts

// Debounced search to respect rate limit
const searchDebounced = useDebouncedFn(async (query: string) => {
  const response = await fetch(
    `https://nominatim.openstreetmap.org/search?` +
    `format=json&q=${encodeURIComponent(query)}&limit=10`
  )
  return response.json()
}, 1000) // 1 second debounce
```

**Rate Limit Strategy:**
- Debounce user input (1 second)
- Cache results in component state
- Show cached results while waiting

**Deduplication:**
Nominatim can return duplicate results. Deduplicate by coordinates:

```typescript
const deduplicated = results.filter((place, index, self) =>
  index === self.findIndex(p =>
    Math.abs(p.lat - place.lat) < 0.001 &&
    Math.abs(p.lon - place.lon) < 0.001
  )
)
```

**Tolerance:** ±0.001° (~100m at equator)

**Response Structure:**
```typescript
interface NominatimPlace {
  place_id: number
  lat: string
  lon: string
  display_name: string
  type: string          // "city", "natural", "tourism", etc.
  class: string         // "place", "natural", "tourism", etc.
  addresstype: string
  importance: number
  extratags?: {
    ele?: string        // Elevation in meters
    height?: string     // Height for buildings
    natural?: string    // Natural feature type
    wikidata?: string   // Wikidata ID
    wikipedia?: string  // Wikipedia link
  }
  address?: {
    country?: string
    country_code?: string
    city?: string
    town?: string
    village?: string
  }
}
```

**Data Extraction:**
Store raw response as `descriptors` JSONB in database:
```typescript
const descriptors = {
  type: result.type,
  class: result.class,
  country_code: result.address?.country_code,
  extratags: result.extratags,
  // ... other metadata
}
```

**Known Issues:**
- Not all places have `extratags.ele` (elevation)
- Not all places have Wikipedia links
- Some famous places missing detailed data
- Coordinates may vary slightly between searches

## MapLibre GL JS (Map Rendering)

**Purpose:** Interactive map visualization

**Version:** v5.9.0

**Lazy Loading:**
```typescript
// Don't import at top level
// const maplibregl = require('maplibre-gl')

// Instead, dynamic import in mounted()
const maplibregl = await import('maplibre-gl')
```

**Why:** MapLibre is ~500KB, lazy load reduces initial bundle size

**Map Styles:**
- Light theme: `https://tiles.stadiamaps.com/styles/alidade_smooth.json`
- Dark theme: `https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json`

**Theme Switching:**
Force map recreation when theme changes using Vue `key` attribute:
```vue
<MglMap
  :key="mapStyle"
  :map-style="mapStyle"
/>
```

**Marker Clustering:**
```typescript
map.addSource('places', {
  type: 'geojson',
  data: geojsonData,
  cluster: true,
  clusterMaxZoom: 14,
  clusterRadius: 50
})
```

**Real-time Candidate Updates:**
Update GeoJSON source when candidates change:
```typescript
const source = map.getSource('places')
if (source) {
  source.setData(newGeojsonData)
}
```

**Performance:**
- Only render visible candidates
- Use clustering for many markers
- Debounce fitBounds on candidate updates

## Open-Meteo (Weather)

**Purpose:** Weather data for place enrichment (future feature)

**Base URL:** `https://api.open-meteo.com/v1/forecast`

**Rate Limit:** Generous (no authentication needed)

**Example:**
```typescript
const response = await fetch(
  `https://api.open-meteo.com/v1/forecast?` +
  `latitude=${lat}&longitude=${lng}&current_weather=true`
)
```

**Response:**
```typescript
{
  current_weather: {
    temperature: number
    windspeed: number
    weathercode: number
  }
}
```

## Overpass (OpenStreetMap Data)

**Purpose:** Detailed OSM data for place enrichment (future feature)

**Base URL:** `https://overpass-api.de/api/interpreter`

**Rate Limit:** Generous, but respect usage guidelines

**Example Query:**
```typescript
const query = `
  [out:json];
  node(around:100,${lat},${lng});
  out body;
`

const response = await fetch(
  'https://overpass-api.de/api/interpreter',
  {
    method: 'POST',
    body: 'data=' + encodeURIComponent(query)
  }
)
```

**Use Cases:**
- Get nearby POIs
- Enrich place descriptions
- Validate place existence

## Wikipedia (Place Enrichment)

**Purpose:** Rich text descriptions for place embeddings

**Implementation:** `src/lib/places/wikipedia.ts`

**API:** MediaWiki API

**Example:**
```typescript
async function getWikipediaExtract(title: string): Promise<string | null> {
  const response = await fetch(
    `https://en.wikipedia.org/w/api.php?` +
    `action=query&format=json&prop=extracts&exintro=true&` +
    `explaintext=true&titles=${encodeURIComponent(title)}&origin=*`
  )
  
  const data = await response.json()
  const pages = data.query.pages
  const page = Object.values(pages)[0]
  
  return page.extract || null
}
```

**Integration:**
1. Extract Wikipedia link from Nominatim `extratags.wikipedia`
2. Fetch first paragraph with MediaWiki API
3. Combine with place name for richer embedding
4. Example: "Eiffel Tower in Paris, France. Wrought-iron lattice tower on the Champ de Mars..."

**Benefits:**
- Much richer embeddings than "Eiffel Tower. Type: tower. Category: tourism."
- Better semantic discrimination between similar places
- Natural language descriptions work better with gte-small model

**Rate Limit:** Reasonable, but cache results

**Known Issues:**
- Not all Nominatim places have Wikipedia links
- Some Wikipedia titles from Nominatim are malformed
- API can be slow (~500ms+)
- Need error handling for missing pages

## Supabase Edge Functions (Embeddings)

**Purpose:** Generate vector embeddings server-side

**Location:** `supabase/functions/generate-embedding/index.ts`

**Runtime:** Deno

**API:**
```typescript
POST /functions/v1/generate-embedding
Authorization: Bearer <anon_key>

Body:
{
  "text": "Eiffel Tower in Paris, France. Famous iron lattice tower."
}

Response:
{
  "embedding": [0.123, -0.456, ...] // 384 dimensions
}
```

**Model:** Supabase AI gte-small (384 dimensions)

**Usage in Frontend:**
```typescript
// src/composables/useEmbeddings.ts

async function generateEmbedding(text: string): Promise<number[]> {
  const { data, error } = await supabase.functions.invoke(
    'generate-embedding',
    { body: { text } }
  )
  
  if (error) throw error
  return data.embedding
}
```

**Rate Limit:** 
- Production: Generous (Supabase AI tier dependent)
- Local: Same as production (calls production function)

**Caching:**
- Embeddings stored in database (never regenerated)
- Frontend caches current session embeddings in memory

**Cost:**
- Included in Supabase AI pricing
- ~0.0001 cents per embedding
- Negligible for MVP scale

## API Error Handling

**Pattern:**
```typescript
try {
  const data = await fetchExternalAPI()
  return data
} catch (error) {
  console.error('API error:', error)
  toast.error('Failed to fetch data', {
    description: 'Please try again'
  })
  return null
}
```

**User-Friendly Messages:**
- Don't expose technical details
- Provide actionable next steps
- Use toast notifications (not alerts)

**Retry Strategy:**
- Nominatim: User can re-search
- Embeddings: Show error, let user retry
- Map: Fallback to default view
- Wikipedia: Fail gracefully (use basic description)

## Rate Limit Monitoring

**Nominatim:**
- Track last request time
- Enforce 1 second minimum between requests
- Debounce user input

**Other APIs:**
- No strict monitoring needed
- Rely on browser network throttling
- Handle errors gracefully

## Future Improvements

**Nominatim:**
- Implement proper caching layer
- Add retry with exponential backoff
- Better duplicate detection

**MapLibre:**
- Implement marker recycling
- Add heatmap visualization
- Custom marker styles

**Wikipedia:**
- Cache extracts in database
- Batch fetch for seed data
- Handle multiple languages

**General:**
- Add API health monitoring
- Implement circuit breaker pattern
- Better error recovery strategies
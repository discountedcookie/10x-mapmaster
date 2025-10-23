# Place Data Enrichment Strategy

## Problem
Current place embeddings lack semantic diversity because they're generated from minimal Nominatim data (name, type, class, country). Need to enrich with distinguishing characteristics.

## Data Sources Research

### 1. Nominatim API (ALREADY INTEGRATED)
**What we get**: Basic place info + **extratags** (if requested)

**Extratags include**:
- `wikidata`: Q-code for Wikidata entity
- `wikipedia`: Wikipedia article reference
- `year_of_construction`: Build date
- `architect`: Builder/architect name  
- `population`: For cities/regions
- `website`: Official website
- `heritage`: Heritage status
- `wheelchair`: Accessibility info

**Current code**: `src/composables/useNominatim.ts` already fetches from Nominatim
**Missing**: We're NOT requesting `extratags=1` parameter

**Fix**: Add to Nominatim API call:
```typescript
const params = {
  ...existingParams,
  extratags: 1,  // ADD THIS
  namedetails: 1
}
```

### 2. Overpass API (OSM Detailed Queries)
**Use case**: Get rich OSM tags Nominatim might miss

**What it provides**:
- `height`: Building height in meters
- `building:levels`: Number of floors
- `ele`: Elevation above sea level
- `natural`: Natural feature type (volcano, mountain, lake)
- `material`: Construction material (stone, steel, etc.)
- `historic`: Historical period/significance
- `start_date`: Construction start date

**API**: Free, no API key needed
**Rate limit**: Reasonable for our use case
**Query example**:
```
[out:json];
node(48.8584,2.2945);  // Eiffel Tower coords
out tags;
```

**Integration**: Use Overpass as fallback if Nominatim extratags lack height/elevation

### 3. Open-Elevation API
**Use case**: Get elevation for natural features (mountains, etc.)

**What it provides**:
- Elevation in meters for any lat/lng coordinate
- Based on SRTM dataset (global coverage)

**Free options**:
- Open-Elevation: https://api.open-elevation.com/api/v1/lookup
- Open-Meteo: https://api.open-meteo.com/v1/elevation
- OpenTopoData: https://api.opentopodata.org/v1/

**Rate limits**: 
- Open-Meteo: No auth needed, reasonable limits
- OpenTopoData: 100 locations/request, 1/sec, 1000/day

**When to use**: For natural peaks/mountains where OSM lacks `ele` tag

### 4. GeoNames API
**Use case**: Additional metadata (population, timezone, wikipedia)

**What it provides**:
- Population (for cities/landmarks)
- Elevation (srtm3 dataset)
- Wikipedia links
- Timezone
- Administrative hierarchy
- Continent, country, region details

**Limits**: 10,000 credits/day, 1,000/hour (need free account)
**License**: Creative Commons CC 4.0

**When to use**: Backup source if Nominatim/OSM lacks data

## Recommended Enrichment Strategy

### Phase 1: Leverage Existing Nominatim Better
**Immediate fix - no new APIs needed**

1. Update `src/composables/useNominatim.ts` to request extratags
2. Store extratags in `descriptors.extratags` JSONB field
3. Update `scripts/generate-seed-embeddings.ts` to use extratags:

```typescript
function generatePlaceEmbeddingText(place) {
  const parts = [place.name]
  const desc = place.descriptors
  const ext = desc.extratags || {}
  
  // Basic info
  if (desc.type) parts.push(`Type: ${desc.type}`)
  if (desc.class) parts.push(`Category: ${desc.class}`)
  
  // FROM EXTRATAGS
  if (ext.year_of_construction) {
    parts.push(`Built: ${ext.year_of_construction}`)
  }
  if (ext.natural) {
    parts.push(`Natural feature: ${ext.natural}`)
  }
  if (ext.wikipedia) {
    parts.push(`See: ${ext.wikipedia}`)
  }
  
  // Location
  if (desc.address?.city) parts.push(`City: ${desc.address.city}`)
  if (desc.address?.country) parts.push(`Country: ${desc.address.country}`)
  
  return parts.join('. ')
}
```

### Phase 2: Add Height/Elevation Enrichment
**For places missing elevation in Nominatim**

1. Check if place has `extratags.ele` or `extratags.height`
2. If missing AND place is natural feature → call Open-Elevation API
3. If missing AND place is building → try Overpass API for `height` tag
4. Store in `descriptors.height_meters` or `descriptors.elevation_meters`

```typescript
async function enrichWithElevation(place) {
  // Skip if already has elevation
  if (place.descriptors.extratags?.ele) return
  
  // For natural features, use Open-Elevation
  if (place.descriptors.class === 'natural') {
    const response = await fetch(
      `https://api.open-meteo.com/v1/elevation?latitude=${place.lat}&longitude=${place.lng}`
    )
    const data = await response.json()
    place.descriptors.elevation_meters = data.elevation[0]
  }
}
```

### Phase 3: User-Generated Descriptions (BEST FOR DIVERSITY)
**User describes place → update embedding with their description**

1. When user successfully guesses a place, capture their description
2. Append to a `user_descriptions` array in descriptors
3. Regenerate embedding including user descriptions:

```typescript
// descriptors structure:
{
  type: "peak",
  class: "natural",
  extratags: {...},
  user_descriptions: [
    "One of the tallest mountains",
    "Famous volcano in Japan",
    "Snow-capped sacred mountain"
  ]
}

// Embedding text generation:
const textParts = [place.name]
// ... add extratags ...
if (desc.user_descriptions?.length) {
  textParts.push(...desc.user_descriptions)
}
```

**Deduplication strategy**:
- Use `pg_trgm` for fuzzy name matching (trigram similarity)
- Use vector cosine similarity for semantic deduplication
- Cluster similar descriptions using DBSCAN on description embeddings
- Keep top 3-5 most distinctive descriptions per place

## Implementation Priority

### Quick Win (1-2 hours):
✅ Add `extratags=1` to Nominatim calls
✅ Update embedding generation to use extratags
✅ Regenerate embeddings for seed data
✅ Test semantic discrimination improvement

### Medium Term (1 day):
- Add Open-Elevation API calls for missing elevation
- Add Overpass API fallback for building heights
- Store enriched data in descriptors JSONB

### Long Term (ongoing):
- Implement user description capture on successful guesses
- Build description deduplication system
- Implement periodic embedding updates as descriptions accumulate

## Technical Notes

### PostgreSQL Extensions Needed
Already have:
- ✅ `vector` (pgvector) - for embeddings
- ✅ `postgis` - for spatial queries

Could add:
- `pg_trgm` - for fuzzy text matching/deduplication
- `address_standardizer` - for normalizing addresses (maybe overkill)

### Embedding Update Strategy
**When to regenerate embeddings**:
1. When place is first added (required)
2. When elevation/height data is enriched (optional batch update)
3. When user descriptions accumulate (every N descriptions or periodically)

**Avoid**: Regenerating on every single user guess (too expensive)
**Instead**: Queue updates, batch process daily/weekly

### Overpass vs GeoNames vs Open-Elevation
**Use Overpass when**: Need detailed OSM tags (height, levels, material)
**Use GeoNames when**: Need population, admin data, Wikipedia links
**Use Open-Elevation when**: Need elevation for natural features

**Don't**: Call all three for every place (expensive, slow)
**Do**: Use waterfall approach - try Nominatim extratags first, fallback to others only if needed

## Success Metrics
After Phase 1 implementation, semantic questions should show:
- Min similarity < 0.6 (some places don't match)
- Max similarity > 0.7 (some places do match)
- At least 8 of 14 questions should discriminate between places

Target example:
- "Is it very tall?" → Everest (0.85), Fuji (0.78), Burj (0.82) vs Lake Geneva (0.45), Brandenburg Gate (0.48)

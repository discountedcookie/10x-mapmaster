# Semantic Filtering Bug Analysis

## Problem
User describes "One of the tallest mountains" thinking of Mount Fuji. After rejecting Mount Everest by answering NO to semantic questions, game shows "0 places remaining".

## Root Cause
**ALL 14 semantic questions are non-discriminative** - every place has similarity >= 0.734 to every question:

| Question | Min Sim | Max Sim | Result |
|----------|---------|---------|---------|
| Is it in a major city? | 0.774 | 0.834 | ALL match |
| Is it near river/lake? | 0.767 | 0.848 | ALL match |
| Is it near ocean/sea? | 0.766 | 0.798 | ALL match |
| Is it very tall? | 0.738 | 0.785 | ALL match |

When user answers NO to any semantic question, ALL places are excluded because they all match (similarity > 0.4).

## Why This Happens
Place embeddings generated from minimal text:
```
"Mount Fuji. Type: peak. Category: natural. Country: Japan"
"Mount Everest. Type: peak. Category: natural. Country: Nepal"
```

Both are "peak + natural + country" → nearly identical embeddings → no discrimination.

**The gte-small model (384 dimensions) is NOT the problem.** The issue is input text quality, not model capacity.

## Emergency Fix Applied
Migration 000010: Disabled all semantic questions (set `is_active = false`)
- Game now uses ONLY 19 geographic questions (continents, hemispheres, regions)
- Geographic questions work correctly with PostGIS spatial queries

## Solutions for Semantic Diversity

### Option 1: Enrich Place Embedding Input Text (RECOMMENDED)
Use Nominatim extratags + manual data to create richer descriptions:

**Current**: "Mount Fuji. Type: peak. Category: natural. Country: Japan"
**Improved**: "Mount Fuji. Type: peak. Elevation: 3776 meters. Natural feature: volcano. Active stratovolcano, Japan's tallest mountain. Country: Japan"

**Changes needed in `scripts/generate-seed-embeddings.ts`**:
```typescript
const textParts = [place.name]

// Add extratags data
if (descriptors.extratags?.ele) {
  textParts.push(`Elevation: ${descriptors.extratags.ele} meters`)
}
if (descriptors.extratags?.height) {
  textParts.push(`Height: ${descriptors.extratags.height} meters`)
}
if (descriptors.extratags?.natural) {
  textParts.push(`Natural feature: ${descriptors.extratags.natural}`)
}

// Add manual discriminating features if Nominatim lacks them
if (descriptors.height_meters) {
  textParts.push(`Height: ${descriptors.height_meters} meters`)
}
```

### Option 2: Manual Height/Characteristics in Seed Data
If Nominatim extratags don't have enough info, add manually to `000002_seed_data.sql`:

```sql
INSERT INTO places (name, lat, lng, descriptors) VALUES
  ('Mount Fuji', 35.3606, 138.7274, '{
    "type":"peak",
    "class":"natural",
    "country_code":"jp",
    "continent":"asia",
    "height_meters": 3776,
    "natural_type": "volcano",
    "is_active_volcano": true
  }'::jsonb),
  ('Burj Khalifa', 25.1972, 55.2744, '{
    "type":"tower",
    "class":"tourism",
    "country_code":"ae",
    "continent":"asia",
    "height_meters": 828,
    "building_type": "skyscraper",
    "construction_year": 2010
  }'::jsonb)
```

### Option 3: Use User-Submitted Descriptions
When users add places via Nominatim, let them provide a 1-2 sentence description. Generate embeddings from that natural language description instead of structured fields.

## Model Size Question
**Using larger embeddings (768, 1024 dims) won't help.** The problem isn't model capacity - it's that we're feeding it identical input text. A larger model given "peak, natural, Japan" vs "peak, natural, Nepal" will still produce similar embeddings.

**Key insight**: Semantic similarity models are designed to recognize that "Mount Fuji" and "Mount Everest" ARE semantically similar (both are tall natural mountains). The only way to discriminate them is to add distinguishing features in the input text (height: 3776m vs 8849m).

## Next Steps
1. Update seed data to include height/elevation for all places
2. Modify `generate-seed-embeddings.ts` to use richer text
3. Regenerate embeddings with `npm run generate:seed-migration`
4. Test discrimination: places should now have varying similarities (min < 0.6, max > 0.8)
5. Re-enable useful semantic questions that now discriminate
6. Lower threshold back to 0.4-0.5

## Success Criteria
After fix, "Is it very tall?" should have:
- High similarity (>0.6): Mount Everest (8849m), Burj Khalifa (828m), Mount Fuji (3776m)
- Low similarity (<0.5): Lake Geneva, Brandenburg Gate, Colosseum

This creates actual discrimination where answering NO excludes tall places but keeps shorter ones.

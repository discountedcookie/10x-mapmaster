#!/usr/bin/env tsx

import { writeFileSync } from 'node:fs'
import { join } from 'node:path'

/**
 * Generate geographic regions seed data from Natural Earth GeoJSON
 *
 * This script:
 * 1. Fetches country data from martynafford/natural-earth-geojson
 * 2. Derives continents from country data
 * 3. Generates PostgreSQL INSERT statements with PostGIS geometries
 *
 * Source: https://github.com/martynafford/natural-earth-geojson
 *
 * Usage:
 *   bun run scripts/generate-geographic-regions.ts
 */

const OUTPUT_FILE = join(process.cwd(), 'supabase', 'seeds', '02_geographic_regions.sql')
const COUNTRIES_URL =
  'https://raw.githubusercontent.com/martynafford/natural-earth-geojson/master/50m/cultural/ne_50m_admin_0_countries.json'

function geometryToWKT(geometry: any): string {
  if (geometry.type === 'MultiPolygon') {
    const polygons = geometry.coordinates
      .map((polygon: any) => {
        const rings = polygon
          .map((ring: any) => `(${ring.map((coord: any) => `${coord[0]} ${coord[1]}`).join(', ')})`)
          .join(', ')
        return `(${rings})`
      })
      .join(', ')
    return `MULTIPOLYGON(${polygons})`
  } else if (geometry.type === 'Polygon') {
    const coords = geometry.coordinates
      .map((ring: any) => `(${ring.map((coord: any) => `${coord[0]} ${coord[1]}`).join(', ')})`)
      .join(', ')
    return `POLYGON(${coords})`
  }
  throw new Error(`Unsupported geometry type: ${geometry.type}`)
}

function escapeSql(string_: string): string {
  return string_.split("'").join("''")
}

async function main() {
  console.log('🌍 Generating geographic regions from Natural Earth GeoJSON...\n')

  try {
    // Fetch countries data
    console.log('📥 Fetching countries from Natural Earth...')
    const response = await fetch(COUNTRIES_URL)
    if (!response.ok) {
      throw new Error(`Failed to fetch: ${response.statusText}`)
    }

    const countriesGeoJSON = await response.json()
    console.log(`✓ Loaded ${countriesGeoJSON.features.length} countries`)

    // Group countries by continent
    console.log('\n🌐 Processing continents and countries...')
    const continentFeatures = new Map<string, any[]>()
    const countryFeatures = new Map<string, any[]>()

    for (const feature of countriesGeoJSON.features) {
      const continent = feature.properties.CONTINENT
      const name = feature.properties.NAME
      const iso = feature.properties.ISO_A2 || feature.properties.ADM0_A3

      if (!continent || !name) continue

      // Group countries by continent
      if (!countryFeatures.has(continent)) {
        countryFeatures.set(continent, [])
      }
      countryFeatures.get(continent)!.push({
        name,
        iso,
        geometry: feature.geometry,
      })

      // Collect geometries for continent unions
      if (!continentFeatures.has(continent)) {
        continentFeatures.set(continent, [])
      }
      continentFeatures.get(continent)!.push(feature.geometry)
    }

    console.log(`Found ${continentFeatures.size} continents`)
    console.log(`Found ${countriesGeoJSON.features.length} countries`)

    // Generate SQL
    console.log('\n📝 Generating SQL...')
    let sql = `-- ============================================================================
-- Geographic Regions Seed Data
-- ============================================================================
-- Generated from Natural Earth GeoJSON (50m scale)
-- Source: https://github.com/martynafford/natural-earth-geojson
-- Generated: ${new Date().toISOString()}
-- prettier-ignore
-- ============================================================================

-- Insert continents (union all country geometries for accurate boundaries)
`

    // Generate continent inserts with ST_Union of all country geometries
    for (const [continentName, geometries] of continentFeatures) {
      const escapedName = escapeSql(continentName)

      // Generate WKT for all geometries in this continent
      const geometryWKTs = geometries.map((geom) => geometryToWKT(geom))

      // Use ST_Union to merge all country geometries into continent geometry
      // ST_Collect creates a geometry collection, ST_Union merges overlaps
      const geomCollection = geometryWKTs
        .map((wkt, index) => `    ST_GeomFromText('${escapeSql(wkt)}', 4326)`)
        .join(',\n')

      sql += `INSERT INTO geographic_regions (name, level, geom, continent_id, iso_code)
SELECT '${escapedName}', 'continent', 
  ST_Multi(ST_Union(ARRAY[
${geomCollection}
  ])), NULL, NULL;\n\n`
    }

    sql += `\n`

    // Insert countries - generate individual INSERT statements to avoid Prettier issues
    sql += `\n-- Insert countries\n`

    for (const [continent, countries] of countryFeatures) {
      for (const country of countries) {
        const wkt = geometryToWKT(country.geometry)
        const escapedName = escapeSql(country.name)
        const escapedContinent = escapeSql(continent)
        const escapedWkt = escapeSql(wkt)

        sql += `INSERT INTO geographic_regions (name, level, geom, continent_id, iso_code) SELECT '${escapedName}', 'country', ST_Multi(ST_GeomFromText('${escapedWkt}', 4326)), id, '${country.iso}' FROM geographic_regions WHERE level = 'continent' AND name = '${escapedContinent}';\n`
      }
    }

    // Write to file
    writeFileSync(OUTPUT_FILE, sql, 'utf-8')
    console.log(`✓ Generated: ${OUTPUT_FILE}`)

    console.log('\n✅ Geographic regions seed data generated successfully!')
    console.log(`   - ${continentFeatures.size} continents`)
    console.log(`   - ${countriesGeoJSON.features.length} countries`)
    console.log('\nNext steps:')
    console.log('1. Review the generated SQL file')
    console.log('2. Run: bun run db:rebuild')
    console.log('3. Verify: SELECT level, COUNT(*) FROM geographic_regions GROUP BY level;')
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : String(error))
    process.exit(1)
  }
}

main()

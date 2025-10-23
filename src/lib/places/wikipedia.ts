/**
 * Wikipedia API client for fetching place summaries
 * Uses the dopecodez/wikipedia package
 */

import wiki from 'wikipedia'

/**
 * Get Wikipedia summary from Wikidata ID
 * Uses extratags.wikidata from Nominatim
 * Always fetches English Wikipedia for consistent embeddings
 */
export async function getWikipediaSummary(
  wikidata_id: string
): Promise<string | null> {
  // Extract Q-code (e.g., 'Q243' from 'wikidata:Q243')
  const qcode = wikidata_id.replace(/^wikidata:/, '')

  // Force English Wikipedia for embeddings
  wiki.setLang('en')

  // Search for the Wikidata item
  const searchResults = await wiki.search(qcode, { limit: 1 })
  if (!searchResults.results || searchResults.results.length === 0) {
    return null
  }

  const title = searchResults.results[0].title
  const summary = await wiki.summary(title)

  // Return extract (plain text summary)
  return summary.extract || null
}

/**
 * Get Wikipedia summary from article title
 * Always uses English Wikipedia for consistent embeddings
 */
export async function getWikipediaSummaryByTitle(
  title: string
): Promise<string | null> {
  // Force English Wikipedia for embeddings
  wiki.setLang('en')

  const summary = await wiki.summary(title, { autoSuggest: true })
  return summary.extract || null
}

/**
 * Enrich place with Wikipedia summary
 * Only fetches if wikidata or wikipedia identifier exists
 * Always fetches English Wikipedia for consistent embeddings
 */
export async function enrichWithWikipedia(
  placeName: string,
  extratags: Record<string, any>
): Promise<string | null> {
  // Always use English Wikipedia for embeddings
  wiki.setLang('en')

  // Try Wikidata ID first (most reliable)
  if (extratags.wikidata) {
    const summary = await getWikipediaSummary(extratags.wikidata)
    if (summary) return summary
  }

  // Try Wikipedia tag as fallback
  // Nominatim may provide localized titles (e.g., 'el:Ακρόπολη Αθηνών')
  // but we'll search English Wikipedia using the place name instead
  if (extratags.wikipedia) {
    // Try searching English Wikipedia with the place name
    const summary = await getWikipediaSummaryByTitle(placeName)
    if (summary) return summary
  }

  // No identifier found - return null
  return null
}

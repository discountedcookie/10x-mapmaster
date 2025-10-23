import { describe, expect, it } from 'vitest'
import { generatePlaceEmbeddingText } from '@/lib/places'

describe('generatePlaceEmbeddingText', () => {
    it('should include place name and basic descriptors', () => {
        const text = generatePlaceEmbeddingText({
            name: 'Eiffel Tower',
            descriptors: {
                type: 'tower',
                class: 'tourism',
                elevation_meters: 30,
                height_meters: 330,
                address: {
                    city: 'Paris',
                    country: 'France',
                },
                country_code: 'fr',
                extratags: {},
            },
        })

        expect(text).toContain('Eiffel Tower')
        expect(text).toContain('Elevation: 30 meters')
        expect(text).toContain('Height: 330 meters')
        expect(text).toContain('Type: tower')
        expect(text).toContain('Category: tourism')
        expect(text).toContain('City: Paris')
        expect(text).toContain('Country: France')
    })

    it('should filter out non-Latin city names and use country code', () => {
        const text = generatePlaceEmbeddingText({
            name: 'Acropolis',
            descriptors: {
                type: 'attraction',
                class: 'tourism',
                address: {
                    city: 'Αθήνα', // Athens in Greek
                    country: 'Ελλάς', // Greece in Greek
                },
                country_code: 'gr',
                extratags: {},
            },
        })

        expect(text).toContain('Acropolis')
        expect(text).not.toContain('Αθήνα') // Greek characters filtered
        expect(text).not.toContain('Ελλάς') // Greek characters filtered
        expect(text).toContain('Country code: GR') // Fallback to country code
    })

    it('should prefer name:en from extratags over localized names', () => {
        const text = generatePlaceEmbeddingText({
            name: 'Great Wall',
            descriptors: {
                type: 'attraction',
                class: 'historic',
                address: {
                    city: '北京', // Beijing in Chinese
                    country: '中国', // China in Chinese
                },
                country_code: 'cn',
                extratags: {
                    'name:en': 'Beijing', // English name in extratags
                },
            },
        })

        expect(text).toContain('City: Beijing') // English from extratags
        expect(text).not.toContain('北京') // Chinese filtered
        expect(text).toContain('Country code: CN') // Fallback to country code
    })

    it('should include Wikipedia summary in English', () => {
        const text = generatePlaceEmbeddingText({
            name: 'Eiffel Tower',
            descriptors: {
                type: 'tower',
                class: 'tourism',
                address: {},
                extratags: {},
            },
            wikipedia_summary:
                'The Eiffel Tower is a wrought-iron lattice tower on the Champ de Mars in Paris, France. It is named after the engineer Gustave Eiffel, whose company designed and built the tower.',
        })

        expect(text).toContain('Eiffel Tower')
        expect(text).toContain('The Eiffel Tower is a wrought-iron lattice tower')
        expect(text).toContain('engineer Gustave Eiffel')
    })

    it('should truncate long Wikipedia summaries to 200 chars', () => {
        const longSummary = 'A'.repeat(300)
        const text = generatePlaceEmbeddingText({
            name: 'Test Place',
            descriptors: {
                address: {},
                extratags: {},
            },
            wikipedia_summary: longSummary,
        })

        expect(text).toContain('A'.repeat(200))
        expect(text).not.toContain('A'.repeat(201))
    })

    it('should include extratags metadata', () => {
        const text = generatePlaceEmbeddingText({
            name: 'Mount Everest',
            descriptors: {
                extratags: {
                    natural: 'peak',
                    year_of_construction: '1889',
                    architect: 'Gustave Eiffel',
                    building: 'tower',
                },
                address: {},
            },
        })

        expect(text).toContain('Natural feature: peak')
        expect(text).toContain('Built: 1889')
        expect(text).toContain('Architect: Gustave Eiffel')
        expect(text).toContain('Building type: tower')
    })

    it('should handle missing fields gracefully', () => {
        const text = generatePlaceEmbeddingText({
            name: 'Simple Place',
            descriptors: {
                address: {},
                extratags: {},
            },
        })

        expect(text).toBe('Simple Place')
    })

    it('should allow Latin extended characters (accents, diacritics)', () => {
        const text = generatePlaceEmbeddingText({
            name: 'Château',
            descriptors: {
                address: {
                    city: 'Málaga',
                    country: 'España',
                },
                country_code: 'es',
                extratags: {},
            },
        })

        expect(text).toContain('City: Málaga') // Spanish accents allowed
        expect(text).toContain('Country: España') // ñ allowed
    })
})





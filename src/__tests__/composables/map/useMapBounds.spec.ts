import { describe, expect, it } from 'vitest'
import { computed, ref } from 'vue'
import { useMapBounds, type Marker } from '@/composables/map/useMapBounds'

describe('useMapBounds', () => {
  describe('Empty Markers', () => {
    it('should return undefined when no markers', () => {
      const markers = computed<Marker[]>(() => [])
      const bounds = useMapBounds(markers)

      expect(bounds.value).toBeUndefined()
    })
  })

  describe('Single Marker', () => {
    it('should calculate bounds for a single marker with default padding', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [2.3522, 48.8566] }, // Paris (lng, lat)
      ])
      const bounds = useMapBounds(markers)

      expect(bounds.value).toBeDefined()
      expect(bounds.value).toHaveLength(2)

      // With 0 range, padding calculation results in 0 * 0.15 = 0
      // So a single marker results in a point (min == max)
      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!
      expect(minLng).toBe(2.3522)
      expect(maxLng).toBe(2.3522)
      expect(minLat).toBe(48.8566)
      expect(maxLat).toBe(48.8566)
    })

    it('should handle custom padding for single marker', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, 0] },
      ])
      const bounds = useMapBounds(markers, 0.5) // 50% padding

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // With 50% padding on 0 range, still results in 0 * 0.5 = 0
      expect(minLng).toBe(0)
      expect(maxLng).toBe(0)
      expect(minLat).toBe(0)
      expect(maxLat).toBe(0)
    })
  })

  describe('Multiple Markers', () => {
    it('should calculate bounds for multiple markers', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [2.3522, 48.8566] }, // Paris
        { coordinates: [-0.1276, 51.5074] }, // London
        { coordinates: [13.4050, 52.5200] }, // Berlin
      ])
      const bounds = useMapBounds(markers)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Should encompass all markers
      expect(minLng).toBeLessThan(-0.1276) // West of London
      expect(maxLng).toBeGreaterThan(13.4050) // East of Berlin
      expect(minLat).toBeLessThan(48.8566) // South of Paris
      expect(maxLat).toBeGreaterThan(52.5200) // North of Berlin
    })

    it('should calculate bounds with no padding', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, 0] },
        { coordinates: [10, 10] },
      ])
      const bounds = useMapBounds(markers, 0) // No padding

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Should be exact bounds without padding
      expect(minLng).toBe(0)
      expect(maxLng).toBe(10)
      expect(minLat).toBe(0)
      expect(maxLat).toBe(10)
    })

    it('should calculate bounds with 15% default padding', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, 0] },
        { coordinates: [10, 10] },
      ])
      const bounds = useMapBounds(markers) // Default 15% padding

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Range is 10, so padding should be 1.5 on each side
      expect(minLng).toBeCloseTo(-1.5, 10)
      expect(maxLng).toBeCloseTo(11.5, 10)
      expect(minLat).toBeCloseTo(-1.5, 10)
      expect(maxLat).toBeCloseTo(11.5, 10)
    })

    it('should calculate bounds with custom padding', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, 0] },
        { coordinates: [100, 100] },
      ])
      const bounds = useMapBounds(markers, 0.25) // 25% padding

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Range is 100, so padding should be 25 on each side
      expect(minLng).toBeCloseTo(-25, 10)
      expect(maxLng).toBeCloseTo(125, 10)
      expect(minLat).toBeCloseTo(-25, 10)
      expect(maxLat).toBeCloseTo(125, 10)
    })
  })

  describe('Edge Cases', () => {
    it('should handle markers on same longitude', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, 0] },
        { coordinates: [0, 10] },
      ])
      const bounds = useMapBounds(markers, 0.1)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Longitude padding should still work even with 0 range
      expect(minLng).toBeLessThanOrEqual(0)
      expect(maxLng).toBeGreaterThanOrEqual(0)
      expect(minLat).toBeCloseTo(-1, 10) // 10 * 0.1 = 1
      expect(maxLat).toBeCloseTo(11, 10)
    })

    it('should handle markers on same latitude', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, 0] },
        { coordinates: [10, 0] },
      ])
      const bounds = useMapBounds(markers, 0.1)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      expect(minLng).toBeCloseTo(-1, 10)
      expect(maxLng).toBeCloseTo(11, 10)
      // Latitude padding should still work even with 0 range
      expect(minLat).toBeLessThanOrEqual(0)
      expect(maxLat).toBeGreaterThanOrEqual(0)
    })

    it('should handle negative coordinates', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [-10, -10] },
        { coordinates: [-5, -5] },
      ])
      const bounds = useMapBounds(markers, 0.1)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Range is 5, padding is 0.5
      expect(minLng).toBeCloseTo(-10.5, 10)
      expect(maxLng).toBeCloseTo(-4.5, 10)
      expect(minLat).toBeCloseTo(-10.5, 10)
      expect(maxLat).toBeCloseTo(-4.5, 10)
    })

    it('should handle markers crossing the equator', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, -10] },
        { coordinates: [0, 10] },
      ])
      const bounds = useMapBounds(markers, 0.1)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Range is 20, padding is 2
      expect(minLat).toBeCloseTo(-12, 10)
      expect(maxLat).toBeCloseTo(12, 10)
    })

    it('should handle markers crossing the prime meridian', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [-10, 0] },
        { coordinates: [10, 0] },
      ])
      const bounds = useMapBounds(markers, 0.1)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Range is 20, padding is 2
      expect(minLng).toBeCloseTo(-12, 10)
      expect(maxLng).toBeCloseTo(12, 10)
    })

    it('should handle very small coordinate ranges', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, 0] },
        { coordinates: [0.001, 0.001] },
      ])
      const bounds = useMapBounds(markers, 0.15)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Should still calculate valid bounds
      expect(minLng).toBeLessThan(0)
      expect(maxLng).toBeGreaterThan(0.001)
      expect(minLat).toBeLessThan(0)
      expect(maxLat).toBeGreaterThan(0.001)
    })

    it('should handle very large coordinate ranges', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [-180, -90] },
        { coordinates: [180, 90] },
      ])
      const bounds = useMapBounds(markers, 0.1)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Should handle extreme values
      expect(minLng).toBeLessThan(-180)
      expect(maxLng).toBeGreaterThan(180)
      expect(minLat).toBeLessThan(-90)
      expect(maxLat).toBeGreaterThan(90)
    })
  })

  describe('Reactivity', () => {
    it('should update bounds when markers change', () => {
      const markerList = ref<Marker[]>([{ coordinates: [0, 0] }])
      const markers = computed(() => markerList.value)
      const bounds = useMapBounds(markers, 0)

      let [[minLng, minLat], [maxLng, maxLat]] = bounds.value!
      expect(minLng).toBe(0)
      expect(maxLng).toBe(0)

      // Add another marker - reassign array to trigger reactivity
      markerList.value = [...markerList.value, { coordinates: [10, 10] }]

      ;[[minLng, minLat], [maxLng, maxLat]] = bounds.value!
      expect(minLng).toBe(0)
      expect(maxLng).toBe(10)
      expect(minLat).toBe(0)
      expect(maxLat).toBe(10)
    })

    it('should return undefined when markers become empty', () => {
      const markerList = ref<Marker[]>([{ coordinates: [0, 0] }])
      const markers = computed(() => markerList.value)
      const bounds = useMapBounds(markers)

      expect(bounds.value).toBeDefined()

      // Remove all markers
      markerList.value = []

      expect(bounds.value).toBeUndefined()
    })
  })

  describe('Marker Object Structure', () => {
    it('should handle markers with additional properties', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, 0], id: '1', name: 'Place A' },
        { coordinates: [10, 10], id: '2', name: 'Place B', metadata: {} },
      ])
      const bounds = useMapBounds(markers, 0)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      expect(minLng).toBe(0)
      expect(maxLng).toBe(10)
      expect(minLat).toBe(0)
      expect(maxLat).toBe(10)
    })
  })

  describe('Padding Calculations', () => {
    it('should apply padding symmetrically', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [5, 5] },
        { coordinates: [15, 15] },
      ])
      const bounds = useMapBounds(markers, 0.2) // 20% padding

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Range is 10, padding is 2
      const lngPadding = 15 - maxLng
      const latPadding = 15 - maxLat

      // Padding should be equal on both sides
      expect(minLng - 5).toBeCloseTo(lngPadding, 10)
      expect(minLat - 5).toBeCloseTo(latPadding, 10)
    })

    it('should handle 100% padding', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, 0] },
        { coordinates: [10, 10] },
      ])
      const bounds = useMapBounds(markers, 1.0) // 100% padding

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Range is 10, padding should be 10 on each side
      expect(minLng).toBeCloseTo(-10, 10)
      expect(maxLng).toBeCloseTo(20, 10)
      expect(minLat).toBeCloseTo(-10, 10)
      expect(maxLat).toBeCloseTo(20, 10)
    })

    it('should handle very small padding', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, 0] },
        { coordinates: [100, 100] },
      ])
      const bounds = useMapBounds(markers, 0.01) // 1% padding

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Range is 100, padding should be 1 on each side
      expect(minLng).toBeCloseTo(-1, 10)
      expect(maxLng).toBeCloseTo(101, 10)
      expect(minLat).toBeCloseTo(-1, 10)
      expect(maxLat).toBeCloseTo(101, 10)
    })
  })

  describe('Real World Scenarios', () => {
    it('should calculate bounds for European cities', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [2.3522, 48.8566] }, // Paris
        { coordinates: [-0.1276, 51.5074] }, // London
        { coordinates: [13.4050, 52.5200] }, // Berlin
        { coordinates: [12.4964, 41.9028] }, // Rome
        { coordinates: [-3.7038, 40.4168] }, // Madrid
      ])
      const bounds = useMapBounds(markers, 0.1)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Should create a bounding box around Europe
      expect(minLng).toBeLessThan(-3.7038) // West of Madrid
      expect(maxLng).toBeGreaterThan(13.4050) // East of Berlin
      expect(minLat).toBeLessThan(40.4168) // South of Madrid
      expect(maxLat).toBeGreaterThan(52.5200) // North of Berlin

      // Verify it's a reasonable size
      const lngRange = maxLng - minLng
      const latRange = maxLat - minLat
      expect(lngRange).toBeGreaterThan(15)
      expect(latRange).toBeGreaterThan(10)
    })

    it('should handle global marker distribution', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [-74.0060, 40.7128] }, // New York
        { coordinates: [139.6917, 35.6895] }, // Tokyo
        { coordinates: [151.2093, -33.8688] }, // Sydney
        { coordinates: [-43.1729, -22.9068] }, // Rio de Janeiro
      ])
      const bounds = useMapBounds(markers, 0.05)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Should span a large portion of the globe
      const lngRange = maxLng - minLng
      const latRange = maxLat - minLat

      expect(lngRange).toBeGreaterThan(100)
      expect(latRange).toBeGreaterThan(50)
    })
  })
})

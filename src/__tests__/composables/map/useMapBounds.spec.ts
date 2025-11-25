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
    it('should calculate bounds for a single marker with minimum padding', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [2.3522, 48.8566] }, // Paris (lng, lat)
      ])
      const bounds = useMapBounds(markers)

      expect(bounds.value).toBeDefined()
      expect(bounds.value).toHaveLength(2)

      // Single marker uses minimum padding of 0.5 degrees
      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!
      expect(minLng).toBeCloseTo(2.3522 - 0.5, 10)
      expect(maxLng).toBeCloseTo(2.3522 + 0.5, 10)
      expect(minLat).toBeCloseTo(48.8566 - 0.5, 10)
      expect(maxLat).toBeCloseTo(48.8566 + 0.5, 10)
    })

    it('should use minimum padding even with custom padding parameter', () => {
      const markers = computed<Marker[]>(() => [{ coordinates: [0, 0] }])
      const bounds = useMapBounds(markers, 0.5) // 50% padding (but min padding applies)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Single marker uses minimum padding of 0.5 degrees
      expect(minLng).toBeCloseTo(-0.5, 10)
      expect(maxLng).toBeCloseTo(0.5, 10)
      expect(minLat).toBeCloseTo(-0.5, 10)
      expect(maxLat).toBeCloseTo(0.5, 10)
    })
  })

  describe('Multiple Markers', () => {
    it('should calculate bounds for multiple markers', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [2.3522, 48.8566] }, // Paris
        { coordinates: [-0.1276, 51.5074] }, // London
        { coordinates: [13.405, 52.52] }, // Berlin
      ])
      const bounds = useMapBounds(markers)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Should encompass all markers
      expect(minLng).toBeLessThan(-0.1276) // West of London
      expect(maxLng).toBeGreaterThan(13.405) // East of Berlin
      expect(minLat).toBeLessThan(48.8566) // South of Paris
      expect(maxLat).toBeGreaterThan(52.52) // North of Berlin
    })

    it('should calculate bounds with no padding parameter but minimum padding applies', () => {
      const markers = computed<Marker[]>(() => [{ coordinates: [0, 0] }, { coordinates: [10, 10] }])
      const bounds = useMapBounds(markers, 0) // 0% padding, but minimum 0.05 applies

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Minimum padding of 0.05 applies even with 0 padding parameter
      expect(minLng).toBeCloseTo(-0.05, 10)
      expect(maxLng).toBeCloseTo(10.05, 10)
      expect(minLat).toBeCloseTo(-0.05, 10)
      expect(maxLat).toBeCloseTo(10.05, 10)
    })
  })

  describe('Edge Cases', () => {
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
  })

  describe('Reactivity', () => {
    it('should update bounds when markers change', () => {
      const markerList = ref<Marker[]>([{ coordinates: [0, 0] }])
      const markers = computed(() => markerList.value)
      const bounds = useMapBounds(markers, 0)

      let [[minLng, minLat], [maxLng, maxLat]] = bounds.value!
      // Single marker has minimum padding of 0.5
      expect(minLng).toBeCloseTo(-0.5, 10)
      expect(maxLng).toBeCloseTo(0.5, 10)

      // Add another marker - reassign array to trigger reactivity
      markerList.value = [...markerList.value, { coordinates: [10, 10] }]
      ;[[minLng, minLat], [maxLng, maxLat]] = bounds.value!
      // Multiple markers have minimum padding of 0.05
      expect(minLng).toBeCloseTo(-0.05, 10)
      expect(maxLng).toBeCloseTo(10.05, 10)
      expect(minLat).toBeCloseTo(-0.05, 10)
      expect(maxLat).toBeCloseTo(10.05, 10)
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

      // Minimum padding of 0.05 applies
      expect(minLng).toBeCloseTo(-0.05, 10)
      expect(maxLng).toBeCloseTo(10.05, 10)
      expect(minLat).toBeCloseTo(-0.05, 10)
      expect(maxLat).toBeCloseTo(10.05, 10)
    })
  })

  describe('Padding Calculations', () => {
    it('should apply padding symmetrically', () => {
      const markers = computed<Marker[]>(() => [{ coordinates: [5, 5] }, { coordinates: [15, 15] }])
      const bounds = useMapBounds(markers, 0.2) // 20% padding

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Range is 10, padding is 2
      const lngPadding = 15 - maxLng
      const latPadding = 15 - maxLat

      // Padding should be equal on both sides
      expect(minLng - 5).toBeCloseTo(lngPadding, 10)
      expect(minLat - 5).toBeCloseTo(latPadding, 10)
    })
  })

  describe('Minimum Padding', () => {
    it('should apply minimum padding of 0.5 degrees for single marker', () => {
      const markers = computed<Marker[]>(() => [{ coordinates: [10, 20] }])
      const bounds = useMapBounds(markers)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Single marker should have 0.5 degree padding
      expect(minLng).toBeCloseTo(9.5, 10)
      expect(maxLng).toBeCloseTo(10.5, 10)
      expect(minLat).toBeCloseTo(19.5, 10)
      expect(maxLat).toBeCloseTo(20.5, 10)
    })

    it('should apply minimum padding of 0.05 degrees for small clusters', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [0, 0] },
        { coordinates: [0.001, 0.001] }, // Very close markers
      ])
      const bounds = useMapBounds(markers)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Small cluster should have at least 0.05 degree padding
      const lngPadding = Math.min(minLng - 0, 0.001 - maxLng)
      const latPadding = Math.min(minLat - 0, 0.001 - maxLat)

      expect(Math.abs(lngPadding)).toBeGreaterThanOrEqual(0.05)
      expect(Math.abs(latPadding)).toBeGreaterThanOrEqual(0.05)
    })

    it('should use calculated padding when larger than minimum', () => {
      const markers = computed<Marker[]>(() => [{ coordinates: [0, 0] }, { coordinates: [10, 10] }])
      const bounds = useMapBounds(markers) // 15% of 10 = 1.5 > 0.05 minimum

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Should use calculated padding (1.5) not minimum (0.05)
      expect(minLng).toBeCloseTo(-1.5, 10)
      expect(maxLng).toBeCloseTo(11.5, 10)
      expect(minLat).toBeCloseTo(-1.5, 10)
      expect(maxLat).toBeCloseTo(11.5, 10)
    })
  })

  describe('Real World Scenarios', () => {
    it('should calculate bounds for European cities', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [2.3522, 48.8566] }, // Paris
        { coordinates: [-0.1276, 51.5074] }, // London
        { coordinates: [13.405, 52.52] }, // Berlin
        { coordinates: [12.4964, 41.9028] }, // Rome
        { coordinates: [-3.7038, 40.4168] }, // Madrid
      ])
      const bounds = useMapBounds(markers, 0.1)

      const [[minLng, minLat], [maxLng, maxLat]] = bounds.value!

      // Should create a bounding box around Europe
      expect(minLng).toBeLessThan(-3.7038) // West of Madrid
      expect(maxLng).toBeGreaterThan(13.405) // East of Berlin
      expect(minLat).toBeLessThan(40.4168) // South of Madrid
      expect(maxLat).toBeGreaterThan(52.52) // North of Berlin

      // Verify it's a reasonable size
      const lngRange = maxLng - minLng
      const latRange = maxLat - minLat
      expect(lngRange).toBeGreaterThan(15)
      expect(latRange).toBeGreaterThan(10)
    })

    it('should handle global marker distribution', () => {
      const markers = computed<Marker[]>(() => [
        { coordinates: [-74.006, 40.7128] }, // New York
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

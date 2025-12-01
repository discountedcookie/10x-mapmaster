/**
 * Shared map utilities for camera and bounds calculations
 */

export interface Coordinates {
  lng: number
  lat: number
}

export interface Bounds {
  min: [number, number]
  max: [number, number]
}

/**
 * Calculate bounding box from array of coordinates
 * Returns [[minLng, minLat], [maxLng, maxLat]]
 */
export function calculateBounds(coords: Coordinates[]): [[number, number], [number, number]] {
  if (coords.length === 0) {
    return [
      [0, 0],
      [0, 0],
    ]
  }

  const lngs = coords.map((c) => c.lng)
  const lats = coords.map((c) => c.lat)

  return [
    [Math.min(...lngs), Math.min(...lats)],
    [Math.max(...lngs), Math.max(...lats)],
  ]
}

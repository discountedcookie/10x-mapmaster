/**
 * Composable for determining if a point is visible on globe projection
 *
 * Uses spherical geometry to check if a point is on the visible hemisphere
 * of the globe based on the current map center. Points with cosAngle > -0.1
 * are considered visible (includes a small buffer beyond the exact hemisphere).
 */

export interface GlobeCoordinates {
  lng: number
  lat: number
}

/**
 * Check if a point is visible on the globe hemisphere
 *
 * @param pointLng - Longitude of the point to check
 * @param pointLat - Latitude of the point to check
 * @param centerLng - Longitude of the globe center (map center)
 * @param centerLat - Latitude of the globe center (map center)
 * @returns true if the point is visible on the current hemisphere
 */
export function isVisibleOnGlobe(
  pointLng: number,
  pointLat: number,
  centerLng: number,
  centerLat: number
): boolean {
  const toRad = (deg: number) => (deg * Math.PI) / 180
  const lat1 = toRad(centerLat)
  const lat2 = toRad(pointLat)
  const dLng = toRad(pointLng - centerLng)
  const cosAngle =
    Math.sin(lat1) * Math.sin(lat2) + Math.cos(lat1) * Math.cos(lat2) * Math.cos(dLng)
  return cosAngle > -0.1
}

/**
 * Composable for globe visibility filtering
 *
 * @returns Object with isVisibleOnGlobe function
 */
export function useGlobeVisibility() {
  return {
    isVisibleOnGlobe,
  }
}

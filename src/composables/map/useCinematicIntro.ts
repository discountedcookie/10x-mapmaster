import type { Map } from 'maplibre-gl'

interface Place {
  lng: number
  lat: number
}

interface CinematicIntroOptions {
  /** Total animation duration in ms (default: 5000) */
  duration?: number
  /** Number of extra 360° rotations to add (default: 1) */
  extraRotations?: number
  /** Starting zoom level - tiny globe (default: 0.2) */
  startZoom?: number
  /** Final zoom level after landing (default: 5) */
  endZoom?: number
  /** Starting latitude (default: 20) */
  startLat?: number
}

/**
 * Easing function: deceleration from the start
 * easeOutCubic - starts fast, slows down smoothly
 */
function easeOutCubic(t: number): number {
  return 1 - Math.pow(1 - t, 3)
}

/**
 * Calculate shortest longitude delta (handles wraparound)
 */
function shortestLngDelta(from: number, to: number): number {
  let delta = to - from
  // Normalize to -180 to 180
  while (delta > 180) delta -= 360
  while (delta < -180) delta += 360
  return delta
}

/**
 * Performs a cinematic intro animation - a flyTo with globe spin.
 *
 * Single smooth animation that:
 * - Starts very zoomed out (tiny globe)
 * - Spins the globe while zooming in
 * - Lands smoothly on the target place
 *
 * @param map - MapLibre map instance
 * @param targetPlace - The place to land on
 * @param options - Animation configuration
 * @returns Promise that resolves when animation completes
 */
export function cinematicIntro(
  map: Map,
  targetPlace: Place,
  options: CinematicIntroOptions = {}
): Promise<void> {
  const {
    duration = 5000,
    extraRotations = 1,
    startZoom = 0.2,
    endZoom = 5,
    startLat = 20,
  } = options

  return new Promise((resolve) => {
    // Starting position: neutral point, very zoomed out
    const startLng = 0

    // Calculate the shortest path to target
    const baseLngDelta = shortestLngDelta(startLng, targetPlace.lng)

    // Add extra rotation in the direction of travel
    const rotationDirection = baseLngDelta >= 0 ? 1 : -1
    const totalLngDelta = baseLngDelta + extraRotations * 360 * rotationDirection

    const latDelta = targetPlace.lat - startLat

    // Set starting position
    map.jumpTo({
      center: [startLng, startLat],
      zoom: startZoom,
      pitch: 0,
      bearing: 0,
    })

    const startTime = performance.now()

    function animate(currentTime: number) {
      const elapsed = currentTime - startTime
      const rawProgress = Math.min(elapsed / duration, 1)

      // Apply easing - decelerate from the start
      const easedProgress = easeOutCubic(rawProgress)

      // Interpolate all values
      const currentZoom = startZoom + (endZoom - startZoom) * easedProgress
      const currentLng = startLng + totalLngDelta * easedProgress
      const currentLat = startLat + latDelta * easedProgress

      // Normalize longitude
      let normalizedLng = currentLng % 360
      if (normalizedLng > 180) normalizedLng -= 360
      if (normalizedLng < -180) normalizedLng += 360

      map.jumpTo({
        center: [normalizedLng, currentLat],
        zoom: currentZoom,
        pitch: 0,
        bearing: 0,
      })

      if (rawProgress < 1) {
        requestAnimationFrame(animate)
      } else {
        // Ensure we land exactly on target
        map.jumpTo({
          center: [targetPlace.lng, targetPlace.lat],
          zoom: endZoom,
          pitch: 0,
          bearing: 0,
        })
        resolve()
      }
    }

    requestAnimationFrame(animate)
  })
}

import { watch } from 'vue'
import type { Ref } from 'vue'

interface UseZoomPitchCorrelationOptions {
  /** Zoom level ref to watch */
  zoom: Ref<number>
  /** Callback to set pitch when zoom changes */
  onPitchChange: (pitch: number) => void
  /** Minimum zoom for pitch calculation (default: 2) */
  minZoom?: number
  /** Maximum zoom for pitch calculation (default: 12) */
  maxZoom?: number
  /** Minimum pitch at minZoom (default: 0) */
  minPitch?: number
  /** Maximum pitch at maxZoom (default: 55) */
  maxPitch?: number
}

/**
 * Composable for smooth pitch interpolation based on zoom level.
 *
 * Pitch scales linearly from minPitch at minZoom to maxPitch at maxZoom.
 * Default: 0° pitch at zoom ≤2 (globe view), 55° pitch at zoom ≥12 (close view)
 *
 * Usage:
 * ```ts
 * const camera = useMapCamera()
 * useZoomPitchCorrelation({
 *   zoom: camera.zoom,
 *   onPitchChange: (pitch) => camera.jumpTo({ pitch }),
 * })
 * ```
 */
export function useZoomPitchCorrelation(options: UseZoomPitchCorrelationOptions) {
  const { zoom, onPitchChange, minZoom = 2, maxZoom = 12, minPitch = 0, maxPitch = 55 } = options

  /**
   * Calculate pitch for a given zoom level using linear interpolation.
   * Clamped to [minPitch, maxPitch] range.
   */
  function getPitchForZoom(zoomLevel: number): number {
    // Clamp zoom to [minZoom, maxZoom]
    const t = Math.max(0, Math.min(1, (zoomLevel - minZoom) / (maxZoom - minZoom)))
    // Linear interpolation: pitch = minPitch + t * (maxPitch - minPitch)
    return minPitch + t * (maxPitch - minPitch)
  }

  // Watch zoom changes and update pitch
  watch(
    zoom,
    (newZoom) => {
      const newPitch = getPitchForZoom(newZoom)
      onPitchChange(newPitch)
    },
    { immediate: true }
  )

  return {
    getPitchForZoom,
  }
}

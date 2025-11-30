import { ref, onUnmounted } from 'vue'
import { useMapCamera } from './useMapCamera'
import { cinematicIntro } from './useCinematicIntro'

interface AutoRotationOptions {
  /** Duration of each fly-to animation in ms (default: 6000) */
  flyDuration?: number
  /** Pause between animations in ms (default: 2000) */
  pauseBetween?: number
  /** Zoom level for viewing places (default: 5) */
  viewZoom?: number
}

interface Place {
  lng: number
  lat: number
}

/**
 * Composable for automatic camera drift between places.
 *
 * Flies to random places from a provided list.
 * Views explicitly control when to start/stop/pause.
 *
 * Usage:
 * ```ts
 * const rotation = useAutoRotation()
 * rotation.setPlaces(places)
 * rotation.start('initial')    // Cinematic intro for fresh page load
 * rotation.start('transition') // Smooth transition from another view
 * rotation.pause()             // Pause on user interaction
 * rotation.resume()            // Resume and fly to next place
 * rotation.stop()              // Stop completely
 * ```
 */
export function useAutoRotation(options: AutoRotationOptions = {}) {
  const { flyDuration = 6000, pauseBetween = 2000, viewZoom = 5 } = options

  const camera = useMapCamera({ syncFromMap: true })

  const isPaused = ref(false)
  const isRotating = ref(false)

  let places: Place[] = []
  let currentIndex = 0
  let timeoutId: ReturnType<typeof setTimeout> | null = null
  let isRunning = false

  // Shuffle array using Fisher-Yates
  function shuffleArray<T>(array: T[]): T[] {
    const shuffled = [...array]
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      const temp = shuffled[i]!
      shuffled[i] = shuffled[j]!
      shuffled[j] = temp
    }
    return shuffled
  }

  // Fly to next place
  async function flyToNext() {
    if (!isRunning || isPaused.value || places.length === 0) return

    const place = places[currentIndex]!
    currentIndex = (currentIndex + 1) % places.length

    // Reshuffle when we've visited all places
    if (currentIndex === 0) {
      places = shuffleArray(places)
    }

    isRotating.value = true

    await camera.flyTo({
      center: [place.lng, place.lat],
      zoom: viewZoom,
      pitch: 0,
      bearing: 0,
      duration: flyDuration,
      essential: true,
    })

    isRotating.value = false

    // Schedule next fly-to after pause
    if (isRunning && !isPaused.value) {
      timeoutId = setTimeout(flyToNext, pauseBetween)
    }
  }

  // Set places to visit
  function setPlaces(newPlaces: Place[]) {
    places = shuffleArray(newPlaces.filter((p) => p.lng != null && p.lat != null))
    currentIndex = 0
  }

  // Start rotation
  // - 'initial': Cinematic globe flydown intro for fresh page load
  // - 'transition': Start flying to next place immediately (for view transitions)
  function start(mode: 'initial' | 'transition') {
    if (isRunning || places.length === 0) return

    isRunning = true
    isPaused.value = false

    const place = places[currentIndex]!
    currentIndex = (currentIndex + 1) % places.length

    if (mode === 'initial') {
      // Cinematic intro: spinning globe from above, then fly to place
      const map = camera.map.value
      if (map) {
        cinematicIntro(map, place, {
          duration: 5000,
          extraRotations: 1,
          startZoom: 0.2,
          endZoom: viewZoom,
          startLat: 20,
        }).then(() => {
          // After intro completes, schedule next fly-to
          if (isRunning && !isPaused.value) {
            timeoutId = setTimeout(flyToNext, pauseBetween)
          }
        })
      } else {
        // Fallback if map not ready: just fly to place
        flyToNext()
      }
    } else {
      // Transition mode: Start flying immediately (no initial delay)
      flyToNext()
    }
  }

  // Stop rotation completely
  // Note: We don't call camera.stop() here to avoid interrupting animations
  // from other views during navigation transitions
  function stop() {
    isRunning = false
    isPaused.value = false
    if (timeoutId !== null) {
      clearTimeout(timeoutId)
      timeoutId = null
    }
  }

  // Pause rotation (can be resumed)
  function pause() {
    isPaused.value = true
    if (timeoutId !== null) {
      clearTimeout(timeoutId)
      timeoutId = null
    }
    camera.stop()
  }

  // Resume rotation from pause
  function resume() {
    if (!isRunning) return
    isPaused.value = false
    // Move to next place and continue
    currentIndex = (currentIndex + 1) % places.length
    flyToNext()
  }

  // Setup interaction listeners to pause on user interaction
  function setupInteractionListeners() {
    const map = camera.map.value
    if (!map) return

    const handleInteraction = () => {
      if (isRunning && !isPaused.value) {
        pause()
      }
    }

    map.on('mousedown', handleInteraction)
    map.on('touchstart', handleInteraction)
    map.on('wheel', handleInteraction)

    // Return cleanup function
    return () => {
      map.off('mousedown', handleInteraction)
      map.off('touchstart', handleInteraction)
      map.off('wheel', handleInteraction)
    }
  }

  // Setup interaction listeners when camera loads
  let cleanupListeners: (() => void) | null = null
  if (camera.isLoaded.value) {
    cleanupListeners = setupInteractionListeners() || null
  }

  // Clean up on unmount
  onUnmounted(() => {
    stop()
    cleanupListeners?.()
  })

  return {
    // State (read-only)
    isPaused,
    isRotating,

    // Methods
    setPlaces,
    start,
    stop,
    pause,
    resume,
  }
}

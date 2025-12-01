import { ref, watch, onUnmounted } from 'vue'
import { useMapCamera } from './useMapCamera'
import { cinematicIntro } from './useCinematicIntro'

interface AutoRotationOptions {
  /** Duration of each fly-to animation in ms (default: 6000) */
  flyDuration?: number
  /** Pause between animations in ms (default: 2000) */
  pauseBetween?: number
  /** Zoom level for viewing places (default: 5) */
  viewZoom?: number
  /** Callback fired on EVERY user interaction (even if already paused) */
  onInteraction?: () => void
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
// Shuffle array using Fisher-Yates
function shuffleArray<T>(array: T[]): T[] {
  const shuffled = [...array]
  for (let index = shuffled.length - 1; index > 0; index--) {
    const index_ = Math.floor(Math.random() * (index + 1))
    const temporary = shuffled[index]!
    shuffled[index] = shuffled[index_]!
    shuffled[index_] = temporary
  }
  return shuffled
}

export function useAutoRotation(options: AutoRotationOptions = {}) {
  const { flyDuration = 6000, pauseBetween = 2000, viewZoom = 5, onInteraction } = options

  const camera = useMapCamera({ syncFromMap: true })

  const isPaused = ref(false)
  const isRotating = ref(false)

  let places: Place[] = []
  let currentIndex = 0
  let timeoutId: ReturnType<typeof setTimeout> | undefined
  let isRunning = false
  let introAbortController: AbortController | undefined

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

  // Handle user interaction
  function handleInteraction() {
    // Always notify about interaction (so HomeView can reset its resume timer)
    onInteraction?.()

    // Only pause if running and not already paused
    if (isRunning && !isPaused.value) {
      pause()
    }
  }

  // Set places to visit
  function setPlaces(newPlaces: Place[]) {
    places = shuffleArray(newPlaces.filter((p) => p.lng != undefined && p.lat != undefined))
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
        // Create abort controller for user interruption
        introAbortController = new AbortController()
        cinematicIntro(map, place, {
          duration: 5000,
          extraRotations: 1,
          startZoom: 0.2,
          endZoom: viewZoom,
          startLat: 20,
          signal: introAbortController.signal,
        }).then(() => {
          introAbortController = undefined
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
    if (timeoutId !== undefined) {
      clearTimeout(timeoutId)
      timeoutId = undefined
    }
  }

  // Pause rotation (can be resumed)
  function pause() {
    isPaused.value = true
    if (timeoutId !== undefined) {
      clearTimeout(timeoutId)
      timeoutId = undefined
    }
    // Abort cinematic intro if running
    if (introAbortController) {
      introAbortController.abort()
      introAbortController = undefined
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
  let cleanupListeners: (() => void) | undefined

  // Watch for camera load to set up listeners
  watch(
    () => camera.isLoaded.value,
    (isLoaded) => {
      if (isLoaded && !cleanupListeners) {
        cleanupListeners = setupInteractionListeners()
      }
    },
    { immediate: true }
  )

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

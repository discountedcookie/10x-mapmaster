import { ref, onUnmounted } from 'vue'
import { useMapCamera } from './useMapCamera'

interface PlaceCoords {
  lng: number
  lat: number
}

interface Offset {
  x: number
  y: number
}

interface UsePlacePresentationOptions {
  getPlace: () => PlaceCoords | null
  getOffset?: () => Offset
  interactionMode?: 'full' | 'zoom-only'
  onPanAway?: () => void
  rotationDuration?: number
  panAwayDuration?: number
  panAwayCheckDelay?: number
}

// Pitch interpolation constants
const MIN_ZOOM = 2
const MAX_ZOOM = 12
const MIN_PITCH = 0
const MAX_PITCH = 55

function getPitchForZoom(zoom: number): number {
  const t = Math.max(0, Math.min(1, (zoom - MIN_ZOOM) / (MAX_ZOOM - MIN_ZOOM)))
  return MIN_PITCH + t * (MAX_PITCH - MIN_PITCH)
}

export function usePlacePresentation(options: UsePlacePresentationOptions) {
  const {
    getPlace,
    getOffset = () => ({ x: 0, y: 0 }),
    interactionMode = 'full',
    onPanAway,
    rotationDuration = 30_000,
    panAwayDuration = 500,
    panAwayCheckDelay = 1500,
  } = options

  const camera = useMapCamera({ syncFromMap: true })
  const isRotating = ref(false)

  let animationId: number | undefined
  let startTime: number | undefined
  let isPanning = false
  let isZooming = false
  let checkTimeoutId: ReturnType<typeof setTimeout> | undefined
  let cleanup: (() => void) | undefined

  function startRotation() {
    const place = getPlace()
    const map = camera.map.value
    if (!place || !map || isRotating.value) return

    isRotating.value = true
    startTime = performance.now()

    function animate(now: number) {
      if (!isRotating.value || !camera.map.value) return
      const currentPlace = getPlace()
      if (!currentPlace) return

      const offset = getOffset()
      const bearing = ((now - (startTime || now)) / rotationDuration) * 360

      // Update bearing AND re-center on place with offset
      camera.map.value.setBearing(bearing % 360)
      camera.map.value.flyTo({
        center: [currentPlace.lng, currentPlace.lat],
        offset: [offset.x, offset.y],
        duration: 0,
        zoom: camera.map.value.getZoom(),
      })

      animationId = requestAnimationFrame(animate)
    }

    animationId = requestAnimationFrame(animate)
    setupListeners()
  }

  function stopRotation() {
    isRotating.value = false
    if (animationId) cancelAnimationFrame(animationId)
    animationId = undefined
    startTime = undefined
  }

  // Event handlers (moved to outer scope for consistent-function-scoping)
  const onInteraction = () => {
    if (isRotating.value) stopRotation()
  }

  const onDragStart = () => {
    isPanning = true
  }

  const onDragEnd = () => {
    if (!isPanning) return
    isPanning = false

    if (interactionMode === 'full') {
      camera.easeTo({ pitch: 0, bearing: 0, duration: panAwayDuration })

      if (checkTimeoutId) clearTimeout(checkTimeoutId)
      checkTimeoutId = setTimeout(() => {
        const place = getPlace()
        if (place && !camera.isInBounds(place.lng, place.lat)) {
          onPanAway?.()
        }
      }, panAwayCheckDelay)
    }
  }

  const onZoomStart = () => {
    isZooming = true
  }

  const onZoom = () => {
    // Only apply pitch correlation if we were rotating (place in focus)
    // and user is zooming (not panning)
    if (isZooming && !isPanning) {
      const map = camera.map.value
      if (!map) return
      const currentZoom = map.getZoom()
      const targetPitch = getPitchForZoom(currentZoom)
      // Use easeTo with short duration for smooth feel during gesture
      map.easeTo({ pitch: targetPitch, duration: 100 })
    }
  }

  const onZoomEnd = () => {
    isZooming = false
  }

  function setupListeners() {
    const map = camera.map.value
    if (!map) return

    map.on('mousedown', onInteraction)
    map.on('touchstart', onInteraction)
    map.on('dragstart', onDragStart)
    map.on('dragend', onDragEnd)
    map.on('zoomstart', onZoomStart)
    map.on('zoom', onZoom)
    map.on('zoomend', onZoomEnd)

    cleanup = () => {
      map.off('mousedown', onInteraction)
      map.off('touchstart', onInteraction)
      map.off('dragstart', onDragStart)
      map.off('dragend', onDragEnd)
      map.off('zoomstart', onZoomStart)
      map.off('zoom', onZoom)
      map.off('zoomend', onZoomEnd)
    }
  }

  function stop() {
    stopRotation()
    cleanup?.()
    cleanup = undefined
    if (checkTimeoutId) clearTimeout(checkTimeoutId)
  }

  onUnmounted(stop)

  return { isRotating, startRotation, stopRotation, stop }
}

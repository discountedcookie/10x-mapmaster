<script setup lang="ts">
import { onMounted, onUnmounted, ref, watch } from 'vue'
import maplibregl from 'maplibre-gl'

interface Candidate {
  lat: number
  lng: number
  name: string
  similarity?: number
}

interface Props {
  candidates?: Candidate[]
}

const props = withDefaults(defineProps<Props>(), {
  candidates: () => [],
})

const mapContainer = ref<HTMLElement>()
let map: maplibregl.Map | undefined
// Using any to avoid Json type recursion issues with maplibregl.Marker[]
const markers = ref<any[]>([])

onMounted(() => {
  if (!mapContainer.value)
    return

  map = new maplibregl.Map({
    container: mapContainer.value,
    style: 'https://raw.githubusercontent.com/go2garret/maps/main/src/assets/json/openStreetMap.json',
    center: [0, 20],
    zoom: 3,
  })

  // Add markers if candidates exist
  if (props.candidates.length > 0) {
    updateMarkers()
  }
})

onUnmounted(() => {
  clearMarkers()
  map?.remove()
})

watch(() => props.candidates, () => {
  updateMarkers()
}, { deep: true })

function clearMarkers() {
  for (const marker of markers.value) marker.remove()
  markers.value = []
}

function updateMarkers() {
  if (!map)
    return

  clearMarkers()

  if (props.candidates.length === 0)
    return

  // Add new markers with opacity based on similarity
  for (let i = 0; i < props.candidates.length; i++) {
    const candidate = props.candidates[i]
    if (!candidate) continue

    // Calculate opacity based on confidence (or position if no confidence)
    let opacity = 1
    if (candidate.similarity !== undefined) {
      // Scale confidence (0-1) to opacity (0.4-1.0) for visibility
      opacity = 0.4 + (candidate.similarity * 0.6)
    }
    else if (props.candidates.length > 1) {
      // Fallback: use position (first is most opaque)
      opacity = 1 - (i / props.candidates.length) * 0.5
    }

    const el = document.createElement('div')
    el.className = 'w-6 h-6 bg-red-500 rounded-full border-2 border-white shadow-lg cursor-pointer hover:scale-110 transition-transform'
    el.style.opacity = opacity.toString()
    el.title = candidate.name
    // Add ARIA attributes for accessibility
    el.setAttribute('role', 'button')
    el.setAttribute('aria-label', `View ${candidate.name}${candidate.similarity ? ` - ${Math.round(candidate.similarity * 100)}% match` : ''}`)

    const marker = new maplibregl.Marker({ element: el })
      .setLngLat([candidate.lng, candidate.lat])
      .setPopup(
        new maplibregl.Popup({ offset: 25 })
          .setHTML(`<strong>${candidate.name}</strong>${candidate.similarity ? `<br><span style="font-size: 0.8em;">Match: ${Math.round(candidate.similarity * 100)}%</span>` : ''}`),
      )
      .addTo(map!)

    markers.value.push(marker)
  }

  // Fit map to show all markers
  if (props.candidates.length > 0) {
    const bounds = new maplibregl.LngLatBounds()
    for (const candidate of props.candidates) bounds.extend([candidate.lng, candidate.lat])
    map.fitBounds(bounds, { padding: 100, maxZoom: 10 })
  }
}
</script>

<template>
  <div
    ref="mapContainer"
    class="!absolute inset-0"
  />
</template>

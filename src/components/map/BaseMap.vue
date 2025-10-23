<script setup lang="ts">
import { computed, ref } from 'vue'
import { useTheme } from '@/composables/useTheme'
import { 
  MglMap, 
  MglGeoJsonSource, 
  MglCircleLayer, 
  MglSymbolLayer,
  MglPopup 
} from '@indoorequal/vue-maplibre-gl'

interface Props {
  bounds?: [[number, number], [number, number]]
  center?: [number, number]
  zoom?: number
  placesGeoJson?: any
  isBrowseMode?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  center: () => [0, 20],
  zoom: 3,
  isBrowseMode: false,
})

const { resolvedTheme } = useTheme()
const mapRef = ref()
const showPopup = ref(false)
const popupCoordinates = ref<[number, number]>([0, 0])
const popupName = ref('')
const popupGameCount = ref(0)

// Map configuration - theme-aware styles
const mapStyle = computed(() => {
  const isDark = resolvedTheme.value === 'dark'
  return isDark
    ? 'https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json'
    : 'https://tiles.stadiamaps.com/styles/alidade_smooth.json'
})

// Cluster source configuration
const clusterSource = computed(() => ({
  type: 'geojson',
  data: props.placesGeoJson,
  cluster: true,
  clusterMaxZoom: 14,
  clusterRadius: 50
}))

// Cluster circle layer configuration
const clusterLayer = computed(() => ({
  paint: {
    'circle-color': '#3b82f6',
    'circle-radius': 15,
    'circle-stroke-width': 2,
    'circle-stroke-color': '#ffffff'
  }
}))

// Cluster count layer configuration
const clusterCountLayer = computed(() => ({
  layout: {
    'text-field': '{point_count_abbreviated}',
    'text-font': ['Noto Sans Regular'],
    'text-size': 12
  },
  paint: {
    'text-color': '#ffffff'
  }
}))

// Unclustered points layer configuration
const unclusteredLayer = computed(() => ({
  paint: {
    'circle-color': '#3b82f6',
    'circle-radius': 8,
    'circle-stroke-width': 2,
    'circle-stroke-color': '#ffffff'
  }
}))

// Event handlers
function onClusterClick(e: any) {
  if (!mapRef.value) return
  
  const map = mapRef.value.map
  const features = map.queryRenderedFeatures(e.point, {
    layers: ['clusters']
  })
  const clusterId = features[0].properties.cluster_id
  map.getSource('places').getClusterExpansionZoom(clusterId).then((zoom: number) => {
    map.easeTo({
      center: features[0].geometry.coordinates,
      zoom
    })
  })
}

function onUnclusteredClick(e: any) {
  const coordinates = e.features[0].geometry.coordinates.slice()
  const name = e.features[0].properties.name
  const gameCount = e.features[0].properties.game_count
  
  popupCoordinates.value = coordinates
  popupName.value = name
  popupGameCount.value = gameCount
  showPopup.value = true
}

function onClusterMouseEnter() {
  if (mapRef.value) {
    mapRef.value.map.getCanvas().style.cursor = 'pointer'
  }
}

function onClusterMouseLeave() {
  if (mapRef.value) {
    mapRef.value.map.getCanvas().style.cursor = ''
  }
}

function onUnclusteredMouseEnter() {
  if (mapRef.value) {
    mapRef.value.map.getCanvas().style.cursor = 'pointer'
  }
}

function onUnclusteredMouseLeave() {
  if (mapRef.value) {
    mapRef.value.map.getCanvas().style.cursor = ''
  }
}
</script>

<template>
  <div class="absolute inset-0">
    <MglMap
      ref="mapRef"
      :map-style="mapStyle"
      :center="center"
      :zoom="zoom"
      :bounds="bounds"
    >
      <!-- Clustering layers for browse mode -->
      <template v-if="isBrowseMode && placesGeoJson">
        <MglGeoJsonSource
          source-id="places"
          :data="placesGeoJson"
          :cluster="true"
          :cluster-max-zoom="14"
          :cluster-radius="50"
        />
        
        <MglCircleLayer
          layer-id="clusters"
          source="places"
          :filter="['has', 'point_count']"
          :paint="clusterLayer.paint"
          @click="onClusterClick"
          @mouseenter="onClusterMouseEnter"
          @mouseleave="onClusterMouseLeave"
        />
        
        <MglSymbolLayer
          layer-id="cluster-count"
          source="places"
          :filter="['has', 'point_count']"
          :layout="clusterCountLayer.layout"
          :paint="clusterCountLayer.paint"
        />
        
        <MglCircleLayer
          layer-id="unclustered-point"
          source="places"
          :filter="['!', ['has', 'point_count']]"
          :paint="unclusteredLayer.paint"
          @click="onUnclusteredClick"
          @mouseenter="onUnclusteredMouseEnter"
          @mouseleave="onUnclusteredMouseLeave"
        />
        
        <!-- Popup for unclustered points -->
        <MglPopup
          v-if="showPopup"
          :coordinates="popupCoordinates"
          :close-button="true"
          @close="showPopup = false"
        >
          <div class="p-2">
            <h3 class="font-semibold">{{ popupName }}</h3>
            <p v-if="popupGameCount > 0" class="text-sm text-gray-600">
              Played {{ popupGameCount }} times
            </p>
          </div>
        </MglPopup>
      </template>
      
      <!-- Regular markers for game mode -->
      <slot />
    </MglMap>
  </div>
</template>

import { defineStore } from 'pinia'
import { ref, markRaw } from 'vue'
import type { Component } from 'vue'

export interface MapLayer {
  key: string
  component: Component
  props?: Record<string, any>
}

export const useMapLayersStore = defineStore('mapLayers', () => {
  const layers = ref<MapLayer[]>([])

  function setLayers(newLayers: MapLayer[]) {
    // markRaw to prevent Vue from making components reactive (they don't need to be)
    layers.value = newLayers.map((layer) => ({
      ...layer,
      component: markRaw(layer.component),
    }))
  }

  function clearLayers() {
    layers.value = []
  }

  return { layers, setLayers, clearLayers }
})

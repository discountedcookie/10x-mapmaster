import { onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { usePlacesStore } from '@/stores/places'
import type { RealtimeChannel } from '@supabase/supabase-js'

/**
 * Minimal payload shape for Postgres changes we care about.
 */
interface ChangeRow {
  id?: string | null
  // Other columns are ignored for typing purposes
  [key: string]: unknown
}

interface ChangePayload {
  eventType: 'INSERT' | 'UPDATE' | 'DELETE'
  new: ChangeRow | null
  old: ChangeRow | null
}

interface PlaceRecord extends ChangeRow {
  name?: string | null
}

/**
 * Composable for managing realtime subscriptions to places data
 * Handles INSERT, UPDATE, DELETE events from the database
 */
export function useRealtimePlaces() {
  const placesStore = usePlacesStore()
  let channel: RealtimeChannel | undefined

  /**
   * Handle realtime change events from database
   */
  async function handleRealtimeChange(payload: ChangePayload) {
    const { eventType, new: newRecord, old: oldRecord } = payload

    switch (eventType) {
      case 'INSERT':
      case 'UPDATE': {
        if (!newRecord?.id) break

        // Refetch the place from view to get geometry
        const { data } = await supabase
          .from('places_with_geometry')
          .select('*')
          .eq('id', newRecord.id as string)
          .single()

        if (data) {
          const placeData = data as PlaceRecord
          const places = placesStore.places as unknown as PlaceRecord[]
          const index = places.findIndex((p) => p.id === placeData.id)
          if (index === -1) {
            places.push(placeData)
            places.sort((a, b) => (a.name ?? '').localeCompare(b.name ?? ''))
          } else {
            places[index] = placeData
          }
        }
        break
      }
      case 'DELETE': {
        if (!oldRecord?.id) break

        const deletedId = oldRecord.id as string
        const places = placesStore.places as unknown as PlaceRecord[]
        const index = places.findIndex((p) => p.id === deletedId)
        if (index !== -1) {
          places.splice(index, 1)
        }
        break
      }
    }
  }

  /**
   * Subscribe to realtime changes
   */
  function subscribe() {
    // Clean up existing subscription if any
    if (channel) {
      supabase.removeChannel(channel)
    }

    // Subscribe to changes in the places table
    channel = supabase
      .channel('places-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'places',
        },
        (payload) => {
          void handleRealtimeChange(payload as ChangePayload)
        }
      )
      .subscribe()
  }

  /**
   * Unsubscribe from realtime changes
   */
  function unsubscribe() {
    if (channel) {
      supabase.removeChannel(channel)
      channel = undefined
    }
  }

  onMounted(() => {
    subscribe()
  })

  onUnmounted(() => {
    unsubscribe()
  })

  return {
    subscribe,
    unsubscribe,
  }
}

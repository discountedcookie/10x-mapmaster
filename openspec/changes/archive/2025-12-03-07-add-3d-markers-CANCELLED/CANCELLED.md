# Change Cancelled

**Date:** 2025-12-03
**Reason:** Technology decision changed

## Summary

This change proposed using deck.gl for 3D marker visualization. After initial dependency installation, we decided NOT to use deck.gl due to performance concerns.

**Current approach:** Use MapLibre native layers for all map visualization, including any future 3D markers.

## What was done

- deck.gl packages were installed (`@deck.gl/core`, `@deck.gl/layers`, `@deck.gl/mapbox`)
- Vite bundling was configured

## What was NOT done

- No `Deck3DLayer.vue` component was created
- No actual deck.gl integration in the map
- Current `CandidatesLayer.vue` uses MapLibre native layers

## Recommendation

If 3D markers are still desired, create a new change proposal using MapLibre's native 3D capabilities (fill-extrusion layers) instead of deck.gl.

# Change: Add Frontend Gameplay UI

## Why

Render the gameplay interface (chat, contextual input, candidate list, status badges) based on next_turn JSON from the backend.

## What Changes

- Build chat-style history, contextual input for question/guess/give up
- Display candidates with confidence bars and map panning hooks
- Show status/turn indicators

## Impact

- Affected specs: frontend
- Affected code: gameplay components, stores consuming RPC results

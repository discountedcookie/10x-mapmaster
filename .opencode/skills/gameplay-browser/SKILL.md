---
name: gameplay-browser
description: >-
  Test game via browser with Chrome DevTools. Navigate UI, play through
  game flow, observe behavior and report issues.
---

# Browser Gameplay

Test the game through the browser UI.

> **Announce:** "I'm using gameplay-browser to test via UI."

## Access

Navigate to `http://localhost:5173` (dev server must be running).

## Game Flow

1. **Start Game**
   - Enter place description in text field
   - Click "Start Game" button
   - Wait for loading to complete

2. **Answer Questions**
   - Read the question displayed
   - Click "Yes", "No", or "Not Sure"
   - Observe: map updates, confidence meter changes

3. **Handle Guesses**
   - When system guesses, confirm or deny
   - "Yes" = correct guess (game won)
   - "No" = continue with more questions

4. **Give Up**
   - Click "Give Up" when stuck
   - Search for correct place
   - Select from results to submit

## What to Observe

| Element | What to Check |
|---------|---------------|
| Buttons | Loading states, disabled during requests |
| Map | Markers update, zoom changes |
| Confidence | Meter reflects candidate certainty |
| Errors | Toast messages, console errors |
| Responsiveness | UI doesn't freeze during API calls |

## Reporting Issues

```
## Issue
[What went wrong]

## Steps to Reproduce
1. [Action] → [Expected] → [Actual]

## Evidence
- Screenshot/console error if available
```

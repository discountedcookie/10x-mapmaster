---
name: shadcn-vue
description: >-
  Context and reference for building UI with shadcn-vue components.
  Load when adding, modifying, or debugging UI components.
---

# shadcn-vue

Context skill for working with shadcn-vue components.

> **Announce:** "I'm loading shadcn-vue context for component work."

## Key Facts

- Built on **Reka UI** primitives (not Radix like React version)
- Uses **Tailwind CSS** for styling
- Forms integrate with **VeeValidate** + **zod**
- CLI: `npx shadcn-vue@latest add [component]`

## When Stuck

Fetch docs with `webfetch` for the component you need:

| Category | Components | Base URL |
|----------|------------|----------|
| **Form** | form, button, input, select, checkbox, switch | `https://www.shadcn-vue.com/docs/components/[name]` |
| **Layout** | sidebar, tabs, accordion, navigation-menu | same pattern |
| **Overlay** | dialog, sheet, popover, tooltip, dropdown-menu | same pattern |
| **Feedback** | alert, sonner (toast), progress, badge, skeleton | same pattern |
| **Display** | card, table, avatar | same pattern |

**Full LLM reference:** `https://www.shadcn-vue.com/llms.txt`

## Component Patterns in This Project

Check existing components in `src/components/ui/` before adding new ones.

Common patterns used:
- Toast notifications via Sonner
- Forms with VeeValidate + zod schemas
- Dialog for modals, Sheet for slide-overs

## Do NOT

- Import from `@radix-vue` directly - use Reka UI via shadcn-vue
- Create custom styles when a variant exists
- Skip checking if component already exists in `src/components/ui/`

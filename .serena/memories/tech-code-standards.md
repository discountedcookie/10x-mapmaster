# Technical: Code Standards

## Non-Negotiables

### 1. RLS Policies Always
**Every table must have Row Level Security enabled**

```sql
-- Enable RLS
ALTER TABLE places ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public read access" ON places
  FOR SELECT USING (true);

CREATE POLICY "Authenticated insert" ON places
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');
```

**Why:**
- Prevents unauthorized data access
- Security enforced at database level
- No way to bypass via API

**Check:**
```sql
-- All tables should return true
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

### 2. Migrations Only (Never Manual Schema)
**All schema changes via migration files**

✅ **Correct:**
```bash
# Create migration
npx supabase migration new add_column_to_places

# Edit supabase/migrations/000004_add_column_to_places.sql
ALTER TABLE places ADD COLUMN description TEXT;

# Apply migration
npx supabase db reset
```

❌ **Wrong:**
```sql
-- Running directly in SQL editor
ALTER TABLE places ADD COLUMN description TEXT;
```

**Why:**
- Version control for schema
- Reproducible across environments
- Safe rollback capability
- Clear change history

### 3. No `any` Types
**Always provide explicit types**

❌ **Wrong:**
```typescript
function processData(data: any) {
  return data.map((item: any) => item.id)
}
```

✅ **Correct:**
```typescript
interface DataItem {
  id: string
  name: string
}

function processData(data: DataItem[]): string[] {
  return data.map(item => item.id)
}
```

**Acceptable exceptions:**
- Third-party libraries without types
- Complex recursive types (use `unknown` then type guard)
- Temporary during rapid prototyping (MUST be fixed before commit)

### 4. Async/Await Pattern
**Always use async/await, never .then() chains**

❌ **Wrong:**
```typescript
function fetchData() {
  return supabase
    .from('places')
    .select('*')
    .then(({ data }) => data)
    .catch(error => console.error(error))
}
```

✅ **Correct:**
```typescript
async function fetchData(): Promise<Place[]> {
  try {
    const { data, error } = await supabase
      .from('places')
      .select('*')
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Failed to fetch data:', error)
    throw error
  }
}
```

**Why:**
- More readable
- Consistent error handling
- Better with TypeScript
- Easier to debug

## Code Conventions

### Naming

**Variables & Functions:**
```typescript
// camelCase
const userSession = ref<Session | null>(null)
const topCandidates = computed(() => ...)

function fetchAllPlaces() { ... }
async function generateEmbedding(text: string) { ... }
```

**Constants:**
```typescript
// SCREAMING_SNAKE_CASE
const MAX_QUESTIONS = 5
const MIN_CONFIDENCE = 0.7
const EMBEDDING_DIMENSIONS = 384
```

**Types & Interfaces:**
```typescript
// PascalCase
interface Place {
  id: string
  name: string
}

type GameState = 'idle' | 'asking' | 'guessing'
```

**Components:**
```typescript
// PascalCase for files and component names
// components/game/QuestionCard.vue
export default defineComponent({
  name: 'QuestionCard'
})
```

**Composables:**
```typescript
// camelCase with "use" prefix
// composables/useEmbeddings.ts
export function useEmbeddings() { ... }
```

### File Organization

**Component Structure:**
```vue
<script setup lang="ts">
// 1. Imports (external, then internal)
import { ref, computed, onMounted } from 'vue'
import { useGameStore } from '@/stores/game'

// 2. Props & Emits
interface Props {
  candidate: Place
}

const props = defineProps<Props>()
const emit = defineEmits<{
  select: [place: Place]
}>()

// 3. Composables & Stores
const gameStore = useGameStore()

// 4. Local State
const isLoading = ref(false)

// 5. Computed Properties
const confidence = computed(() => ...)

// 6. Methods
function handleSelect() {
  emit('select', props.candidate)
}

// 7. Lifecycle Hooks
onMounted(() => {
  // Initialize
})
</script>

<template>
  <!-- Template -->
</template>

<style scoped>
/* Component-specific styles */
</style>
```

**Store Structure:**
```typescript
// stores/game.ts

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useGameStore = defineStore('game', () => {
  // 1. State
  const currentSession = ref<GameSession | null>(null)
  
  // 2. Getters (computed)
  const isGameActive = computed(() => currentSession.value !== null)
  
  // 3. Actions (functions)
  async function startGame(description: string) {
    // ...
  }
  
  // 4. Return public API
  return {
    // State
    currentSession,
    // Getters
    isGameActive,
    // Actions
    startGame
  }
})
```

### Error Handling

**Pattern:**
```typescript
async function riskyOperation() {
  try {
    const result = await someAsyncCall()
    return result
  } catch (error) {
    console.error('Operation failed:', error)
    
    // User-friendly error message
    toast.error('Operation failed', {
      description: 'Please try again'
    })
    
    // Re-throw or return null based on context
    throw error // or return null
  }
}
```

**Supabase Error Handling:**
```typescript
const { data, error } = await supabase
  .from('places')
  .select('*')

if (error) {
  console.error('Supabase error:', error)
  toast.error('Failed to load data')
  return []
}

return data
```

### Comments & Documentation

**JSDoc for Public APIs:**
```typescript
/**
 * Generates a vector embedding for the given text.
 * 
 * @param text - The text to generate an embedding for
 * @returns A promise resolving to a 384-dimensional vector
 * @throws {Error} If the embedding generation fails
 */
export async function generateEmbedding(text: string): Promise<number[]> {
  // Implementation
}
```

**Inline Comments for Complex Logic:**
```typescript
// Calculate confidence score as weighted average of semantic and spatial scores
// Semantic weight: 0.7, Spatial weight: 0.3
const confidence = (semanticScore * 0.7) + (spatialScore * 0.3)
```

**No Obvious Comments:**
```typescript
// ❌ Bad
const x = 5 // Set x to 5

// ✅ Good (self-documenting)
const MAX_RETRY_ATTEMPTS = 5
```

### Import Organization

**Order:**
```typescript
// 1. Vue core
import { ref, computed, onMounted } from 'vue'

// 2. Vue ecosystem (Router, Pinia, etc.)
import { useRouter } from 'vue-router'
import { useGameStore } from '@/stores/game'

// 3. Third-party libraries
import maplibregl from 'maplibre-gl'
import { toast } from 'vue-sonner'

// 4. Internal utilities
import { supabase } from '@/lib/supabase'
import { generateEmbedding } from '@/composables/useEmbeddings'

// 5. Types
import type { Place, Question } from '@/types/database'

// 6. Assets
import '@/style.css'
```

**Use Path Aliases:**
```typescript
// ✅ Good
import { supabase } from '@/lib/supabase'

// ❌ Bad
import { supabase } from '../../../lib/supabase'
```

### TypeScript Patterns

**Use Type Inference When Clear:**
```typescript
// ✅ Good (type inferred)
const count = ref(0) // Ref<number>
const name = ref('John') // Ref<string>

// ❌ Unnecessary explicit type
const count = ref<number>(0)
```

**Explicit Types for Complex Cases:**
```typescript
// ✅ Good
const user = ref<User | null>(null)
const candidates = ref<Place[]>([])

// Return type for functions
function getConfidence(): number {
  return 0.85
}
```

**Type Guards:**
```typescript
function isPlace(obj: unknown): obj is Place {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    'id' in obj &&
    'name' in obj
  )
}

// Usage
if (isPlace(data)) {
  console.log(data.name) // TypeScript knows data is Place
}
```

### Reactivity Patterns

**Use Computed for Derived State:**
```typescript
// ✅ Good
const topCandidates = computed(() => 
  candidates.value.slice(0, 5)
)

// ❌ Bad (not reactive)
let topCandidates = candidates.value.slice(0, 5)
```

**Avoid Mutating Props:**
```typescript
// ❌ Bad
const props = defineProps<{ count: number }>()
props.count++ // Error!

// ✅ Good
const props = defineProps<{ count: number }>()
const emit = defineEmits<{ update: [number] }>()
emit('update', props.count + 1)
```

**Deep Reactivity When Needed:**
```typescript
// Shallow ref (default)
const user = ref({ name: 'John', age: 30 })

// Deep reactivity
import { reactive } from 'vue'
const user = reactive({ name: 'John', age: 30 })
user.age++ // Reactive
```

## Database Conventions

### Table & Column Names
```sql
-- snake_case for everything
CREATE TABLE game_sessions (
  id uuid PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  place_id uuid REFERENCES places(id),
  created_at timestamptz DEFAULT now()
);
```

### Foreign Keys
```sql
-- Always name foreign keys descriptively
ALTER TABLE game_sessions
ADD CONSTRAINT fk_game_sessions_user_id
FOREIGN KEY (user_id) REFERENCES auth.users(id)
ON DELETE CASCADE;
```

### Indexes
```sql
-- Name format: idx_<table>_<column>
CREATE INDEX idx_game_sessions_user_id ON game_sessions(user_id);

-- Vector indexes
CREATE INDEX idx_places_embedding ON places 
USING hnsw (embedding vector_cosine_ops);
```

### Function Names
```sql
-- snake_case, descriptive
CREATE FUNCTION get_candidates(p_session_id uuid)
RETURNS TABLE(...) AS $$
  -- Implementation
$$ LANGUAGE plpgsql;
```

## Performance Guidelines

**Avoid N+1 Queries:**
```typescript
// ❌ Bad
for (const session of sessions) {
  const answers = await supabase
    .from('game_answers')
    .select('*')
    .eq('session_id', session.id)
}

// ✅ Good
const { data: answers } = await supabase
  .from('game_answers')
  .select('*, game_sessions(*)')
  .in('session_id', sessions.map(s => s.id))
```

**Debounce User Input:**
```typescript
import { useDebouncedFn } from '@vueuse/core'

const searchDebounced = useDebouncedFn(async (query: string) => {
  await searchPlaces(query)
}, 1000)
```

**Lazy Load Heavy Components:**
```typescript
// router/index.ts
const GameView = () => import('@/views/GameView.vue')
```

## Security Guidelines

**Never Expose Service Keys:**
```typescript
// ❌ NEVER in frontend code
const supabase = createClient(url, SERVICE_KEY)

// ✅ Use anon key (RLS protects data)
const supabase = createClient(url, ANON_KEY)
```

**Validate User Input:**
```typescript
function validateDescription(text: string): boolean {
  const MIN_LENGTH = 10
  const MAX_LENGTH = 500
  
  return (
    text.length >= MIN_LENGTH &&
    text.length <= MAX_LENGTH &&
    text.trim().length > 0
  )
}
```

**Sanitize Before Display:**
```typescript
// Use Vue's built-in escaping ({{ variable }})
// NOT v-html unless absolutely necessary and sanitized
```

## Testing Standards

**Test File Naming:**
```
src/components/QuestionCard.vue
src/__tests__/components/QuestionCard.spec.ts
```

**Test Structure:**
```typescript
import { describe, it, expect, beforeEach } from 'vitest'

describe('QuestionCard', () => {
  describe('when rendering', () => {
    it('should display the question text', () => {
      // Test
    })
    
    it('should show answer buttons', () => {
      // Test
    })
  })
  
  describe('when user clicks yes', () => {
    it('should emit answer event', () => {
      // Test
    })
  })
})
```

**Use Descriptive Test Names:**
```typescript
// ✅ Good
it('should filter candidates by user answer')
it('should display error message when embedding fails')

// ❌ Bad
it('works')
it('test1')
```

## Commit Message Format

**Use Conventional Commits:**
```
feat(game): add confidence badge to results
fix(auth): handle email not confirmed error
docs(readme): update installation instructions
refactor(stores): extract game state machine logic
test(game): add tests for candidate filtering
chore(deps): upgrade vue to 3.4.0
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `refactor` - Code refactoring
- `test` - Adding/updating tests
- `chore` - Maintenance tasks
- `perf` - Performance improvements
- `style` - Code style changes (formatting)
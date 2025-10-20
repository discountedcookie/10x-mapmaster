# 10x-mapmaster - Product Vision & Architecture

## Product Overview

**10x-mapmaster** is an intelligent geography guessing game where players describe a place, and the system asks yes/no questions to identify it. The game learns from every session, improving its ability to match descriptions with places using vector embeddings and accumulated gameplay knowledge.

## Core Concept

- **Player Input**: Descriptive text (e.g., "A huge, hot city of palaces and busy markets")
- **Game Response**: Strategic yes/no questions to narrow down possibilities
- **Visual Feedback**: Real-time map showing candidate places with confidence scores
- **Learning**: Each session improves the system's place embeddings and question effectiveness

## Technical Architecture

### Tech Stack

- **Frontend**: Vue 3 + TypeScript + Vite
- **UI**: shadcn-vue component library
- **Maps**: MapLibre GL JS
- **Backend**: Supabase (PostgreSQL + pgvector + Edge Functions + Auth)
- **Hosting**: GitHub Pages (static)
- **Embeddings**: Supabase built-in gte-small model (384 dimensions)
- **Place Verification**: OpenStreetMap Nominatim API

### Full System Database Schema

#### places
- id (uuid, pk)
- name (text)
- lat, lng (float8)
- descriptors (jsonb) - Nominatim metadata
- embedding (vector(384)) - Semantic representation
- game_count (int) - Number of times guessed
- created_at, updated_at

#### questions
- id (uuid, pk)
- text (text)
- embedding (vector(384)) - Semantic representation
- times_asked (int)
- effectiveness_score (float) - Information gain metric
- created_at

#### game_sessions
- id (uuid, pk)
- user_id (uuid, fk auth.users)
- description (text) - Player's input
- description_embedding (vector(384))
- place_id (uuid, fk places) - Actual place (guess or correction)
- was_correct (boolean)
- question_count (int)
- created_at

#### game_answers
- id (uuid, pk)
- session_id (uuid, fk game_sessions)
- question_id (uuid, fk questions)
- answer (boolean)
- candidates_after (int)
- sequence_number (int)
- created_at

### Core Mechanics

#### Game Flow (Full System)
1. Player enters description → generate embedding
2. Find candidate places via vector similarity (cosine distance)
3. If confidence high → guess immediately
4. Else → select most discriminating question from database
5. Player answers → filter candidates → repeat
6. Make guess when confident or max questions reached
7. Player confirms/corrects → system learns

#### Intelligence System
- **Vector Matching**: Semantic similarity between descriptions/questions and places
- **Question Selection**: Information gain algorithm - pick questions that best split candidates
- **Learning**: Weighted average of embeddings after each game (place_embedding = weighted_avg(old_embedding, new_description_embedding, game_count))
- **Effectiveness Tracking**: Monitor which questions successfully narrow down candidates

#### Place Verification
- Query Nominatim API for place name
- Extract coordinates, type, address metadata
- Generate initial embedding from player description
- Add to database with descriptors

#### Question Generation
- Edge function analyzes current places database
- Uses AI to generate strategic yes/no questions
- Generates embeddings for new questions
- Stores in database for semantic matching

### Security & Permissions

- **places**: Public read, authenticated insert/update
- **questions**: Public read, admin-only write
- **game_sessions** & **game_answers**: RLS - users access only their own data

## Key Design Decisions

### Cold Start Strategy
- Start with **empty database** - no seed data in production
- First games will fail to guess (expected behavior)
- System learns organically from player contributions
- Quality improves naturally as database grows

### Technical Rationale

**Why pgvector?**
- Native PostgreSQL extension for vector operations
- Excellent performance with HNSW indexing
- No separate vector database needed
- Integrates seamlessly with Supabase

**Why gte-small (384d)?**
- Good balance of quality and performance
- Smaller than sentence-transformers (768d) but comparable accuracy
- Faster cosine similarity computations
- Built into Supabase

**Why Nominatim?**
- Free, open-source geocoding
- Rich metadata (type, class, address structure)
- Rate limit (1 req/sec) manageable with debouncing

**Why cold start?**
- Organic data quality from real players
- No bias from pre-selected places
- Authentic learning system demonstration
- Database grows with actual use patterns

### Open Parameters (TBD)
- Confidence threshold for immediate guess
- Maximum questions per game (10-20 range)
- Minimum candidates before guessing (3-5 range)
- Learning rate for embedding updates
- Question effectiveness decay rate

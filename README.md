# 10x-mapmaster

An intelligent geography guessing game where players describe a place, and the system asks strategic yes/no questions to identify it. The game learns from every session, improving its ability to match descriptions using semantic embeddings.

## How It Works

1. **Describe** - Enter a place description (e.g., "A huge iron tower in a European capital")
2. **Answer** - Respond to yes/no questions that narrow down candidates
3. **Discover** - Watch confidence scores update on an interactive globe
4. **Learn** - Each game improves the system's knowledge

## Tech Stack

| Layer      | Technology                                                  |
| ---------- | ----------------------------------------------------------- |
| Frontend   | Vue 3, Pinia, MapLibre GL JS, shadcn-vue                    |
| Backend    | Supabase (PostgreSQL + pgvector + PostGIS + Edge Functions) |
| Embeddings | 384-dimensional vectors (gte-small)                         |
| Hosting    | GitHub Pages                                                |

## Architecture

**Database-first design** - All game logic lives in PostgreSQL. The frontend is purely presentational.

- `start_game(description, language)` - Initialize game session
- `play_turn(session_id, answer)` - Process player response
- `submit_place(session_id, osm_id)` - Submit correct place after giving up

See `spec/` for detailed specifications and `openspec/specs/` for requirements.

## Getting Started

### Prerequisites

- [Bun](https://bun.sh/) - Package manager and runtime
- [Docker](https://www.docker.com/) - For local Supabase
- [Ollama](https://ollama.ai/) - For local LLM and embeddings

### Setup

```bash
# Clone and install
git clone <repository-url>
cd 10x-mapmaster
bun install

# Start local services
supabase start -x vector   # exclude built-in vector extension (use pgvector)
ollama serve

# Pull embedding model
ollama pull nomic-embed-text

# Set up environment
cp .env.example .env.local
# Edit .env.local with your Supabase credentials

# Reset database with migrations and seeds
bun run db:rebuild

# Start development server
bun run dev
```

## Development

```bash
bun run dev          # Start dev server
bun run lint         # Run linters
bun run type-check   # TypeScript check
bun run test:unit    # Unit tests (Vitest)
bun run test:db      # Database tests (pgTAP)
bun run db:rebuild   # Rebuild database from source
supabase test db     # Database tests (pgTAP)
```

## Project Structure

```
spec/               # Project specifications (human-readable)
openspec/           # OpenSpec requirements (machine-readable)
src/                # Vue 3 frontend (presentation only)
supabase/
├── db/             # Database source files
│   ├── schema/     # Tables, RLS, indexes
│   └── functions/  # SQL functions by domain
├── functions/      # Edge functions (Deno)
├── migrations/     # Generated migrations
└── seeds/          # Seed data
```

## For AI Agents

This project uses **OpenSpec** for spec-driven development:

```bash
openspec list --specs     # View all specifications
openspec show game-core   # View specific capability
```

See `AGENTS.md` for agent instructions and `openspec/AGENTS.md` for the full workflow.

## License

MIT

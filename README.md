# 10x-mapmaster 🗺️

[![CI/CD](https://github.com/discountedcookie/10x-mapmaster/actions/workflows/ci.yml/badge.svg)](https://github.com/discountedcookie/10x-mapmaster/actions/workflows/ci.yml)
[![Security Scan](https://github.com/discountedcookie/10x-mapmaster/actions/workflows/security-scan.yml/badge.svg)](https://github.com/discountedcookie/10x-mapmaster/actions/workflows/security-scan.yml)
[![codecov](https://codecov.io/gh/discountedcookie/10x-mapmaster/branch/main/graph/badge.svg)](https://codecov.io/gh/discountedcookie/10x-mapmaster)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/discountedcookie/10x-mapmaster/badge)](https://scorecard.dev/viewer/?uri=github.com/discountedcookie/10x-mapmaster)
[![Dependabot](https://img.shields.io/badge/Dependabot-enabled-success?logo=dependabot)](https://github.com/discountedcookie/10x-mapmaster/security/dependabot)

**10x-mapmaster** is an intelligent geography guessing game where players describe a place, and the system asks yes/no questions to identify it. The game learns from every session, improving its ability to match descriptions with places using vector embeddings and accumulated gameplay knowledge.

---

## 📊 Quality & Security Dashboard

### Test Coverage
[![Codecov Graph](https://codecov.io/gh/discountedcookie/10x-mapmaster/graphs/sunburst.svg?height=200&width=200)](https://codecov.io/gh/discountedcookie/10x-mapmaster)

**[View detailed coverage report →](https://codecov.io/gh/discountedcookie/10x-mapmaster)**

### Active Monitoring
| Tool | Status | Purpose | Dashboard |
|------|--------|---------|-----------|
| 🧪 **Codecov** | [![codecov](https://codecov.io/gh/discountedcookie/10x-mapmaster/branch/main/graph/badge.svg)](https://codecov.io/gh/discountedcookie/10x-mapmaster) | Test coverage tracking | [View Dashboard](https://codecov.io/gh/discountedcookie/10x-mapmaster) |
| 🔒 **OSSF Scorecard** | [![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/discountedcookie/10x-mapmaster/badge)](https://scorecard.dev/viewer/?uri=github.com/discountedcookie/10x-mapmaster) | Security best practices | [View Scorecard](https://scorecard.dev/viewer/?uri=github.com/discountedcookie/10x-mapmaster) |
| 📦 **Dependabot** | [![Dependabot](https://img.shields.io/badge/enabled-success?logo=dependabot)](https://github.com/discountedcookie/10x-mapmaster/security/dependabot) | Dependency updates | [View PRs](https://github.com/discountedcookie/10x-mapmaster/pulls) |
| 📏 **Bundle Size** | On PRs | Bundle monitoring | [Latest Analysis](https://github.com/discountedcookie/10x-mapmaster/pulls) |

---

## Core Concept

- **Player Input**: Descriptive text (e.g., "A huge, hot city of palaces and busy markets")
- **Game Response**: Strategic yes/no questions to narrow down possibilities
- **Visual Feedback**: Real-time map showing candidate places with confidence scores
- **Learning**: Each session improves the system's place embeddings and question effectiveness

## Technical Architecture

### Tech Stack

- **Frontend**: Vue 3 + shadcn-vue
- **Maps**: MapLibre GL JS
- **Backend**: Supabase (PostgreSQL + pgvector + Edge Functions + Auth)
- **Hosting**: GitHub Pages (static)
- **Embeddings**: Supabase built-in gte-small model (384 dimensions)
- **Data sources**: Nominatim, Open-Elevation, Overpass, Wikipedia

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

#### Question Generation
- Edge function analyzes current places database
- Uses AI to generate strategic yes/no questions
- Generates embeddings for new questions
- Stores in database for semantic matching

## Getting Started

To set up and run the project locally, follow these steps:

1.  **Prerequisites:**
    *   Node.js (v18 or higher)
    *   Docker (for Supabase local development)

2.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-repo/10x-mapmaster.git
    cd 10x-mapmaster
    ```

3.  **Install dependencies:**
    ```bash
    npm install
    ```

4.  **Set up Supabase locally:**
    ```bash
    npx supabase start
    npx supabase db reset
    ```

5.  **Set up environment variables:**
    *   Copy the example file and fill in your values:
        ```bash
        cp .env.example .env.local
        ```
    *   Required variables for development:
        - `VITE_SUPABASE_URL` - Your Supabase project URL
        - `VITE_SUPABASE_ANON_KEY` - Your Supabase anonymous key
    *   Optional variables for MCP servers (AI agent development):
        - `CONTEXT7_API_KEY` - Context7 API key
        - `SUPABASE_PROJECT_REF` - Supabase project reference
        - `CONPORT_PATH` - Path to context-portal installation

6.  **Seed the database:**
    *   Run the seed scripts:
        ```bash
        npm run seed:places
        npm run seed:questions
        ```

7.  **Run the development server:**
    ```bash
    npm dev
    ```
    The application will be available at `http://localhost:5173`.

## For AI Agents

This project uses **ConPort** for minimal context workflow:

1. **Start**: Run `/init` command to load critical project context from ConPort
2. **Work**: Use ConPort for progress tracking and decisions
3. **Handoff**: Run `/handoff` command to document work for the next agent

Available commands in `.claude/commands/`:
- `/init` - Load minimal critical context
- `/audit-memory` - Check ConPort usage and cleanup candidates
- `/handoff` - Prepare context for next agent

All project architecture, decisions, and workflow patterns are stored in ConPort for efficient, scalable context management.

## License

MIT
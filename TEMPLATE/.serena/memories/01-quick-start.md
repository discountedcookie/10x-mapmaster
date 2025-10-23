# Quick Start Guide

## Prerequisites

- Node.js 20.19.0+ or 22.12.0+
- Supabase CLI
- Git

## Setup Steps

1. **Clone and Setup**
   ```bash
   # Copy template to new project
   cp -r TEMPLATE my-new-project
   cd my-new-project
   
   # Replace template variables
   find . -type f -name "*.json" -o -name "*.yml" -o -name "*.toml" | xargs sed -i 's/{{PROJECT_NAME}}/my-new-project/g'
   ```

2. **Environment Setup**
   ```bash
   # Copy environment template
   cp .env.example .env.local
   
   # Edit .env.local with your values
   # SUPABASE_URL=http://127.0.0.1:54321
   # SUPABASE_ANON_KEY=your_anon_key
   # CONTEXT7_API_KEY=your_context7_key
   ```

3. **Install Dependencies**
   ```bash
   npm install
   ```

4. **Start Supabase**
   ```bash
   npm run supabase:start
   ```

5. **Start Development**
   ```bash
   npm run dev
   ```

## First Steps

1. Open Supabase Studio: http://localhost:54323
2. Create your first table in the SQL editor
3. Generate types: `npm run supabase:types`
4. Start building your app!

## AI Agent Usage

- **Serena**: Use for code analysis, editing, and memory management
- **Context7**: Use for documentation lookup
- **Zen**: Use for planning and project management
- **Playwright**: Use for browser testing and automation

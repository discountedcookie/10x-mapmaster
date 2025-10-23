# Project Starter Template

This is a comprehensive starter template for modern web applications with AI agent integration.

## Key Features

- **Serena AI Agent**: Intelligent code analysis and editing with memory system
- **Supabase MCP**: Direct database interaction and testing capabilities
- **Browser Testing**: Playwright integration for human-like testing
- **Planning Sessions**: SpecKit integration for project planning
- **Modern Stack**: Vue 3, TypeScript, Tailwind CSS, Vite

## Quick Start

1. Copy this template to your new project directory
2. Replace `{{PROJECT_NAME}}` with your project name
3. Set up environment variables (see `.env.example`)
4. Run `npm install`
5. Start Supabase: `npm run supabase:start`
6. Start development: `npm run dev`

## Architecture

- **Frontend**: Vue 3 + TypeScript + Tailwind CSS
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **AI Tools**: Serena (code analysis), Context7 (documentation), Zen (planning)
- **Testing**: Playwright (E2E), Vitest (Unit)
- **Development**: Vite, ESLint, TypeScript

## Memory System

The project uses Serena's memory system to maintain context across sessions:
- `00-START-HERE.md`: This file - project overview
- `01-quick-start.md`: Quick setup instructions
- `02-current-state.md`: Current project state
- `tech-stack.md`: Technology stack details
- `workflow-*.md`: Workflow patterns and best practices

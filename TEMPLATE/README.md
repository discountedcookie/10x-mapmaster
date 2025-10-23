# {{PROJECT_NAME}} - AI-Powered Development Template

A comprehensive starter template for modern web applications with AI agent integration, featuring Serena, Supabase MCP, and browser testing capabilities.

## 🚀 Features

- **🤖 AI Agent Integration**: Serena for intelligent code analysis and editing
- **🗄️ Supabase MCP**: Direct database interaction and testing
- **🌐 Browser Testing**: Playwright for human-like testing
- **📋 Planning Tools**: SpecKit integration for project planning
- **⚡ Modern Stack**: Vue 3, TypeScript, Tailwind CSS, Vite
- **🔒 Security**: Row Level Security (RLS) and authentication
- **🧪 Testing**: Unit tests (Vitest) and E2E tests (Playwright)

## 🛠️ Tech Stack

### Frontend
- **Vue 3** - Progressive JavaScript framework
- **TypeScript** - Type-safe JavaScript
- **Vite** - Fast build tool and dev server
- **Tailwind CSS** - Utility-first CSS framework
- **Vue Router** - Official router for Vue.js
- **Pinia** - State management for Vue

### Backend & Database
- **Supabase** - Backend-as-a-Service
  - PostgreSQL database
  - Authentication
  - Real-time subscriptions
  - Storage
  - Edge Functions

### AI & Development Tools
- **Serena** - AI code analysis and editing
- **Context7** - Documentation lookup
- **Zen** - Project planning and management
- **Playwright** - Browser automation and testing

## 🚀 Quick Start

### Prerequisites
- Node.js 20.19.0+ or 22.12.0+
- Supabase CLI
- Git

### Setup

1. **Copy Template**
   ```bash
   cp -r TEMPLATE my-new-project
   cd my-new-project
   ```

2. **Run Setup Script**
   ```bash
   ./scripts/setup-project.sh
   ```

3. **Configure Environment**
   ```bash
   # Edit .env.local with your values
   cp env.example .env.local
   # Edit .env.local with your actual API keys
   ```

4. **Start Development**
   ```bash
   npm run dev
   ```

## 📁 Project Structure

```
{{PROJECT_NAME}}/
├── .serena/                 # Serena AI agent configuration
│   ├── project.yml         # Serena project config
│   └── memories/           # AI agent memory system
├── .cursor/                # Cursor IDE configuration
│   └── mcp.json           # MCP server configuration
├── supabase/               # Supabase configuration
│   ├── config.toml        # Supabase config
│   ├── migrations/        # Database migrations
│   ├── functions/         # Edge functions
│   └── tests/             # Database tests
├── e2e/                   # End-to-end tests
├── src/                   # Source code
│   ├── components/        # Vue components
│   ├── composables/       # Vue composables
│   ├── lib/              # Utilities
│   ├── stores/           # Pinia stores
│   └── types/            # TypeScript types
├── scripts/               # Build and utility scripts
└── public/               # Static assets
```

## 🧠 AI Agent Workflow

### Serena (Code Analysis & Editing)
- **Symbol-based reading**: Analyze code structure efficiently
- **Intelligent editing**: Make precise code changes
- **Memory system**: Maintain context across sessions
- **Best practices**: Follow coding standards and patterns

### Context7 (Documentation)
- **API documentation**: Look up library documentation
- **Code examples**: Find usage examples
- **Best practices**: Learn from official docs

### Zen (Planning & Management)
- **Project planning**: Create project specifications
- **Task management**: Break down work into tasks
- **Progress tracking**: Monitor development progress

### Playwright (Browser Testing)
- **E2E testing**: Test complete user workflows
- **Browser automation**: Interact with the app like a user
- **Visual testing**: Capture screenshots and compare

## 🗄️ Database Workflow

### Local Development
```bash
# Start Supabase
npm run supabase:start

# Check status
npm run supabase:status

# Reset database
npm run supabase:reset
```

### Database Management
```bash
# Generate TypeScript types
npm run supabase:types

# Run migrations
supabase db push

# Test database
npm run test:db
```

## 🧪 Testing

### Unit Tests
```bash
npm run test:unit
```

### E2E Tests
```bash
npm run test:e2e
```

### Database Tests
```bash
npm run test:db
```

## 📋 Planning Sessions

Use SpecKit integration for comprehensive project planning:

1. **Project Overview**: Define goals and scope
2. **User Stories**: Create user story mapping
3. **Technical Architecture**: Plan system design
4. **Database Design**: Design schema
5. **API Design**: Plan endpoints
6. **Implementation Plan**: Create roadmap

## 🔧 Development Commands

```bash
# Development
npm run dev              # Start dev server
npm run build            # Build for production
npm run preview          # Preview production build

# Database
npm run supabase:start   # Start Supabase
npm run supabase:stop    # Stop Supabase
npm run supabase:reset   # Reset database
npm run supabase:types   # Generate types

# Testing
npm run test:unit        # Run unit tests
npm run test:e2e         # Run E2E tests
npm run test:db          # Run database tests

# Linting
npm run lint             # Run all linters
npm run lint:eslint       # Run ESLint
npm run lint:oxlint       # Run Oxlint
```

## 🎯 Best Practices

### Code Development
- Use Serena for intelligent code analysis
- Follow TypeScript best practices
- Write tests before implementation
- Use semantic commit messages

### Database
- Always test changes locally first
- Use migrations for schema changes
- Implement Row Level Security
- Document schema changes

### AI Agent Usage
- Use symbolic tools before reading full files
- Leverage memory system for context
- Test with browser automation
- Document decisions in memories

## 📚 Resources

- [Vue 3 Documentation](https://vuejs.org/)
- [Supabase Documentation](https://supabase.com/docs)
- [Playwright Documentation](https://playwright.dev/)
- [Serena Documentation](https://github.com/oraios/serena)
- [Tailwind CSS Documentation](https://tailwindcss.com/)

## 🤝 Contributing

1. Use Serena for code analysis
2. Write tests for new features
3. Update documentation
4. Follow the established patterns

## 📄 License

This project is licensed under the MIT License.

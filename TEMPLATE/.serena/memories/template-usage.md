# Template Usage Guide

## How to Use This Template

### 1. Copy Template
```bash
# Copy the entire TEMPLATE directory to your new project
cp -r TEMPLATE my-new-project
cd my-new-project
```

### 2. Replace Template Variables
The template uses `{{PROJECT_NAME}}` as a placeholder. Replace it with your actual project name:

```bash
# Replace all occurrences of {{PROJECT_NAME}}
find . -type f -name "*.json" -o -name "*.yml" -o -name "*.toml" -o -name "*.ts" -o -name "*.js" -o -name "*.md" | xargs sed -i 's/{{PROJECT_NAME}}/my-new-project/g'
```

### 3. Run Setup Script
```bash
# Make setup script executable and run it
chmod +x scripts/setup-project.sh
./scripts/setup-project.sh
```

### 4. Configure Environment
```bash
# Copy environment template
cp env.example .env.local

# Edit .env.local with your actual values
# SUPABASE_URL=http://127.0.0.1:54321
# SUPABASE_ANON_KEY=your_anon_key
# CONTEXT7_API_KEY=your_context7_key
```

### 5. Start Development
```bash
# Install dependencies
npm install

# Start Supabase
npm run supabase:start

# Start development server
npm run dev
```

## Template Customization

### Project-Specific Changes
1. **Update project name** in all configuration files
2. **Customize database schema** in `supabase/migrations/`
3. **Add project-specific components** in `src/components/`
4. **Update memory system** with project-specific information
5. **Configure environment variables** for your APIs

### Memory System Customization
- Update `00-START-HERE.md` with your project overview
- Modify `01-quick-start.md` with your setup instructions
- Add project-specific memories in `.serena/memories/`
- Update workflow memories with your patterns

### Database Customization
- Modify `supabase/migrations/000001_initial_schema.sql`
- Add your tables and relationships
- Update `supabase/seed.sql` with your data
- Create additional migrations as needed

## Template Features

### AI Agent Integration
- **Serena**: Intelligent code analysis and editing
- **Context7**: Documentation lookup
- **Zen**: Project planning and management
- **Playwright**: Browser testing and automation

### Development Tools
- **Vue 3 + TypeScript**: Modern frontend stack
- **Supabase**: Backend-as-a-Service
- **Tailwind CSS**: Utility-first styling
- **Vite**: Fast build tool
- **Playwright**: E2E testing

### Testing Setup
- **Vitest**: Unit testing
- **Playwright**: E2E testing
- **Supabase**: Database testing
- **ESLint**: Code linting

## Best Practices

### When Starting a New Project
1. **Plan first** using SpecKit integration
2. **Set up database schema** early
3. **Configure authentication** properly
4. **Write tests** as you develop
5. **Use AI agents** for code analysis and editing

### Development Workflow
1. **Use Serena** for code analysis
2. **Test with Playwright** for user workflows
3. **Use Supabase MCP** for database operations
4. **Document decisions** in memory system
5. **Follow safety rules** for all changes

### Maintenance
1. **Update dependencies** regularly
2. **Keep memories current**
3. **Test thoroughly** before deployment
4. **Monitor performance**
5. **Document changes**

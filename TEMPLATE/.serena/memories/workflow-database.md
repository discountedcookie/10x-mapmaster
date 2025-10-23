# Database Workflow with Supabase MCP

## Database Operations

### Local Development
```bash
# Start Supabase
npm run supabase:start

# Check status
npm run supabase:status

# Reset database
npm run supabase:reset

# Stop Supabase
npm run supabase:stop
```

### Database Management
```bash
# Generate TypeScript types
npm run supabase:types

# Run migrations
supabase db push

# Create new migration
supabase migration new migration_name

# Test database
npm run test:db
```

## MCP Integration

### Supabase MCP Tools
- **Database queries**: Direct SQL execution
- **Schema management**: Create/modify tables
- **Data seeding**: Insert test data
- **Function testing**: Test edge functions
- **Real-time testing**: Test subscriptions

### Common Patterns

1. **Schema Changes**
   - Create migration file
   - Test locally with MCP
   - Apply to production

2. **Data Operations**
   - Use MCP for direct queries
   - Test with Playwright
   - Validate with unit tests

3. **Function Development**
   - Write edge functions
   - Test with MCP tools
   - Deploy and test

## Best Practices

- Always test database changes locally first
- Use MCP tools for direct database interaction
- Test with both unit tests and E2E tests
- Keep migrations small and focused
- Use RLS for security
- Document schema changes in memories

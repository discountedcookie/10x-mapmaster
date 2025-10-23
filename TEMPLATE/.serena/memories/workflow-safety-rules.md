# Safety Rules and Best Practices

## Code Safety

### Before Making Changes
1. **Read existing code** using Serena's symbolic tools
2. **Understand the context** before editing
3. **Test changes locally** before committing
4. **Use version control** for all changes
5. **Write tests** for new functionality

### Database Safety
1. **Always backup** before schema changes
2. **Test migrations** on development first
3. **Use transactions** for complex operations
4. **Validate data** before insertion
5. **Use RLS** for security

### AI Agent Safety
1. **Review AI suggestions** before applying
2. **Test generated code** thoroughly
3. **Don't commit** without review
4. **Use memory system** to track decisions
5. **Document changes** in memories

## Security Best Practices

### Authentication
- Use Supabase Auth for user management
- Implement proper RLS policies
- Validate user inputs
- Use secure session management

### Data Protection
- Encrypt sensitive data
- Use HTTPS in production
- Implement proper CORS policies
- Validate all inputs

### API Security
- Rate limit API endpoints
- Validate request data
- Use proper error handling
- Log security events

## Testing Safety

### Before Deployment
1. **Run all tests** (unit, integration, E2E)
2. **Test database migrations**
3. **Verify security policies**
4. **Test error scenarios**
5. **Validate user workflows**

### Continuous Testing
- Automated test runs
- Database test coverage
- Security test scans
- Performance monitoring

## Development Workflow

### Code Quality
- Use TypeScript for type safety
- Follow ESLint rules
- Write meaningful tests
- Document complex logic
- Use semantic commits

### Collaboration
- Use feature branches
- Review all changes
- Document decisions
- Share knowledge
- Maintain consistency

## Emergency Procedures

### If Something Breaks
1. **Don't panic** - use version control
2. **Identify the issue** using logs and tests
3. **Revert if necessary** to last working state
4. **Fix incrementally** with small changes
5. **Test thoroughly** before deploying

### Database Issues
1. **Stop the application** if needed
2. **Check Supabase logs**
3. **Verify migrations**
4. **Test with sample data**
5. **Restore from backup** if critical

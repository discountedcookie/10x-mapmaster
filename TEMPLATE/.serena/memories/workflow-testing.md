# Testing Workflow

## Testing Strategy

### Unit Tests (Vitest)
- Test individual components and functions
- Fast execution
- Isolated testing
- Mock external dependencies

### E2E Tests (Playwright)
- Test complete user workflows
- Browser automation
- Real user interactions
- Cross-browser testing

## Playwright Integration

### Browser Testing
```bash
# Run E2E tests
npm run test:e2e

# Run specific test
npx playwright test test-name.spec.ts

# Run in headed mode
npx playwright test --headed

# Generate test
npx playwright codegen
```

### MCP Browser Tools
- **Page navigation**: Navigate to URLs
- **Element interaction**: Click, type, select
- **Screenshot capture**: Visual testing
- **Form submission**: Test user inputs
- **API testing**: Test backend integration

## Testing Patterns

### Component Testing
1. Test component props and events
2. Test user interactions
3. Test conditional rendering
4. Test error states

### E2E Testing
1. Test complete user journeys
2. Test authentication flows
3. Test data persistence
4. Test error handling

### Database Testing
1. Test with real database
2. Use MCP tools for setup
3. Clean up after tests
4. Test edge cases

## Best Practices

- Write tests before implementation (TDD)
- Use descriptive test names
- Keep tests independent
- Mock external services
- Test error scenarios
- Use Page Object Model for E2E
- Take screenshots for debugging
- Test on multiple browsers

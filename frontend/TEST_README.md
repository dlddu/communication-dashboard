# Frontend Testing Guide

## Test Setup

This project uses Vitest with React Testing Library for frontend testing.

## Prerequisites

1. Install dependencies:
```bash
cd frontend
npm install
```

## Running Tests

### Run all tests
```bash
npm test
```

### Run tests in watch mode
```bash
npm test -- --watch
```

### Run tests with UI
```bash
npm run test:ui
```

### Run tests with coverage
```bash
npm run test:coverage
```

### Run specific test file
```bash
npm test -- --testPathPattern=SlackWidget
```

## Test Structure

### Hook Tests
- Location: `src/hooks/useSlackMessages.test.ts`
- Tests the `useSlackMessages` custom hook
- Covers:
  - Initial loading state
  - Successful message fetching
  - Error handling
  - Refresh functionality
  - Edge cases

### Component Tests
- Location: `src/components/features/SlackWidget.test.tsx`
- Tests the `SlackWidget` component
- Covers:
  - Rendering
  - Message list display
  - Loading state
  - Error state
  - Refresh functionality
  - Accessibility
  - Edge cases

## Test Status

**⚠️ IMPORTANT: Tests are currently FAILING**

This is expected behavior for TDD (Test-Driven Development) - Red Phase.

The following components need to be implemented:
1. `src/hooks/useSlackMessages.ts` - Custom hook for fetching Slack messages
2. `src/components/features/SlackWidget.tsx` - Widget component for displaying Slack messages

## Next Steps (Green Phase)

1. Implement `useSlackMessages` hook:
   - Use `pluginService.getPluginData('slack', limit)` to fetch messages
   - Handle loading, error, and success states
   - Provide refresh functionality
   - Validate and sanitize input (negative limit handling)

2. Implement `SlackWidget` component:
   - Use `useSlackMessages` hook
   - Display message list with channel, sender, content, and timestamp
   - Show loading indicator during data fetch
   - Display error messages appropriately
   - Add refresh button with proper state management
   - Handle edge cases (empty data, missing metadata, invalid timestamps)
   - Ensure accessibility (ARIA labels, semantic HTML)

3. Run tests again to verify implementation:
```bash
npm test
```

## Coverage Goals

- Aim for >80% code coverage
- Focus on testing critical user interactions
- Ensure all error paths are tested

## CI/CD Integration

Tests run automatically on:
- Push to main/develop branches
- Pull requests to main/develop branches

GitHub Actions workflow: `.github/workflows/test.yml`

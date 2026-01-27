# Frontend Testing Guide

This document describes how to run and write tests for the frontend application.

## Setup

### Install Dependencies

```bash
cd frontend
npm install
```

## Running Tests

### Run all tests
```bash
npm test
```

### Run tests in watch mode (for development)
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
npm test -- src/services/api.test.ts
```

### Run tests matching a pattern
```bash
npm test -- --testNamePattern="should fetch plugins"
```

## Test Structure

### Test Files Location
- Unit tests: `src/**/*.test.ts` or `src/**/*.test.tsx`
- Test setup: `src/test/setup.ts`
- Vitest config: `vitest.config.ts`

### Current Test Coverage

#### API Service Tests (`src/services/api.test.ts`)
- Tests for `pluginService.getPlugins()`
- Tests for `pluginService.getPluginData()`
- Tests for `pluginService.refreshPlugin()`
- Error handling and edge cases
- API client configuration

#### Custom Hook Tests (`src/hooks/usePlugins.test.ts`)
- Initial state tests
- Successful data fetching
- Error handling
- Refetch functionality
- Edge cases (multiple rapid calls, stable function reference)

#### UI Component Tests
- **Button** (`src/components/ui/Button.test.tsx`)
  - Rendering with different variants (primary, secondary, danger)
  - Loading state
  - Disabled state
  - Click interactions
  - Accessibility

- **Card** (`src/components/ui/Card.test.tsx`)
  - Children rendering
  - className handling
  - DOM structure
  - Edge cases
  - Accessibility

## Writing New Tests

### Example: Testing a Component

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MyComponent } from './MyComponent';

describe('MyComponent', () => {
  it('should render correctly', () => {
    // Arrange & Act
    render(<MyComponent />);

    // Assert
    expect(screen.getByText('Expected Text')).toBeInTheDocument();
  });

  it('should handle click', async () => {
    // Arrange
    const user = userEvent.setup();
    render(<MyComponent />);

    // Act
    await user.click(screen.getByRole('button'));

    // Assert
    expect(screen.getByText('Clicked')).toBeInTheDocument();
  });
});
```

### Example: Testing a Hook

```typescript
import { describe, it, expect } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useMyHook } from './useMyHook';

describe('useMyHook', () => {
  it('should return initial state', () => {
    // Act
    const { result } = renderHook(() => useMyHook());

    // Assert
    expect(result.current.data).toBeNull();
  });

  it('should fetch data', async () => {
    // Act
    const { result } = renderHook(() => useMyHook());

    // Assert
    await waitFor(() => {
      expect(result.current.data).not.toBeNull();
    });
  });
});
```

### Example: Mocking API calls

```typescript
import { vi } from 'vitest';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';

describe('API Tests', () => {
  let mock: MockAdapter;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  it('should mock API response', async () => {
    // Arrange
    mock.onGet('/api/data').reply(200, { data: 'mocked' });

    // Act & Assert
    // Your test code here
  });
});
```

## Test Best Practices

1. **Use AAA Pattern**: Arrange, Act, Assert
2. **One assertion per test**: Keep tests focused
3. **Clear test names**: Use "should [expected behavior] when [condition]"
4. **Isolate tests**: Each test should be independent
5. **Mock external dependencies**: Use `vi.mock()` or `MockAdapter`
6. **Test user behavior**: Focus on what users see and do
7. **Avoid testing implementation details**: Test the component's public API

## Troubleshooting

### Tests not running
- Ensure dependencies are installed: `npm install`
- Check if vitest is properly configured
- Verify test file naming convention (*.test.ts or *.test.tsx)

### Import errors
- Check path aliases in `vitest.config.ts`
- Ensure `@/` alias is properly configured
- Verify file extensions are correct

### DOM-related errors
- Ensure `jsdom` environment is configured in `vitest.config.ts`
- Check if `@testing-library/jest-dom` is imported in setup file

### Type errors
- Verify `vitest/globals` is in tsconfig types
- Check TypeScript version compatibility
- Ensure all testing library types are installed

## CI/CD

Tests run automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

GitHub Actions workflow: `.github/workflows/test.yml`

## Coverage Reports

Coverage reports are generated in the `coverage/` directory after running:

```bash
npm run test:coverage
```

Open `coverage/index.html` in a browser to view the detailed coverage report.

## Resources

- [Vitest Documentation](https://vitest.dev/)
- [React Testing Library](https://testing-library.com/react)
- [Testing Library User Event](https://testing-library.com/docs/user-event/intro)
- [Jest DOM Matchers](https://github.com/testing-library/jest-dom)

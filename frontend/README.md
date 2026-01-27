# Communication Dashboard - Frontend

A modern, responsive web dashboard for managing communication plugins and data sources. Built with React, TypeScript, and Vite.

## Features

- View all available communication plugins
- Display plugin statistics (data count, last update time)
- Refresh plugin data with a single click
- Real-time loading and error states
- Responsive design (mobile, tablet, desktop)
- Dark/Light theme support (follows system preference)

## Tech Stack

- **React 19** - UI framework
- **TypeScript** - Type safety
- **Vite** - Fast build tool and dev server
- **Axios** - HTTP client
- **CSS3** - Modern styling

## Project Structure

```
frontend/
├── src/
│   ├── components/
│   │   ├── features/        # Feature-specific components
│   │   │   └── PluginCard.tsx
│   │   └── ui/              # Reusable UI components
│   │       ├── Button.tsx
│   │       └── Card.tsx
│   ├── config/
│   │   └── api.ts           # API configuration
│   ├── hooks/
│   │   └── usePlugins.ts    # Custom React hooks
│   ├── pages/               # Page components (future)
│   ├── services/
│   │   └── api.ts           # API client and services
│   ├── types/
│   │   └── plugin.ts        # TypeScript type definitions
│   ├── utils/               # Utility functions (future)
│   ├── App.tsx              # Main application component
│   ├── main.tsx             # Application entry point
│   └── index.css            # Global styles
├── .env.example             # Environment variables template
├── .env.local               # Local environment variables (gitignored)
├── package.json
├── tsconfig.json
├── tsconfig.app.json
├── vite.config.ts
└── README.md
```

## Prerequisites

- Node.js 18+ and npm
- Backend API running on `http://localhost:8000` (or configure via environment variables)

## Installation

1. Install dependencies:

```bash
npm install
```

2. Configure environment variables:

```bash
cp .env.example .env.local
```

Edit `.env.local` if your backend API is running on a different URL:

```env
VITE_API_URL=http://localhost:8000
```

## Available Scripts

### Development

Start the development server with hot module replacement:

```bash
npm run dev
```

The application will be available at `http://localhost:5173`

### Build

Build the application for production:

```bash
npm run build
```

The optimized build will be in the `dist/` directory.

### Preview

Preview the production build locally:

```bash
npm run preview
```

### Lint

Check code quality with ESLint:

```bash
npm run lint
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_API_URL` | Backend API base URL | `http://localhost:8000` |

## API Integration

The frontend communicates with the backend API using the following endpoints:

- `GET /plugins` - Fetch all plugins
- `GET /plugins/{name}/data` - Fetch plugin data
- `POST /plugins/{name}/refresh` - Refresh plugin data

### API Service

All API calls are handled through the `pluginService` in `src/services/api.ts`:

```typescript
import { pluginService } from '@/services/api';

// Get all plugins
const plugins = await pluginService.getPlugins();

// Get plugin data
const data = await pluginService.getPluginData('email', 50);

// Refresh plugin
const result = await pluginService.refreshPlugin('email');
```

## Component Usage

### PluginCard

Displays information about a single plugin:

```tsx
import { PluginCard } from '@/components/features/PluginCard';

<PluginCard
  plugin={{
    name: 'email',
    count: 42,
    last_updated: '2026-01-26T12:00:00Z'
  }}
  onRefresh={() => console.log('Refreshed')}
/>
```

### Button

Reusable button component with variants:

```tsx
import { Button } from '@/components/ui/Button';

<Button variant="primary" onClick={handleClick}>
  Click Me
</Button>

<Button variant="secondary" loading={true}>
  Loading...
</Button>
```

### Card

Container component for card layouts:

```tsx
import { Card } from '@/components/ui/Card';

<Card>
  <h3>Title</h3>
  <p>Content</p>
</Card>
```

## Custom Hooks

### usePlugins

Manages plugin state and API calls:

```tsx
import { usePlugins } from '@/hooks/usePlugins';

function MyComponent() {
  const { plugins, loading, error, refetch } = usePlugins();

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      {plugins.map(plugin => (
        <div key={plugin.name}>{plugin.name}</div>
      ))}
    </div>
  );
}
```

## Styling

The project uses CSS modules with a consistent design system:

- Dark mode by default
- Light mode support via `prefers-color-scheme`
- Responsive breakpoints at 768px
- Modern color palette with hover effects
- Smooth transitions and animations

## TypeScript

The project is fully typed with TypeScript in strict mode:

- All API responses have defined types
- Props are strictly typed
- Type inference for hooks and utilities
- Path aliases configured (`@/` points to `src/`)

## Browser Support

- Chrome/Edge (latest 2 versions)
- Firefox (latest 2 versions)
- Safari (latest 2 versions)
- Mobile browsers (iOS Safari, Chrome Mobile)

## Troubleshooting

### Port 5173 already in use

Kill the process using the port or specify a different port:

```bash
npm run dev -- --port 3000
```

### API connection refused

Make sure the backend server is running on `http://localhost:8000` or update `VITE_API_URL` in `.env.local`.

### Build fails with TypeScript errors

Run the type checker:

```bash
npx tsc --noEmit
```

Fix any type errors before building.

## Future Enhancements

- [ ] Plugin data viewer (click to see messages/emails)
- [ ] Search and filter functionality
- [ ] Pagination for large datasets
- [ ] User authentication
- [ ] Plugin configuration interface
- [ ] Real-time updates with WebSockets
- [ ] Data export functionality
- [ ] Advanced analytics and charts

## Contributing

1. Follow the existing code style
2. Use TypeScript strict mode
3. Write meaningful component names
4. Keep components small and focused
5. Add proper error handling

## License

MIT

import { usePlugins } from '@/hooks/usePlugins';
import { PluginCard } from '@/components/features/PluginCard';

function App() {
  const { plugins, loading, error, refetch } = usePlugins();

  if (loading) {
    return (
      <div className="app">
        <div className="loading">Loading plugins...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="app">
        <div className="error">
          <strong>Error:</strong> {error}
        </div>
      </div>
    );
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1 className="app-title">Communication Dashboard</h1>
        <p className="app-subtitle">
          Manage your communication plugins and data sources
        </p>
      </header>

      {plugins.length === 0 ? (
        <div className="loading">No plugins available</div>
      ) : (
        <div className="plugin-grid">
          {plugins.map((plugin) => (
            <PluginCard
              key={plugin.name}
              plugin={plugin}
              onRefresh={refetch}
            />
          ))}
        </div>
      )}
    </div>
  );
}

export default App;

import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import AppRouter from './router/AppRouter.tsx';
import { useSessionRefresh } from './hooks/useSessionRefresh';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

function SessionGate({ children }: { children: React.ReactNode }) {
  // Refresca permisos y alcance al abrir el panel: sin esto, un cambio de rol
  // o un permiso nuevo no se notaban hasta volver a iniciar sesión.
  useSessionRefresh();
  return <>{children}</>;
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <SessionGate>
          <AppRouter />
        </SessionGate>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

export default App;

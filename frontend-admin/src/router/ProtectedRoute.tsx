import { Navigate, Outlet } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';

export function ProtectedRoute() {
  const { isAuthenticated, user } = useAuthStore();

  // Check if authenticated
  if (!isAuthenticated || !user) {
    return <Navigate to="/login" replace />;
  }

  // Ensure user status is active
  if (user.status !== 'ACTIVE') {
    return <Navigate to="/login" replace />;
  }

  // Render children/outlet
  return <Outlet />;
}

import { Navigate, Outlet } from 'react-router-dom';
import { ShieldAlert } from 'lucide-react';
import { useAuthStore, userHasPermission } from '../store/authStore';

interface ProtectedRouteProps {
  /**
   * Permiso (o lista de permisos alternativos) que exige la sección.
   * Sin valor, basta con tener acceso al panel.
   */
  permission?: string | string[];
}

/**
 * Puerta de acceso del panel administrativo.
 *
 * Antes sólo comprobaba que hubiera sesión: cualquier cuenta veía todas las
 * secciones y sólo fallaba al llamar al backend. Ahora cada rol entra
 * únicamente a lo que le corresponde.
 */
export function ProtectedRoute({ permission }: ProtectedRouteProps) {
  const { isAuthenticated, user } = useAuthStore();

  if (!isAuthenticated || !user) {
    return <Navigate to="/login" replace />;
  }

  if (user.status !== 'ACTIVE') {
    return <Navigate to="/login" replace />;
  }

  // Un miembro de la comunidad no opera el panel: su lugar es la app móvil.
  if (user.can_access_admin === false) {
    return <Navigate to="/login" replace />;
  }

  if (!userHasPermission(user, permission)) {
    return <NoAccess />;
  }

  return <Outlet />;
}

function NoAccess() {
  return (
    <div className="flex flex-col items-center justify-center py-24 px-6 text-center">
      <div className="p-4 mb-5 rounded-full bg-error-red bg-opacity-10 border border-error-red border-opacity-20">
        <ShieldAlert size={32} className="text-error-red" />
      </div>
      <h2 className="text-lg font-bold text-crema mb-2">Sección no disponible</h2>
      <p className="text-xs text-crema text-opacity-55 max-w-sm leading-relaxed">
        Tu rol no tiene permisos para esta sección. Si necesitas acceso,
        solicítalo al superadministrador de la iglesia.
      </p>
    </div>
  );
}

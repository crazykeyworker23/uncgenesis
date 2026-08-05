import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface UserProfile {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone: string;
  avatar: string | null;
  location: string;
  bio: string;
  status: string;
  /** Roles asignados (SUPERADMIN, CELL_LEADER, ...). */
  roles?: string[];
  /** Permisos efectivos: deciden qué módulos ve esta sesión. */
  permissions?: string[];
  /** Control total del sistema. */
  is_superadmin?: boolean;
  /** Si la cuenta puede operar el panel web. */
  can_access_admin?: boolean;
  /** Cuántas células tiene a su cargo: habilita la sección "Mi Célula". */
  leads_cells?: number;
}

interface AuthState {
  user: UserProfile | null;
  accessToken: string | null;
  refreshToken: string | null;
  isAuthenticated: boolean;
  login: (user: UserProfile, access: string, refresh: string) => void;
  logout: () => void;
  updateAccessToken: (access: string) => void;
  setUser: (user: UserProfile) => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,
      login: (user, access, refresh) => set({
        user,
        accessToken: access,
        refreshToken: refresh,
        isAuthenticated: true
      }),
      logout: () => set({
        user: null,
        accessToken: null,
        refreshToken: null,
        isAuthenticated: false
      }),
      updateAccessToken: (access) => set({
        accessToken: access
      }),
      // Refresca el perfil sin tocar los tokens: si un superadministrador
      // cambia los roles de alguien, su alcance se actualiza al recargar.
      setUser: (user) => set({ user })
    }),
    {
      name: 'genesis-auth-store', // key in localStorage
    }
  )
);

/**
 * Indica si la sesión activa puede ejercer un permiso.
 *
 * El superadministrador siempre puede: así, un permiso nuevo queda cubierto
 * sin tener que enumerarlo en ningún sitio.
 */
export function userHasPermission(
  user: UserProfile | null,
  permission?: string | string[]
): boolean {
  if (!user) return false;
  if (user.is_superadmin) return true;
  if (!permission) return true;

  const required = Array.isArray(permission) ? permission : [permission];
  if (required.length === 0) return true;

  const granted = user.permissions ?? [];
  return required.some((code) => granted.includes(code));
}

/** Hook de conveniencia para consultar permisos dentro de un componente. */
export function usePermissions() {
  const user = useAuthStore((state) => state.user);

  return {
    user,
    isSuperadmin: Boolean(user?.is_superadmin),
    /** Lidera al menos una célula: habilita su vista propia. */
    leadsCells: (user?.leads_cells ?? 0) > 0,
    can: (permission?: string | string[]) => userHasPermission(user, permission),
  };
}

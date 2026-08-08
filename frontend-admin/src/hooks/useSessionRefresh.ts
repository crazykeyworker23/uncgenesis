import { useEffect } from 'react';
import { apiClient } from '../api/client';
import { useAuthStore } from '../store/authStore';

/**
 * Mantiene al día el perfil de la sesión.
 *
 * El alcance y los permisos se guardaban una sola vez al iniciar sesión y
 * quedaban congelados en el navegador. Si el superadministrador cambiaba un
 * rol, asignaba una célula o se añadía un permiso nuevo al sistema, la persona
 * seguía viendo el panel viejo hasta volver a entrar —y sin ninguna pista de
 * por qué le faltaban secciones.
 *
 * Al abrir el panel se vuelve a pedir el perfil, de modo que lo que se muestra
 * corresponda a lo que el servidor concede hoy.
 */
export function useSessionRefresh() {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const setUser = useAuthStore((state) => state.setUser);
  const logout = useAuthStore((state) => state.logout);

  useEffect(() => {
    if (!isAuthenticated) return;

    let cancelled = false;

    apiClient
      .get('/auth/me/')
      .then((res) => {
        if (cancelled) return;
        setUser(res.data);

        // Si la cuenta perdió el acceso al panel, se cierra la sesión en vez
        // de dejar una interfaz que ya no puede operar.
        if (res.data?.can_access_admin === false) {
          logout();
        }
      })
      .catch((err) => {
        if (cancelled) return;
        if (err?.response?.status === 401) {
          logout();
        }
        // Un fallo de red no debe cerrar la sesión: se conserva el perfil
        // guardado y se reintentará en la siguiente carga.
      });

    return () => {
      cancelled = true;
    };
  }, [isAuthenticated, setUser, logout]);
}

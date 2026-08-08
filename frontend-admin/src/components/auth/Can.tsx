import React from 'react';
import { usePermissions } from '../../store/authStore';

interface CanProps {
  /** Permiso (o alternativas) que habilita la acción. */
  permission: string | string[];
  /** Contenido a mostrar si el rol tiene el permiso. */
  children: React.ReactNode;
  /** Qué mostrar cuando no lo tiene. Por defecto, nada. */
  fallback?: React.ReactNode;
}

/**
 * Muestra una acción sólo si el rol puede ejecutarla.
 *
 * El backend ya rechaza lo que no corresponde, pero sin este filtro la
 * interfaz ofrecía botones de crear, editar y eliminar a todo el mundo y la
 * acción fallaba con un 403 que parecía un error del sistema.
 */
export const Can: React.FC<CanProps> = ({ permission, children, fallback = null }) => {
  const { can } = usePermissions();
  return <>{can(permission) ? children : fallback}</>;
};

/**
 * Mapa único de módulos del panel y el permiso que exige cada uno.
 *
 * Lo consumen el menú lateral y el router, de modo que lo que se ve y lo que
 * se puede abrir por URL nunca se contradigan. Los codenames coinciden con el
 * catálogo del backend (apps/roles), editable desde "Roles y Permisos".
 */
export interface AdminModule {
  /** Etiqueta en el menú lateral. */
  name: string;
  /** Ruta base de la sección. */
  path: string;
  /** Permiso necesario para ver la sección. Sin valor: visible para todos. */
  permission?: string;
  /** Permisos que habilitan crear o editar dentro de la sección. */
  writePermission?: string[];
}

export const ADMIN_MODULES: AdminModule[] = [
  { name: 'Dashboard', path: '/dashboard' },
  {
    name: 'Publicaciones',
    path: '/publicaciones',
    permission: 'PUBLICATIONS_VIEW',
    writePermission: ['PUBLICATIONS_CREATE', 'PUBLICATIONS_EDIT'],
  },
  {
    name: 'Servicios',
    path: '/servicios',
    permission: 'SERVICES_VIEW',
    writePermission: ['SERVICES_CREATE', 'SERVICES_EDIT'],
  },
  {
    name: 'Devocionales',
    path: '/devocionales',
    permission: 'DEVOTIONALS_VIEW',
    writePermission: ['DEVOTIONALS_CREATE', 'DEVOTIONALS_EDIT'],
  },
  {
    name: 'Células',
    path: '/celulas',
    permission: 'CELLS_VIEW',
    writePermission: ['CELLS_CREATE', 'CELLS_EDIT'],
  },
  {
    name: 'Eventos',
    path: '/eventos',
    permission: 'EVENTS_VIEW',
    writePermission: ['EVENTS_CREATE', 'EVENTS_EDIT'],
  },
  {
    name: 'Notificaciones',
    path: '/notificaciones',
    permission: 'NOTIFICATIONS_VIEW',
    writePermission: ['NOTIFICATIONS_CREATE', 'NOTIFICATIONS_SEND'],
  },
  {
    name: 'Solicitudes',
    path: '/solicitudes',
    permission: 'REQUESTS_VIEW',
  },
  {
    name: 'Usuarios',
    path: '/usuarios',
    permission: 'USERS_VIEW',
    writePermission: ['USERS_EDIT'],
  },
  {
    name: 'Roles y Permisos',
    path: '/roles',
    permission: 'ROLES_VIEW',
    writePermission: ['ROLES_EDIT'],
  },
  {
    name: 'Biblioteca',
    path: '/multimedia',
    permission: 'MEDIA_VIEW',
    writePermission: ['MEDIA_CREATE'],
  },
  {
    name: 'Reportes',
    path: '/reportes',
    permission: 'REPORTS_VIEW',
  },
  {
    name: 'Configuración',
    path: '/configuracion',
    permission: 'SETTINGS_VIEW',
    writePermission: ['SETTINGS_EDIT'],
  },
];

/** Permiso de lectura de una sección, por su ruta base. */
export function modulePermission(path: string): string | undefined {
  return ADMIN_MODULES.find((mod) => mod.path === path)?.permission;
}

/** Permisos de escritura de una sección, por su ruta base. */
export function moduleWritePermission(path: string): string[] | undefined {
  return ADMIN_MODULES.find((mod) => mod.path === path)?.writePermission;
}

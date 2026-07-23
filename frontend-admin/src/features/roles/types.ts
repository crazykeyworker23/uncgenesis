export interface Permission {
  id: number;
  codename: string;
  name: string;
  description: string;
}

export interface Role {
  id: number;
  name: string;
  description: string;
  permissions: string[];
}

export const ROLE_LABELS: Record<string, string> = {
  SUPERADMIN: 'Super Administrador',
  ADMIN: 'Administrador',
  CONTENT_EDITOR: 'Editor de Contenido',
  CELL_LEADER: 'Líder de Célula',
  SUPPORT: 'Soporte y Consejería',
  MEMBER: 'Miembro de la Comunidad',
  VIEWER: 'Visitante/Espectador',
};

export const ROLE_BADGE_COLORS: Record<string, string> = {
  SUPERADMIN: 'bg-red-500/10 text-red-400 border-red-500/20',
  ADMIN: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
  CONTENT_EDITOR: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
  CELL_LEADER: 'bg-teal-500/10 text-teal-300 border-teal-500/20',
  SUPPORT: 'bg-purple-500/10 text-purple-400 border-purple-500/20',
  MEMBER: 'bg-green-500/10 text-green-400 border-green-500/20',
  VIEWER: 'bg-gray-500/10 text-gray-400 border-gray-500/20',
};

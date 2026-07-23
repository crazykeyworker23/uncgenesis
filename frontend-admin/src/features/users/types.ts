export type UserStatus = 'ACTIVE' | 'INACTIVE' | 'BLOCKED';

export interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone: string;
  avatar: string | null;
  location: string;
  bio: string;
  status: UserStatus;
  is_staff: boolean;
  is_superuser: boolean;
  created_at: string;
  roles: string[];
}

export interface PaginatedUsers {
  count: number;
  next: string | null;
  previous: string | null;
  results: User[];
}

export const USER_STATUS_CONFIG: Record<
  UserStatus,
  { label: string; classes: string }
> = {
  ACTIVE: {
    label: 'Activo',
    classes: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  },
  INACTIVE: {
    label: 'Inactivo',
    classes: 'bg-gray-500/20 text-gray-400 border-gray-500/30',
  },
  BLOCKED: {
    label: 'Bloqueado',
    classes: 'bg-red-500/20 text-red-400 border-red-500/30',
  },
};

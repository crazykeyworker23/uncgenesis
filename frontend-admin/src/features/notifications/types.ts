export type NotificationStatus = 'PENDING' | 'SENT' | 'FAILED';
export type TargetAudience = 'ALL' | 'LEADERS' | 'MEMBERS' | 'USER';

export interface NotificationSender {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
}

export interface Notification {
  id: number;
  title: string;
  body: string;
  sender: NotificationSender | null;
  target_audience: TargetAudience;
  target_user?: number | null;
  target_user_detail?: NotificationSender | null;
  status: NotificationStatus;
  scheduled_for: string | null;
  sent_at: string | null;
  error_message: string;
  created_at: string;
}

export interface PaginatedNotifications {
  count: number;
  next: string | null;
  previous: string | null;
  results: Notification[];
}

export const TARGET_AUDIENCE_LABELS: Record<TargetAudience, string> = {
  ALL: 'Todos los dispositivos',
  LEADERS: 'Líderes de Célula',
  MEMBERS: 'Miembros Registrados',
  USER: 'Usuario Específico (Individual)',
};

export const NOTIFICATION_STATUS_CONFIG: Record<
  NotificationStatus,
  { label: string; classes: string }
> = {
  PENDING: {
    label: 'Pendiente',
    classes: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  },
  SENT: {
    label: 'Enviado',
    classes: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  },
  FAILED: {
    label: 'Fallido',
    classes: 'bg-red-500/20 text-red-400 border-red-500/30',
  },
};

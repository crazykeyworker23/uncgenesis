export type RequestStatus = 'PENDING' | 'IN_PROGRESS' | 'RESOLVED' | 'ARCHIVED';

export type AgeRange = 'YOUTH' | 'YOUNG_ADULT' | 'ADULT' | 'SENIOR' | 'PREFER_NOT_SAY';
export type HowFound = 'SOCIAL_MEDIA' | 'FRIEND_FAMILY' | 'WEBSITE' | 'STREET' | 'EVENT' | 'OTHER';
export type PreferredContact = 'EMAIL' | 'PHONE' | 'WHATSAPP';

export const REQUEST_STATUS_CONFIG: Record<RequestStatus, { label: string; classes: string }> = {
  PENDING:     { label: 'Pendiente',   classes: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30' },
  IN_PROGRESS: { label: 'En proceso',  classes: 'bg-blue-500/20   text-blue-400   border-blue-500/30'   },
  RESOLVED:    { label: 'Resuelto',    classes: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30' },
  ARCHIVED:    { label: 'Archivado',   classes: 'bg-gray-500/20   text-gray-400   border-gray-500/30'   },
};

export const AGE_RANGE_LABELS: Record<AgeRange, string> = {
  YOUTH:          '15-25 años',
  YOUNG_ADULT:    '26-35 años',
  ADULT:          '36-50 años',
  SENIOR:         '51+ años',
  PREFER_NOT_SAY: 'Prefiero no decir',
};

export const HOW_FOUND_LABELS: Record<HowFound, string> = {
  SOCIAL_MEDIA:  'Redes sociales',
  FRIEND_FAMILY: 'Amigo o familiar',
  WEBSITE:       'Página web',
  STREET:        'Pasé por la iglesia',
  EVENT:         'Evento',
  OTHER:         'Otro',
};

export const PREFERRED_CONTACT_LABELS: Record<PreferredContact, string> = {
  EMAIL:    'Correo electrónico',
  PHONE:    'Llamada telefónica',
  WHATSAPP: 'WhatsApp',
};

export interface RequestAssignee {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
}

export interface PrayerRequest {
  id: number;
  requester_name: string;
  requester_email: string;
  requester_phone: string;
  subject: string;
  description: string;
  is_anonymous: boolean;
  status: RequestStatus;
  assigned_to: RequestAssignee | null;
  notes: string;
  created_at: string;
  updated_at: string;
}

export interface VisitorRequest {
  id: number;
  full_name: string;
  email: string;
  phone: string;
  age_range: AgeRange;
  how_did_you_find_us: HowFound;
  message: string;
  preferred_contact: PreferredContact;
  status: RequestStatus;
  assigned_to: RequestAssignee | null;
  cell_group?: { id: number; name: string; slug: string; meeting_day: string; meeting_time: string; address: string } | null;
  cell_group_id?: number | null;
  notes: string;
  created_at: string;
  updated_at: string;
}

export interface PaginatedRequests<T> {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
}

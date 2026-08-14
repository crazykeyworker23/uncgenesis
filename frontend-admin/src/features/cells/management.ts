/** Tipos y etiquetas de la gestión interna de células. */

export type AttendanceStatus = 'PRESENT' | 'ABSENT' | 'LATE' | 'EXCUSED';

export const ATTENDANCE_STATUS: Record<
  AttendanceStatus,
  { label: string; short: string; classes: string }
> = {
  PRESENT: {
    label: 'Asistió',
    short: 'A',
    classes: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40',
  },
  ABSENT: {
    label: 'No asistió',
    short: 'N',
    classes: 'bg-red-500/20 text-red-300 border-red-500/40',
  },
  LATE: {
    label: 'Tardanza',
    short: 'T',
    classes: 'bg-amber-500/20 text-amber-300 border-amber-500/40',
  },
  EXCUSED: {
    label: 'Justificado',
    short: 'J',
    classes: 'bg-blue-500/20 text-blue-300 border-blue-500/40',
  },
};

export const ATTENDANCE_ORDER: AttendanceStatus[] = ['PRESENT', 'LATE', 'EXCUSED', 'ABSENT'];

export type FollowUpType = 'CALL' | 'VISIT' | 'MESSAGE' | 'OTHER';

export const FOLLOW_UP_TYPES: Record<FollowUpType, string> = {
  CALL: 'Llamada',
  VISIT: 'Visita',
  MESSAGE: 'Mensaje',
  OTHER: 'Otro',
};

export interface CellMember {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone: string;
  location: string;
  status: string;
}

export interface MembersResponse {
  cell: { id: number; name: string; slug: string };
  count: number;
  results: CellMember[];
}

export interface AttendanceRecord {
  id: number;
  member: CellMember;
  status: AttendanceStatus;
  status_display: string;
  notes: string;
}

export interface CellMeeting {
  id: number;
  cell: number;
  cell_name: string;
  date: string;
  time: string | null;
  topic: string;
  notes: string;
  guests_count: number;
  attendees_count: number;
  attendances: AttendanceRecord[];
  registered_by: CellMember | null;
}

export interface FollowUp {
  id: number;
  cell: number;
  cell_name: string;
  member: CellMember;
  type: FollowUpType;
  type_display: string;
  date: string;
  summary: string;
  needs_attention: boolean;
  registered_by: CellMember | null;
}

export interface CellStatistics {
  cell: { id: number; name: string; slug: string };
  members_total: number;
  members_active: number;
  members_inactive: number;
  meetings_total: number;
  average_attendance: number;
  attendance_by_status: Record<AttendanceStatus, number>;
  attendance_trend: Array<{ date: string; attendees: number; topic: string }>;
  needs_attention: number;
}

/** `2026-08-05` → `5 de agosto de 2026` */
export function formatDate(value?: string | null): string {
  if (!value) return 'Sin fecha';
  const parsed = new Date(`${value}T00:00:00`);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleDateString('es-PE', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
}

export type CellReportStatus = 'DRAFT' | 'SENT' | 'REVIEWED';

export const REPORT_STATUS: Record<CellReportStatus, { label: string; classes: string }> = {
  DRAFT: {
    label: 'Borrador',
    classes: 'bg-gray-500/20 text-gray-300 border-gray-500/40',
  },
  SENT: {
    label: 'Enviado',
    classes: 'bg-amber-500/20 text-amber-300 border-amber-500/40',
  },
  REVIEWED: {
    label: 'Revisado',
    classes: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40',
  },
};

/** Qué entrega el informe: cómo fue la reunión, o la lectura del devocional. */
export type CellReportKind = 'ACTIVITY' | 'DEVOTIONAL';

export const REPORT_KIND: Record<CellReportKind, { label: string; classes: string }> = {
  ACTIVITY: {
    label: 'Actividad',
    classes: 'bg-white/5 text-crema/70 border-white/10',
  },
  DEVOTIONAL: {
    label: 'Devocional',
    classes: 'bg-dorado/15 text-dorado border-dorado/40',
  },
};

/** Una imagen del informe. Un informe admite hasta cinco. */
export interface ReportPhoto {
  id: number;
  url: string;
  caption: string;
  position: number;
}

export interface CellReport {
  id: number;
  cell: number;
  cell_name: string;
  kind: CellReportKind;
  kind_display: string;
  /** Las imágenes adjuntas, en el orden en que se subieron. */
  photos: ReportPhoto[];
  period_start: string;
  period_end: string;
  summary: string;
  highlights: string;
  challenges: string;
  prayer_needs: string;
  /** La foto única de los informes entregados antes de admitir varias. */
  photo_url: string | null;
  photo_caption: string;
  /** Cifras que se congelaban al enviar. Ya no se calculan ni se muestran:
   *  las conservan los informes entregados antes del cambio. */
  meetings_held: number;
  average_attendance: number;
  new_members: number;
  status: CellReportStatus;
  status_display: string;
  submitted_by: CellMember | null;
  sent_at: string | null;
  reviewed_by: CellMember | null;
  reviewed_at: string | null;
  review_notes: string;
}

/** Todo lo que hay que mostrar del informe, contando la foto única de los
 *  entregados antes del cambio. */
export function reportImages(report: CellReport): string[] {
  const urls = report.photos?.map((photo) => photo.url).filter(Boolean) ?? [];
  if (urls.length) return urls;
  return report.photo_url ? [report.photo_url] : [];
}

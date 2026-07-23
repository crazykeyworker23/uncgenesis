export type CellStatus = 'ACTIVE' | 'INACTIVE';

export type MeetingDay =
  | 'MONDAY'
  | 'TUESDAY'
  | 'WEDNESDAY'
  | 'THURSDAY'
  | 'FRIDAY'
  | 'SATURDAY'
  | 'SUNDAY';

export const MEETING_DAY_LABELS: Record<MeetingDay, string> = {
  MONDAY: 'Lunes',
  TUESDAY: 'Martes',
  WEDNESDAY: 'Miércoles',
  THURSDAY: 'Jueves',
  FRIDAY: 'Viernes',
  SATURDAY: 'Sábado',
  SUNDAY: 'Domingo',
};

export interface CellLeader {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
}

export interface CellGroup {
  id: number;
  name: string;
  slug: string;
  leader: CellLeader | null;
  leader_id?: number | null;
  meeting_day: MeetingDay;
  meeting_time: string; // HH:MM:SS
  address: string;
  latitude: string | null;
  longitude: string | null;
  description: string;
  status: CellStatus;
  created_at: string;
  updated_at: string;
}

export interface PaginatedCells {
  count: number;
  next: string | null;
  previous: string | null;
  results: CellGroup[];
}

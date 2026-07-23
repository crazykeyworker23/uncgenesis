import { AuthorProfile } from '../publications/types';

export type EventStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED' | 'CANCELLED';
export type EventRegistrationStatus = 'CONFIRMED' | 'CANCELLED' | 'ATTENDED';

export interface Event {
  id: number;
  title: string;
  slug: string;
  description: string;
  cover_image: string | null;
  start_date: string;
  end_date: string;
  location: string;
  latitude: number | null;
  longitude: number | null;
  capacity: number | null;
  requires_registration: boolean;
  status: EventStatus;
  created_at: string;
  updated_at: string;
  registered_count: number;
}

export interface EventRegistration {
  id: number;
  event: number;
  user: AuthorProfile;
  registered_at: string;
  status: EventRegistrationStatus;
}

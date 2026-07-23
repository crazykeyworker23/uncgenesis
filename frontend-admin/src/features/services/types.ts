export interface ServiceVerse {
  id?: number;
  book: string;
  chapter: number;
  verses: string;
  text: string;
}

export type ServiceStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

export interface ChurchService {
  id: number;
  title: string;
  slug: string;
  date: string;
  video_url: string | null;
  audio_url: string | null;
  sermon_notes: string;
  views_count: number;
  is_live: boolean;
  status: ServiceStatus;
  created_at: string;
  updated_at: string;
  verses: ServiceVerse[];
}

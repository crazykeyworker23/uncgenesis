import { AuthorProfile } from '../publications/types';

export type DevotionalStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

export interface Devotional {
  id: number;
  title: string;
  slug: string;
  date: string;
  bible_passage: string;
  bible_text: string;
  content: string;
  audio_url: string | null;
  author: AuthorProfile;
  status: DevotionalStatus;
  views_count: number;
  created_at: string;
  updated_at: string;
}

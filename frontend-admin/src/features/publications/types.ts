export interface PublicationCategory {
  id: number;
  name: string;
  slug: string;
  description: string;
  created_at: string;
}

export interface PublicationTag {
  id: number;
  name: string;
  slug: string;
  created_at: string;
}

export interface PublicationGallery {
  id: number;
  publication: number;
  image: string;
  order: number;
  caption: string;
  created_at: string;
}

export type PublicationContentType = 'NEWS' | 'SERVICE' | 'DEVOTIONAL' | 'EVENT' | 'YOUTH' | 'GENERAL';

export type PublicationStatus = 'DRAFT' | 'SCHEDULED' | 'PUBLISHED' | 'ARCHIVED';

export interface AuthorProfile {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  avatar: string | null;
}

export interface Publication {
  id: number;
  title: string;
  slug: string;
  summary: string;
  content: string;
  cover_image: string | null;
  category: PublicationCategory | null;
  content_type: PublicationContentType;
  author: AuthorProfile;
  status: PublicationStatus;
  published_at: string | null;
  scheduled_at: string | null;
  is_featured: boolean;
  show_in_app: boolean;
  send_notification: boolean;
  views_count: number;
  seo_title: string;
  seo_description: string;
  created_at: string;
  updated_at: string;
  tags: PublicationTag[];
  gallery_images: PublicationGallery[];
}

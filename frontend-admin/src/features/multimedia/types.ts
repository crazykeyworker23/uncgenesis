export type MediaType = 'IMAGE' | 'PDF' | 'AUDIO' | 'VIDEO' | 'OTHER';

export interface MultimediaUploader {
  id: number;
  email: string;
  full_name: string;
}

export interface Multimedia {
  id: number;
  title: string;
  file: string;
  file_type: MediaType;
  file_size: number;
  uploaded_by: MultimediaUploader | null;
  file_url: string;
  created_at: string;
  updated_at: string;
}

export interface PaginatedMultimedia {
  count: number;
  next: string | null;
  previous: string | null;
  results: Multimedia[];
}

export const MEDIA_TYPE_LABELS: Record<MediaType, string> = {
  IMAGE: 'Imagen',
  PDF: 'Documento PDF',
  AUDIO: 'Audio',
  VIDEO: 'Video',
  OTHER: 'Otro / Archivo',
};

export const MEDIA_TYPE_COLORS: Record<MediaType, string> = {
  IMAGE: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
  PDF: 'bg-red-500/10 text-red-400 border-red-500/20',
  AUDIO: 'bg-violet-500/10 text-violet-400 border-violet-500/20',
  VIDEO: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
  OTHER: 'bg-gray-500/10 text-gray-400 border-gray-500/20',
};

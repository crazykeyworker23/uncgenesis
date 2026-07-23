export interface AppSettings {
  id?: number;
  app_name: string;
  app_description: string;
  splash_text: string;
  logo: string | null;
  primary_color: string;
  secondary_color: string;
  privacy_policy_url: string;
  terms_url: string;
}

export interface ChurchSettings {
  id?: number;
  church_name: string;
  address: string;
  city: string;
  country: string;
  phone: string;
  whatsapp: string;
  email: string;
  website: string;
  latitude: string | null;
  longitude: string | null;
}

export interface ServiceSchedule {
  id?: number;
  day_of_week: 'MONDAY' | 'TUESDAY' | 'WEDNESDAY' | 'THURSDAY' | 'FRIDAY' | 'SATURDAY' | 'SUNDAY';
  day_of_week_display?: string;
  start_time: string;
  title: string;
  description: string;
}

export interface SocialNetwork {
  id?: number;
  name: string;
  url: string;
  icon_name: string;
}

import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface UserProfile {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone: string;
  avatar: string | null;
  location: string;
  bio: string;
  status: string;
}

interface AuthState {
  user: UserProfile | null;
  accessToken: string | null;
  refreshToken: string | null;
  isAuthenticated: boolean;
  login: (user: UserProfile, access: string, refresh: string) => void;
  logout: () => void;
  updateAccessToken: (access: string) => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,
      login: (user, access, refresh) => set({
        user,
        accessToken: access,
        refreshToken: refresh,
        isAuthenticated: true
      }),
      logout: () => set({
        user: null,
        accessToken: null,
        refreshToken: null,
        isAuthenticated: false
      }),
      updateAccessToken: (access) => set({
        accessToken: access
      })
    }),
    {
      name: 'genesis-auth-store', // key in localStorage
    }
  )
);

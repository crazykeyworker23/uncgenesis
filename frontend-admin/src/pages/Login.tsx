import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate, Navigate } from 'react-router-dom';
import { Mail, Lock, LogIn, AlertCircle } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { apiClient } from '../api/client';
import { Logo } from '../components/ui/Logo';
import { PasswordInput } from '../components/ui/PasswordInput';

export const Login: React.FC = () => {
  const navigate = useNavigate();
  const { login, isAuthenticated } = useAuthStore();
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const { register, handleSubmit, formState: { errors } } = useForm({
    defaultValues: {
      email: '',
      password: '',
      rememberMe: false
    }
  });

  // If already authenticated, redirect to dashboard
  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />;
  }

  const onSubmit = async (data: any) => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const response = await apiClient.post('/auth/login/', {
        email: data.email,
        password: data.password
      });

      const { user, access, refresh } = response.data;

      if (user.status !== 'ACTIVE') {
        throw new Error('Tu cuenta no se encuentra activa.');
      }

      // El panel es del pastorado y de quien produce contenido o atiende
      // solicitudes. El resto —miembros, y también líderes y coordinadores—
      // tiene credenciales válidas, pero su lugar es la app móvil.
      if (!user.can_access_admin) {
        throw new Error(
          'Esta cuenta no tiene acceso al panel administrativo. Ingresa desde la aplicación móvil Génesis.'
        );
      }

      login(user, access, refresh);
      navigate('/dashboard');
    } catch (err: any) {
      const msg = err.response?.data?.detail || err.response?.data?.non_field_errors?.[0] || err.message || 'Error al iniciar sesión. Inténtalo de nuevo.';
      setErrorMsg(typeof msg === 'string' ? msg : 'Credenciales inválidas.');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleLogin = async () => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const response = await apiClient.post('/auth/google/', {
        id_token: 'mock-google-token' // Send mock token for initial Phase 0/3 verification
      });

      const { user, access, refresh } = response.data;

      if (!user.can_access_admin) {
        throw new Error(
          'Esta cuenta no tiene acceso al panel administrativo. Ingresa desde la aplicación móvil Génesis.'
        );
      }

      login(user, access, refresh);
      navigate('/dashboard');
    } catch (err: any) {
      setErrorMsg(err.response?.data?.detail || err.message || 'Error al conectar con Google.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen px-4">
      {/* Decorative blurred blobs */}
      <div className="absolute top-1/4 left-1/4 w-72 h-72 bg-dorado rounded-full mix-blend-multiply filter blur-[90px] opacity-10 animate-pulse" />
      <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-dark-teal rounded-full mix-blend-multiply filter blur-[100px] opacity-30 animate-pulse" />

      {/* Login Box */}
      <div className="w-full max-w-md z-10">
        <div className="glass-panel p-8 bg-dark-teal bg-opacity-35">
          {/* Logo & Header */}
          <div className="flex flex-col items-center mb-8">
            <Logo size={64} variant="gold" className="mb-4 glowing-gold rounded-lg" />
            <h1 className="text-2xl font-extrabold text-dorado tracking-wider">GÉNESIS</h1>
            <p className="text-xs text-crema text-opacity-50 mt-1">Panel de Control de la Iglesia y Comunidad</p>
          </div>

          {/* Error Message */}
          {errorMsg && (
            <div className="flex items-center gap-2 p-3.5 mb-6 bg-error-red bg-opacity-15 text-error-red border border-error-red border-opacity-20 rounded-xl text-xs">
              <AlertCircle size={16} className="shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
            {/* Email Field */}
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Correo Electrónico</label>
              <div className="relative">
                <Mail size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-crema text-opacity-35" />
                <input
                  type="email"
                  placeholder="admin@genesisapp.org"
                  className="w-full pl-11 glass-input text-xs"
                  {...register('email', { 
                    required: 'El correo electrónico es obligatorio',
                    pattern: {
                      value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                      message: 'El formato de correo es inválido'
                    }
                  })}
                />
              </div>
              {errors.email && (
                <span className="text-[10px] text-error-red font-medium ml-1">{errors.email.message}</span>
              )}
            </div>

            {/* Password Field */}
            <div className="space-y-1.5">
              <div className="flex justify-between items-center px-1">
                <label className="text-xs font-semibold text-crema text-opacity-65">Contraseña</label>
                <a href="#" className="text-[10px] text-dorado hover:underline">¿Olvidaste tu contraseña?</a>
              </div>
              <div className="relative">
                <Lock size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-crema text-opacity-35 z-10" />
                <PasswordInput
                  placeholder="••••••••"
                  className="w-full pl-11 glass-input text-xs"
                  {...register('password', { required: 'La contraseña es obligatoria' })}
                />
              </div>
              {errors.password && (
                <span className="text-[10px] text-error-red font-medium ml-1">{errors.password.message}</span>
              )}
            </div>

            {/* Remember Me */}
            <div className="flex items-center justify-between px-1 py-1">
              <label className="flex items-center gap-2 text-[10px] text-crema text-opacity-60 cursor-pointer select-none">
                <input
                  type="checkbox"
                  className="accent-dorado w-3.5 h-3.5 rounded border-white border-opacity-10 bg-deep-teal focus:ring-0"
                  {...register('rememberMe')}
                />
                Recordarme
              </label>
            </div>

            {/* Sign In Button */}
            <button
              type="submit"
              disabled={loading}
              className="flex items-center justify-center gap-2 w-full btn-primary text-xs font-bold mt-2"
            >
              {loading ? (
                <div className="w-4 h-4 border-2 border-deep-teal border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <LogIn size={16} />
                  Iniciar Sesión
                </>
              )}
            </button>
          </form>

          {/* Divider */}
          <div className="relative flex items-center justify-center my-6">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-white border-opacity-5" />
            </div>
            <span className="relative px-3 bg-dark-teal bg-opacity-0 text-[10px] text-crema text-opacity-40 uppercase tracking-widest">O accede con</span>
          </div>

          {/* Google Login */}
          <button
            onClick={handleGoogleLogin}
            disabled={loading}
            className="flex items-center justify-center gap-2.5 w-full btn-secondary text-xs hover:bg-white hover:bg-opacity-5"
          >
            {/* Google Icon SVG */}
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
              <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.56-2.77c-.98.66-2.23 1.06-3.72 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
              <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l3.66-2.85z" fill="#FBBC05"/>
              <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.85c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
            </svg>
            Acceder con Google
          </button>
        </div>
      </div>
    </div>
  );
};

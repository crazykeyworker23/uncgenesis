import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate, Link } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { ArrowLeft, Save, Bell, Users, Clock, Info, Zap, Calendar, Send } from 'lucide-react';
import { apiClient } from '../api/client';
import { Logo } from '../components/ui/Logo';

// ── Mobile Push Notification Preview ────────────────────────────────────────
interface MobilePreviewProps {
  title: string;
  body: string;
}

const MobilePreview: React.FC<MobilePreviewProps> = ({ title, body }) => {
  const displayTitle = title.trim() || 'Título de la Notificación';
  const displayBody = body.trim() || 'Este es el cuerpo del mensaje push. Aquí aparecerá el contenido redactado.';
  const currentTime = new Date().toLocaleTimeString('es-PE', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  });

  return (
    <div className="w-[300px] h-[550px] mx-auto rounded-[40px] border-[10px] border-dark-teal bg-deep-teal shadow-2xl relative overflow-hidden flex flex-col select-none">
      {/* Notch */}
      <div className="absolute top-2 left-1/2 -translate-x-1/2 w-32 h-4 bg-dark-teal rounded-full z-30 flex items-center justify-center">
        <div className="w-2.5 h-2.5 bg-black rounded-full ml-auto mr-4 border border-white/10" />
      </div>

      {/* Lockscreen Wallpaper & Content */}
      <div 
        className="flex-1 bg-cover bg-center flex flex-col p-4 relative"
        style={{ 
          backgroundImage: 'linear-gradient(to bottom, rgba(15, 23, 42, 0.8), rgba(2, 44, 34, 0.95)), url("https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?q=80&w=300&auto=format&fit=crop")' 
        }}
      >
        {/* Time and Date */}
        <div className="text-center mt-12 space-y-1">
          <p className="text-white text-4xl font-extrabold tracking-tight">{currentTime}</p>
          <p className="text-[10px] text-teal-300 uppercase tracking-widest font-semibold">
            {new Date().toLocaleDateString('es-PE', { weekday: 'long', day: 'numeric', month: 'long' })}
          </p>
        </div>

        {/* Push Notification Banner */}
        <div className="mt-14 w-full bg-slate-900/90 backdrop-blur-xl border border-white/10 rounded-2xl p-3 shadow-xl transition-all duration-300 transform scale-100 hover:scale-[1.02] flex gap-2.5">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-dorado to-yellow-600 flex items-center justify-center shrink-0 shadow-md">
            <Logo size={20} variant="dark" />
          </div>
          <div className="flex-1 min-w-0 text-left">
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-bold text-dorado uppercase tracking-wide">Génesis App</span>
              <span className="text-[8px] text-white/50">ahora</span>
            </div>
            <p className="text-xs font-bold text-white leading-tight mt-0.5 truncate">{displayTitle}</p>
            <p className="text-[10px] text-white/80 leading-normal mt-0.5 line-clamp-3 whitespace-pre-wrap">{displayBody}</p>
          </div>
        </div>

        {/* Lockscreen Bottom Controls */}
        <div className="mt-auto flex justify-between px-6 pb-4">
          <div className="w-10 h-10 rounded-full bg-white/10 backdrop-blur-md flex items-center justify-center border border-white/5 hover:bg-white/20 transition-all cursor-pointer">
            <span className="text-sm">🔦</span>
          </div>
          <div className="w-10 h-10 rounded-full bg-white/10 backdrop-blur-md flex items-center justify-center border border-white/5 hover:bg-white/20 transition-all cursor-pointer">
            <span className="text-sm">📷</span>
          </div>
        </div>

        {/* Bottom Swipe bar */}
        <div className="pb-1 pt-1 flex justify-center">
          <div className="w-24 h-1 bg-white/40 rounded-full" />
        </div>
      </div>
    </div>
  );
};

// ── Form Page Component ─────────────────────────────────────────────────────
export const NotificationForm: React.FC = () => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [sendMode, setSendMode] = useState<'IMMEDIATE' | 'SCHEDULED'>('IMMEDIATE');

  const { register, handleSubmit, watch, setValue, formState: { errors } } = useForm({
    defaultValues: {
      title: '',
      body: '',
      target_audience: 'ALL',
      target_user: '',
      scheduled_for: '',
    }
  });

  const watchedTitle = watch('title');
  const watchedBody = watch('body');
  const watchedAudience = watch('target_audience');

  // Fetch users for individual targeting
  const { data: usersData, isLoading: isLoadingUsers } = useQuery({
    queryKey: ['users-list-for-notifications'],
    queryFn: async () => {
      const res = await apiClient.get('/users/', { params: { page_size: 100 } });
      return res.data;
    },
    enabled: watchedAudience === 'USER',
  });

  const usersList = usersData?.results || [];

  // Mutation for creating notifications
  const createMutation = useMutation({
    mutationFn: async (formData: any) => {
      const payload: any = {
        title: formData.title,
        body: formData.body,
        target_audience: formData.target_audience,
        scheduled_for: sendMode === 'SCHEDULED' ? (formData.scheduled_for || null) : null,
      };
      if (formData.target_audience === 'USER' && formData.target_user) {
        payload.target_user = parseInt(formData.target_user, 10);
      }
      return apiClient.post('/notifications/', payload);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      navigate('/notificaciones');
    },
    onError: (err: any) => {
      const details = err.response?.data;
      if (typeof details === 'object') {
        const msg = Object.entries(details)
          .map(([key, val]) => `${key}: ${Array.isArray(val) ? val.join(', ') : val}`)
          .join(' | ');
        setErrorMsg(msg);
      } else {
        setErrorMsg('Error de red al guardar la notificación.');
      }
    }
  });

  const onSubmit = (data: any) => {
    setErrorMsg(null);
    createMutation.mutate(data);
  };

  return (
    <div className="flex gap-8 items-start">
      {/* Form Container */}
      <div className="flex-1 space-y-6">
        {/* Header */}
        <div className="flex items-center gap-3">
          <Link
            to="/notificaciones"
            id="notification-form-back"
            className="p-2 text-gray-400 hover:text-white hover:bg-gray-800 rounded-xl transition-all"
          >
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-white">Redactar Notificación Push</h1>
            <p className="text-sm text-crema text-opacity-50 mt-0.5">
              Envía un mensaje de alerta a los dispositivos móviles (de inmediato o programado)
            </p>
          </div>
        </div>

        {/* Error Alert */}
        {errorMsg && (
          <div className="p-4 bg-red-950/30 border border-red-900/40 rounded-xl text-red-300 text-xs flex items-center gap-2">
            <Info className="w-4 h-4 text-red-400 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* Form Body */}
        <form onSubmit={handleSubmit(onSubmit)} className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl space-y-5">
          {/* Send Mode Selector */}
          <div className="space-y-2">
            <label className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
              Modo de Envío del Mensaje *
            </label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <button
                type="button"
                id="send-mode-immediate"
                onClick={() => {
                  setSendMode('IMMEDIATE');
                  setValue('scheduled_for', '');
                }}
                className={`p-3.5 rounded-xl border transition-all text-left flex items-start gap-3 ${
                  sendMode === 'IMMEDIATE'
                    ? 'bg-teal-900/40 border-dorado text-white shadow-lg'
                    : 'bg-deep-teal/20 border-white/10 text-crema/60 hover:border-white/20'
                }`}
              >
                <div className={`p-2 rounded-lg ${sendMode === 'IMMEDIATE' ? 'bg-dorado/20 text-dorado' : 'bg-white/5 text-gray-400'}`}>
                  <Zap className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs font-bold text-white">Enviar de Inmediato</p>
                  <p className="text-[10px] text-crema/60 mt-0.5">Envía el mensaje push a los teléfonos al instante al guardar.</p>
                </div>
              </button>

              <button
                type="button"
                id="send-mode-scheduled"
                onClick={() => setSendMode('SCHEDULED')}
                className={`p-3.5 rounded-xl border transition-all text-left flex items-start gap-3 ${
                  sendMode === 'SCHEDULED'
                    ? 'bg-teal-900/40 border-dorado text-white shadow-lg'
                    : 'bg-deep-teal/20 border-white/10 text-crema/60 hover:border-white/20'
                }`}
              >
                <div className={`p-2 rounded-lg ${sendMode === 'SCHEDULED' ? 'bg-dorado/20 text-dorado' : 'bg-white/5 text-gray-400'}`}>
                  <Calendar className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs font-bold text-white">Programar Envío Futuro</p>
                  <p className="text-[10px] text-crema/60 mt-0.5">Establece una fecha y hora específica para su despacho.</p>
                </div>
              </button>
            </div>
          </div>

          {/* Title */}
          <div className="space-y-1.5">
            <label htmlFor="notification-title" className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
              <Bell className="inline w-3.5 h-3.5 mr-1 text-dorado" />
              Título de la Notificación *
            </label>
            <input
              id="notification-title"
              type="text"
              placeholder="ej. ¡Servicio Especial de Domingo!"
              className={`w-full px-4 py-2.5 bg-deep-teal bg-opacity-40 border rounded-xl text-white placeholder-crema placeholder-opacity-35 text-xs focus:outline-none transition-all ${
                errors.title ? 'border-red-500 focus:border-red-400' : 'border-white border-opacity-10 focus:border-dorado'
              }`}
              {...register('title', { required: 'El título es obligatorio' })}
            />
            {errors.title && (
              <p className="text-[10px] text-red-400 font-medium ml-1">{errors.title.message}</p>
            )}
          </div>

          {/* Body/Message */}
          <div className="space-y-1.5">
            <label htmlFor="notification-body" className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
              Mensaje principal (Cuerpo) *
            </label>
            <textarea
              id="notification-body"
              rows={4}
              placeholder="Escribe el mensaje que llegará al móvil..."
              className={`w-full px-4 py-2.5 bg-deep-teal bg-opacity-40 border rounded-xl text-white placeholder-crema placeholder-opacity-35 text-xs focus:outline-none transition-all resize-none ${
                errors.body ? 'border-red-500' : 'border-white border-opacity-10 focus:border-dorado'
              }`}
              {...register('body', { required: 'El mensaje es obligatorio' })}
            />
            {errors.body && (
              <p className="text-[10px] text-red-400 font-medium ml-1">{errors.body.message}</p>
            )}
          </div>

          {/* Target Audience & Scheduled DateTime */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Target Audience */}
            <div className="space-y-1.5">
              <label htmlFor="notification-audience" className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
                <Users className="inline w-3.5 h-3.5 mr-1 text-dorado" />
                Destinatarios (Audiencia)
              </label>
              <select
                id="notification-audience"
                className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-crema focus:outline-none focus:border-dorado focus:ring-1 focus:ring-dorado"
                {...register('target_audience')}
              >
                <option value="ALL" className="bg-gray-900 text-crema">Todos los dispositivos (Masivo)</option>
                <option value="LEADERS" className="bg-gray-900 text-crema">Líderes de Célula (LEADERS)</option>
                <option value="MEMBERS" className="bg-gray-900 text-crema">Miembros Registrados (MEMBERS)</option>
                <option value="USER" className="bg-gray-900 text-crema">Usuario Específico (Por Persona)</option>
              </select>
            </div>

            {/* Scheduled For input (only when sendMode === 'SCHEDULED') */}
            {sendMode === 'SCHEDULED' ? (
              <div className="space-y-1.5 animate-fadeIn">
                <label htmlFor="notification-schedule" className="block text-xs font-semibold text-dorado ml-1">
                  <Clock className="inline w-3.5 h-3.5 mr-1 text-dorado" />
                  Fecha y Hora de Envío *
                </label>
                <input
                  id="notification-schedule"
                  type="datetime-local"
                  className={`w-full px-4 py-2.5 bg-deep-teal bg-opacity-40 border text-white rounded-xl text-xs focus:outline-none focus:border-dorado focus:ring-1 focus:ring-dorado ${
                    errors.scheduled_for ? 'border-red-500' : 'border-white border-opacity-10'
                  }`}
                  {...register('scheduled_for', {
                    validate: (val) => sendMode !== 'SCHEDULED' || !!val || 'Debes ingresar fecha y hora programada'
                  })}
                />
                {errors.scheduled_for && (
                  <p className="text-[10px] text-red-400 font-medium ml-1">{errors.scheduled_for.message as string}</p>
                )}
              </div>
            ) : (
              <div className="p-3 bg-teal-950/40 border border-teal-800/40 rounded-xl flex items-center gap-2.5 text-xs text-teal-300">
                <Zap className="w-4 h-4 text-dorado shrink-0 animate-pulse" />
                <span><strong>Envío inmediato:</strong> El mensaje se enviará a los dispositivos móviles sin demoras al guardar.</span>
              </div>
            )}
          </div>

          {/* Individual User Selector when target_audience === 'USER' */}
          {watchedAudience === 'USER' && (
            <div className="space-y-1.5 animate-fadeIn">
              <label htmlFor="notification-user" className="block text-xs font-semibold text-dorado ml-1">
                Seleccionar Persona (Usuario Destinatario) *
              </label>
              <select
                id="notification-user"
                className={`w-full bg-deep-teal bg-opacity-40 border rounded-xl px-4 py-2.5 text-xs text-white focus:outline-none focus:border-dorado focus:ring-1 focus:ring-dorado ${
                  errors.target_user ? 'border-red-500' : 'border-white border-opacity-10'
                }`}
                {...register('target_user', {
                  validate: (val) => watchedAudience !== 'USER' || !!val || 'Debes seleccionar un usuario destinatario'
                })}
              >
                <option value="" className="bg-gray-900 text-gray-400">
                  {isLoadingUsers ? 'Cargando lista de usuarios...' : '-- Seleccionar usuario destinatario --'}
                </option>
                {usersList.map((usr: any) => (
                  <option key={usr.id} value={usr.id} className="bg-gray-900 text-white">
                    {usr.full_name || `${usr.first_name} ${usr.last_name}`} ({usr.email})
                  </option>
                ))}
              </select>
              {errors.target_user && (
                <p className="text-[10px] text-red-400 font-medium ml-1">{errors.target_user.message as string}</p>
              )}
            </div>
          )}

          {/* Form Actions */}
          <div className="flex items-center gap-3 pt-4 border-t border-white border-opacity-5">
            <button
              id="notification-form-submit"
              type="submit"
              disabled={createMutation.isPending}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-teal-600 hover:bg-teal-500 disabled:opacity-60 text-white rounded-xl text-xs font-bold transition-all shadow"
            >
              {createMutation.isPending ? (
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : sendMode === 'IMMEDIATE' ? (
                <Send className="w-4 h-4" />
              ) : (
                <Save className="w-4 h-4" />
              )}
              {sendMode === 'IMMEDIATE' ? 'Enviar Notificación Ahora' : 'Programar Notificación'}
            </button>
            <button
              id="notification-form-cancel"
              type="button"
              onClick={() => navigate('/notificaciones')}
              className="px-4 py-2.5 text-crema text-opacity-50 hover:text-white text-xs font-semibold transition-colors"
            >
              Cancelar
            </button>
          </div>
        </form>
      </div>

      {/* Live Preview Container */}
      <div className="hidden xl:flex flex-col items-center gap-4 sticky top-6">
        <p className="text-xs text-crema text-opacity-50 uppercase tracking-widest font-semibold">
          Vista Previa Push (Móvil)
        </p>
        <MobilePreview title={watchedTitle} body={watchedBody} />
        <p className="text-[10px] text-crema text-opacity-40 text-center max-w-[220px]">
          Esta es una simulación visual de cómo se recibirá el mensaje en el teléfono de los usuarios
        </p>
      </div>
    </div>
  );
};

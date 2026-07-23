import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Settings, Building2, Smartphone, Calendar, Share2,
  Save, Plus, Trash2, Globe, MapPin, Upload,
  ShieldAlert
} from 'lucide-react';
import { apiClient } from '../api/client';
import { AppSettings, ChurchSettings, ServiceSchedule, SocialNetwork } from '../features/settings/types';

export const Configuracion: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'church' | 'app' | 'schedules' | 'socials'>('church');

  // React Query for loading configuration
  const { data: churchData, refetch: refetchChurch } = useQuery<ChurchSettings>({
    queryKey: ['settings-church'],
    queryFn: async () => {
      const res = await apiClient.get('/settings/church/');
      return res.data;
    }
  });

  const { data: appData, refetch: refetchApp } = useQuery<AppSettings>({
    queryKey: ['settings-app'],
    queryFn: async () => {
      const res = await apiClient.get('/settings/app/');
      return res.data;
    }
  });

  const { data: schedules, refetch: refetchSchedules } = useQuery<ServiceSchedule[]>({
    queryKey: ['settings-schedules'],
    queryFn: async () => {
      const res = await apiClient.get('/settings/schedules/');
      return res.data;
    }
  });

  const { data: socialNetworks, refetch: refetchSocials } = useQuery<SocialNetwork[]>({
    queryKey: ['settings-socials'],
    queryFn: async () => {
      const res = await apiClient.get('/settings/social-networks/');
      return res.data;
    }
  });

  // Local form states
  const [churchForm, setChurchForm] = useState<Partial<ChurchSettings>>({});
  const [appForm, setAppForm] = useState<Partial<AppSettings>>({});
  const [logoFile, setLogoFile] = useState<File | null>(null);
  const [logoPreview, setLogoPreview] = useState<string | null>(null);

  // Schedules form state
  const [showScheduleForm, setShowScheduleForm] = useState(false);
  const [newSchedule, setNewSchedule] = useState<Partial<ServiceSchedule>>({
    day_of_week: 'SUNDAY',
    start_time: '10:00:00',
    title: '',
    description: ''
  });

  // Social networks form state
  const [showSocialForm, setShowSocialForm] = useState(false);
  const [newSocial, setNewSocial] = useState<Partial<SocialNetwork>>({
    name: '',
    url: '',
    icon_name: 'globe'
  });

  // Initialize forms when data arrives
  React.useEffect(() => {
    if (churchData) setChurchForm(churchData);
  }, [churchData]);

  React.useEffect(() => {
    if (appData) {
      setAppForm(appData);
      setLogoPreview(appData.logo);
    }
  }, [appData]);

  // Actions
  const handleSaveChurch = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiClient.put('/settings/church/', churchForm);
      alert('Información de la iglesia actualizada con éxito.');
      refetchChurch();
    } catch (err) {
      alert('Error al guardar la información de la iglesia.');
    }
  };

  const handleSaveApp = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const formData = new FormData();
      formData.append('app_name', appForm.app_name || '');
      formData.append('app_description', appForm.app_description || '');
      formData.append('splash_text', appForm.splash_text || '');
      formData.append('primary_color', appForm.primary_color || '#032F2F');
      formData.append('secondary_color', appForm.secondary_color || '#D4AF37');
      formData.append('privacy_policy_url', appForm.privacy_policy_url || '');
      formData.append('terms_url', appForm.terms_url || '');
      if (logoFile) {
        formData.append('logo', logoFile);
      }

      await apiClient.put('/settings/app/', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      alert('Configuración de la aplicación móvil guardada correctamente.');
      refetchApp();
    } catch (err) {
      alert('Error al actualizar la configuración de la aplicación.');
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setLogoFile(file);
      setLogoPreview(URL.createObjectURL(file));
    }
  };

  const handleAddSchedule = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiClient.post('/settings/schedules/', newSchedule);
      alert('Horario de culto registrado con éxito.');
      setShowScheduleForm(false);
      setNewSchedule({ day_of_week: 'SUNDAY', start_time: '10:00:00', title: '', description: '' });
      refetchSchedules();
    } catch (err) {
      alert('Error al agregar el horario de servicio.');
    }
  };

  const handleDeleteSchedule = async (id: number) => {
    if (!confirm('¿Estás seguro de eliminar este horario de culto?')) return;
    try {
      await apiClient.delete(`/settings/schedules/${id}/`);
      refetchSchedules();
    } catch (err) {
      alert('Error al eliminar el horario.');
    }
  };

  const handleAddSocial = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiClient.post('/settings/social-networks/', newSocial);
      alert('Enlace de red social agregado con éxito.');
      setShowSocialForm(false);
      setNewSocial({ name: '', url: '', icon_name: 'globe' });
      refetchSocials();
    } catch (err) {
      alert('Error al agregar la red social.');
    }
  };

  const handleDeleteSocial = async (id: number) => {
    if (!confirm('¿Estás seguro de desvincular esta red social?')) return;
    try {
      await apiClient.delete(`/settings/social-networks/${id}/`);
      refetchSocials();
    } catch (err) {
      alert('Error al eliminar la red social.');
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold text-white flex items-center gap-2">
          <Settings className="w-6 h-6 text-dorado" />
          Configuración General
        </h1>
        <p className="text-sm text-crema text-opacity-50 mt-1">
          Administra la identidad de la aplicación, el directorio de la iglesia, horarios y enlaces de redes sociales
        </p>
      </div>

      {/* Tabs Layout */}
      <div className="flex flex-col lg:flex-row gap-6">
        {/* Navigation Sidebar Tabs */}
        <div className="w-full lg:w-64 flex flex-row lg:flex-col gap-2 overflow-x-auto lg:overflow-x-visible pb-2 lg:pb-0 border-b lg:border-b-0 lg:border-r border-white border-opacity-5">
          <button
            onClick={() => setActiveTab('church')}
            className={`flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
              activeTab === 'church'
                ? 'bg-dorado bg-opacity-10 text-dorado border-l-2 border-dorado'
                : 'text-crema text-opacity-65 hover:bg-deep-teal hover:text-white'
            }`}
          >
            <Building2 className="w-4 h-4" />
            Información Iglesia
          </button>
          <button
            onClick={() => setActiveTab('app')}
            className={`flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
              activeTab === 'app'
                ? 'bg-dorado bg-opacity-10 text-dorado border-l-2 border-dorado'
                : 'text-crema text-opacity-65 hover:bg-deep-teal hover:text-white'
            }`}
          >
            <Smartphone className="w-4 h-4" />
            Personalización App
          </button>
          <button
            onClick={() => setActiveTab('schedules')}
            className={`flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
              activeTab === 'schedules'
                ? 'bg-dorado bg-opacity-10 text-dorado border-l-2 border-dorado'
                : 'text-crema text-opacity-65 hover:bg-deep-teal hover:text-white'
            }`}
          >
            <Calendar className="w-4 h-4" />
            Horarios de Servicios
          </button>
          <button
            onClick={() => setActiveTab('socials')}
            className={`flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
              activeTab === 'socials'
                ? 'bg-dorado bg-opacity-10 text-dorado border-l-2 border-dorado'
                : 'text-crema text-opacity-65 hover:bg-deep-teal hover:text-white'
            }`}
          >
            <Share2 className="w-4 h-4" />
            Redes Sociales
          </button>
        </div>

        {/* Dynamic Panels */}
        <div className="flex-1">
          {/* 1. Church Settings Tab */}
          {activeTab === 'church' && (
            <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl">
              <div className="border-b border-white/5 pb-4 mb-6">
                <h2 className="text-base font-bold text-white flex items-center gap-2">
                  <Building2 className="w-5 h-5 text-dorado" />
                  Información Institucional de la Iglesia
                </h2>
                <p className="text-xs text-crema text-opacity-50 mt-0.5">
                  Establece la sede, medios de contacto y localización para la visualización pública
                </p>
              </div>

              <form onSubmit={handleSaveChurch} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div className="space-y-2">
                    <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Nombre de la Iglesia</label>
                    <input
                      type="text"
                      required
                      value={churchForm.church_name || ''}
                      onChange={e => setChurchForm({ ...churchForm, church_name: e.target.value })}
                      className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white placeholder-crema/20 focus:border-dorado focus:outline-none"
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Sitio Web Oficial</label>
                    <input
                      type="url"
                      required
                      value={churchForm.website || ''}
                      onChange={e => setChurchForm({ ...churchForm, website: e.target.value })}
                      className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Correo de Contacto</label>
                    <input
                      type="email"
                      required
                      value={churchForm.email || ''}
                      onChange={e => setChurchForm({ ...churchForm, email: e.target.value })}
                      className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">WhatsApp Directo</label>
                    <input
                      type="text"
                      required
                      value={churchForm.whatsapp || ''}
                      onChange={e => setChurchForm({ ...churchForm, whatsapp: e.target.value })}
                      className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                    />
                  </div>
                </div>

                <div className="space-y-4 pt-2 border-t border-white/5">
                  <h3 className="text-xs font-bold text-white flex items-center gap-1.5"><MapPin className="w-4 h-4 text-teal-400" /> Ubicación Geográfica</h3>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
                    <div className="space-y-2">
                      <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Dirección Física</label>
                      <input
                        type="text"
                        required
                        value={churchForm.address || ''}
                        onChange={e => setChurchForm({ ...churchForm, address: e.target.value })}
                        className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Ciudad</label>
                      <input
                        type="text"
                        required
                        value={churchForm.city || ''}
                        onChange={e => setChurchForm({ ...churchForm, city: e.target.value })}
                        className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">País</label>
                      <input
                        type="text"
                        required
                        value={churchForm.country || ''}
                        onChange={e => setChurchForm({ ...churchForm, country: e.target.value })}
                        className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                    <div className="space-y-2">
                      <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Latitud (Coordenadas)</label>
                      <input
                        type="text"
                        value={churchForm.latitude || ''}
                        onChange={e => setChurchForm({ ...churchForm, latitude: e.target.value || null })}
                        className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                        placeholder="Ej: -12.046374"
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Longitud (Coordenadas)</label>
                      <input
                        type="text"
                        value={churchForm.longitude || ''}
                        onChange={e => setChurchForm({ ...churchForm, longitude: e.target.value || null })}
                        className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                        placeholder="Ej: -77.042793"
                      />
                    </div>
                  </div>
                </div>

                <div className="flex justify-end pt-4">
                  <button
                    type="submit"
                    className="inline-flex items-center gap-2 px-5 py-2.5 bg-dorado hover:bg-yellow-600 text-deep-teal rounded-xl text-xs font-bold transition-all shadow"
                  >
                    <Save className="w-4 h-4" />
                    Guardar Cambios
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* 2. Mobile App Settings Tab */}
          {activeTab === 'app' && (
            <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl">
              <div className="border-b border-white/5 pb-4 mb-6">
                <h2 className="text-base font-bold text-white flex items-center gap-2">
                  <Smartphone className="w-5 h-5 text-dorado" />
                  Personalización Visual de la Aplicación Móvil
                </h2>
                <p className="text-xs text-crema text-opacity-50 mt-0.5">
                  Alinea la identidad cromática, logotipos e información legal que verán los usuarios finales
                </p>
              </div>

              <form onSubmit={handleSaveApp} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div className="space-y-2">
                    <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Nombre de la App</label>
                    <input
                      type="text"
                      required
                      value={appForm.app_name || ''}
                      onChange={e => setAppForm({ ...appForm, app_name: e.target.value })}
                      className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Frase de Bienvenida (Splash)</label>
                    <input
                      type="text"
                      required
                      value={appForm.splash_text || ''}
                      onChange={e => setAppForm({ ...appForm, splash_text: e.target.value })}
                      className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Descripción de la Aplicación</label>
                  <textarea
                    rows={3}
                    value={appForm.app_description || ''}
                    onChange={e => setAppForm({ ...appForm, app_description: e.target.value })}
                    className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl p-4 text-xs text-white focus:border-dorado focus:outline-none resize-none"
                  />
                </div>

                {/* Logo & Colors */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-5 pt-2 border-t border-white/5">
                  <div className="space-y-3">
                    <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Logotipo de la App</label>
                    <div className="flex flex-col items-center gap-3 p-4 bg-deep-teal bg-opacity-35 rounded-2xl border border-dashed border-white/10 relative">
                      {logoPreview ? (
                        <img src={logoPreview} alt="Logo app" className="w-16 h-16 object-contain rounded" />
                      ) : (
                        <div className="w-16 h-16 bg-white bg-opacity-5 rounded flex items-center justify-center text-crema text-opacity-30">
                          Sin Logo
                        </div>
                      )}
                      <label className="cursor-pointer text-[10px] font-bold text-dorado flex items-center gap-1">
                        <Upload className="w-3.5 h-3.5" />
                        Cambiar Logo
                        <input type="file" accept="image/*" onChange={handleFileChange} className="hidden" />
                      </label>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Color Primario</label>
                    <div className="flex items-center gap-3">
                      <input
                        type="color"
                        value={appForm.primary_color || '#032F2F'}
                        onChange={e => setAppForm({ ...appForm, primary_color: e.target.value })}
                        className="w-10 h-10 border-0 bg-transparent cursor-pointer"
                      />
                      <input
                        type="text"
                        value={appForm.primary_color || '#032F2F'}
                        onChange={e => setAppForm({ ...appForm, primary_color: e.target.value })}
                        className="w-24 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-2 py-1.5 text-xs text-white focus:outline-none"
                      />
                    </div>
                    <p className="text-[10px] text-crema/45">Fondo y cabeceras principales</p>
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">Color Secundario</label>
                    <div className="flex items-center gap-3">
                      <input
                        type="color"
                        value={appForm.secondary_color || '#D4AF37'}
                        onChange={e => setAppForm({ ...appForm, secondary_color: e.target.value })}
                        className="w-10 h-10 border-0 bg-transparent cursor-pointer"
                      />
                      <input
                        type="text"
                        value={appForm.secondary_color || '#D4AF37'}
                        onChange={e => setAppForm({ ...appForm, secondary_color: e.target.value })}
                        className="w-24 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-2 py-1.5 text-xs text-white focus:outline-none"
                      />
                    </div>
                    <p className="text-[10px] text-crema/45">Detalles, botones y destacados</p>
                  </div>
                </div>

                {/* Policies URLs */}
                <div className="space-y-4 pt-4 border-t border-white/5">
                  <h3 className="text-xs font-bold text-white flex items-center gap-1.5"><ShieldAlert className="w-4 h-4 text-dorado" /> Políticas y Legalidad</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                    <div className="space-y-2">
                      <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">URL Política de Privacidad</label>
                      <input
                        type="url"
                        value={appForm.privacy_policy_url || ''}
                        onChange={e => setAppForm({ ...appForm, privacy_policy_url: e.target.value })}
                        className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] uppercase tracking-wider font-bold text-crema/70">URL Términos y Condiciones</label>
                      <input
                        type="url"
                        value={appForm.terms_url || ''}
                        onChange={e => setAppForm({ ...appForm, terms_url: e.target.value })}
                        className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-white focus:border-dorado focus:outline-none"
                      />
                    </div>
                  </div>
                </div>

                <div className="flex justify-end pt-4">
                  <button
                    type="submit"
                    className="inline-flex items-center gap-2 px-5 py-2.5 bg-dorado hover:bg-yellow-600 text-deep-teal rounded-xl text-xs font-bold transition-all shadow"
                  >
                    <Save className="w-4 h-4" />
                    Guardar Configuración Móvil
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* 3. Service Schedule Tab */}
          {activeTab === 'schedules' && (
            <div className="space-y-6">
              <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                  <h2 className="text-base font-bold text-white flex items-center gap-2">
                    <Calendar className="w-5 h-5 text-dorado" />
                    Horarios de Servicios Religiosos
                  </h2>
                  <p className="text-xs text-crema text-opacity-50 mt-0.5">
                    Configura las reuniones semanales de la iglesia expuestas públicamente
                  </p>
                </div>
                <button
                  onClick={() => setShowScheduleForm(!showScheduleForm)}
                  className="inline-flex items-center gap-1.5 px-3 py-2 bg-teal-600 hover:bg-teal-500 text-white rounded-xl text-xs font-bold transition-all shadow"
                >
                  <Plus className="w-4 h-4" />
                  Agregar Horario
                </button>
              </div>

              {/* Add schedule form modal/card */}
              {showScheduleForm && (
                <div className="glass-panel p-5 bg-dark-teal bg-opacity-40 border border-dorado border-opacity-35 rounded-2xl">
                  <h3 className="text-xs font-bold text-dorado uppercase tracking-wider mb-4">Nueva Reunión de Culto</h3>
                  <form onSubmit={handleAddSchedule} className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div className="space-y-1">
                        <label className="text-[10px] text-crema/60 uppercase font-semibold">Día de la Semana</label>
                        <select
                          value={newSchedule.day_of_week}
                          onChange={e => setNewSchedule({ ...newSchedule, day_of_week: e.target.value as any })}
                          className="w-full bg-deep-teal bg-opacity-60 border border-white/10 rounded-xl px-3 py-2 text-xs text-white focus:outline-none"
                        >
                          <option value="MONDAY">Lunes</option>
                          <option value="TUESDAY">Martes</option>
                          <option value="WEDNESDAY">Miércoles</option>
                          <option value="THURSDAY">Jueves</option>
                          <option value="FRIDAY">Viernes</option>
                          <option value="SATURDAY">Sábado</option>
                          <option value="SUNDAY">Domingo</option>
                        </select>
                      </div>

                      <div className="space-y-1">
                        <label className="text-[10px] text-crema/60 uppercase font-semibold">Hora de Inicio</label>
                        <input
                          type="time"
                          required
                          value={newSchedule.start_time}
                          onChange={e => setNewSchedule({ ...newSchedule, start_time: e.target.value })}
                          className="w-full bg-deep-teal bg-opacity-60 border border-white/10 rounded-xl px-3 py-2 text-xs text-white focus:outline-none"
                        />
                      </div>

                      <div className="space-y-1">
                        <label className="text-[10px] text-crema/60 uppercase font-semibold">Título del Culto</label>
                        <input
                          type="text"
                          required
                          placeholder="Ej: Culto Dominical"
                          value={newSchedule.title}
                          onChange={e => setNewSchedule({ ...newSchedule, title: e.target.value })}
                          className="w-full bg-deep-teal bg-opacity-60 border border-white/10 rounded-xl px-3 py-2 text-xs text-white focus:outline-none"
                        />
                      </div>
                    </div>

                    <div className="space-y-1">
                      <label className="text-[10px] text-crema/60 uppercase font-semibold">Descripción o Lema</label>
                      <input
                        type="text"
                        placeholder="Ej: Reunión general de alabanza y palabra"
                        value={newSchedule.description}
                        onChange={e => setNewSchedule({ ...newSchedule, description: e.target.value })}
                        className="w-full bg-deep-teal bg-opacity-60 border border-white/10 rounded-xl px-3 py-2 text-xs text-white focus:outline-none"
                      />
                    </div>

                    <div className="flex justify-end gap-2 pt-2">
                      <button
                        type="button"
                        onClick={() => setShowScheduleForm(false)}
                        className="px-3 py-1.5 text-xs text-crema/70 hover:text-white"
                      >
                        Cancelar
                      </button>
                      <button
                        type="submit"
                        className="px-4 py-1.5 bg-dorado hover:bg-yellow-600 text-deep-teal rounded-xl text-xs font-bold transition-all shadow"
                      >
                        Guardar Horario
                      </button>
                    </div>
                  </form>
                </div>
              )}

              {/* Schedule list */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {schedules && schedules.length > 0 ? (
                  schedules.map(sched => (
                    <div key={sched.id} className="glass-panel p-4 bg-dark-teal bg-opacity-20 border border-white/5 rounded-2xl flex justify-between items-start">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="text-[10px] font-bold text-dorado uppercase tracking-wide bg-dorado bg-opacity-10 px-2 py-0.5 rounded-full">
                            {sched.day_of_week_display}
                          </span>
                          <span className="text-xs text-white font-semibold">
                            {sched.start_time.slice(0, 5)}
                          </span>
                        </div>
                        <h4 className="text-xs font-bold text-white mt-1.5">{sched.title}</h4>
                        <p className="text-[10px] text-crema text-opacity-50 leading-relaxed">{sched.description}</p>
                      </div>
                      <button
                        onClick={() => sched.id && handleDeleteSchedule(sched.id)}
                        className="p-1.5 hover:bg-red-500/10 text-crema text-opacity-50 hover:text-red-400 rounded-lg transition-all"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  ))
                ) : (
                  <div className="col-span-2 text-center py-10 text-crema text-opacity-40 text-xs">
                    No se han registrado horarios de cultos o servicios aún.
                  </div>
                )}
              </div>
            </div>
          )}

          {/* 4. Social Networks Tab */}
          {activeTab === 'socials' && (
            <div className="space-y-6">
              <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                  <h2 className="text-base font-bold text-white flex items-center gap-2">
                    <Share2 className="w-5 h-5 text-dorado" />
                    Enlaces de Redes Sociales
                  </h2>
                  <p className="text-xs text-crema text-opacity-50 mt-0.5">
                    Vincula las cuentas oficiales de la iglesia para la integración en la aplicación
                  </p>
                </div>
                <button
                  onClick={() => setShowSocialForm(!showSocialForm)}
                  className="inline-flex items-center gap-1.5 px-3 py-2 bg-teal-600 hover:bg-teal-500 text-white rounded-xl text-xs font-bold transition-all shadow"
                >
                  <Plus className="w-4 h-4" />
                  Vincular Red Social
                </button>
              </div>

              {/* Add social profile form card */}
              {showSocialForm && (
                <div className="glass-panel p-5 bg-dark-teal bg-opacity-40 border border-dorado border-opacity-35 rounded-2xl">
                  <h3 className="text-xs font-bold text-dorado uppercase tracking-wider mb-4">Nueva Vinculación Social</h3>
                  <form onSubmit={handleAddSocial} className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div className="space-y-1">
                        <label className="text-[10px] text-crema/60 uppercase font-semibold">Red Social (Nombre)</label>
                        <input
                          type="text"
                          required
                          placeholder="Ej: Instagram"
                          value={newSocial.name}
                          onChange={e => setNewSocial({ ...newSocial, name: e.target.value })}
                          className="w-full bg-deep-teal bg-opacity-60 border border-white/10 rounded-xl px-3 py-2 text-xs text-white focus:outline-none"
                        />
                      </div>

                      <div className="space-y-1">
                        <label className="text-[10px] text-crema/60 uppercase font-semibold">Identificador de Icono</label>
                        <select
                          value={newSocial.icon_name}
                          onChange={e => setNewSocial({ ...newSocial, icon_name: e.target.value })}
                          className="w-full bg-deep-teal bg-opacity-60 border border-white/10 rounded-xl px-3 py-2 text-xs text-white focus:outline-none"
                        >
                          <option value="globe">Navegador / Web</option>
                          <option value="facebook">Facebook</option>
                          <option value="instagram">Instagram</option>
                          <option value="youtube">YouTube</option>
                          <option value="twitter">X / Twitter</option>
                        </select>
                      </div>

                      <div className="space-y-1">
                        <label className="text-[10px] text-crema/60 uppercase font-semibold">URL de Perfil</label>
                        <input
                          type="url"
                          required
                          placeholder="https://instagram.com/miiglesia"
                          value={newSocial.url}
                          onChange={e => setNewSocial({ ...newSocial, url: e.target.value })}
                          className="w-full bg-deep-teal bg-opacity-60 border border-white/10 rounded-xl px-3 py-2 text-xs text-white focus:outline-none"
                        />
                      </div>
                    </div>

                    <div className="flex justify-end gap-2 pt-2">
                      <button
                        type="button"
                        onClick={() => setShowSocialForm(false)}
                        className="px-3 py-1.5 text-xs text-crema/70 hover:text-white"
                      >
                        Cancelar
                      </button>
                      <button
                        type="submit"
                        className="px-4 py-1.5 bg-dorado hover:bg-yellow-600 text-deep-teal rounded-xl text-xs font-bold transition-all shadow"
                      >
                        Vincular Cuenta
                      </button>
                    </div>
                  </form>
                </div>
              )}

              {/* Social profile list */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {socialNetworks && socialNetworks.length > 0 ? (
                  socialNetworks.map(soc => (
                    <div key={soc.id} className="glass-panel p-4 bg-dark-teal bg-opacity-20 border border-white/5 rounded-2xl flex justify-between items-center">
                      <div className="space-y-1 flex items-center gap-3">
                        <div className="w-8 h-8 bg-teal-500 bg-opacity-10 border border-teal-500/20 rounded-lg flex items-center justify-center text-teal-400">
                          <Globe className="w-4 h-4" />
                        </div>
                        <div>
                          <h4 className="text-xs font-bold text-white">{soc.name}</h4>
                          <a
                            href={soc.url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-[10px] text-dorado hover:underline block"
                          >
                            {soc.url.length > 30 ? `${soc.url.slice(0, 30)}...` : soc.url}
                          </a>
                        </div>
                      </div>
                      <button
                        onClick={() => soc.id && handleDeleteSocial(soc.id)}
                        className="p-1.5 hover:bg-red-500/10 text-crema text-opacity-50 hover:text-red-400 rounded-lg transition-all"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  ))
                ) : (
                  <div className="col-span-2 text-center py-10 text-crema text-opacity-40 text-xs">
                    No se han registrado redes sociales vinculadas aún.
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

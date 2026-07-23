import React, { useEffect, useState, useRef } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  ArrowLeft, 
  Save, 
  Eye, 
  MapPin, 
  Calendar,
  Users,
  Globe,
  Download,
  AlertCircle,
  Upload,
  Image as ImageIcon,
  X,
  Check,
  Loader2
} from 'lucide-react';
import { apiClient } from '../api/client';
import { Event, EventStatus, EventRegistration } from '../features/events/types';
import { Logo } from '../components/ui/Logo';

export const EventForm: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const isEdit = !!id;
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [uploadSuccess, setUploadSuccess] = useState(false);

  const { register, handleSubmit, watch, setValue, formState: { errors } } = useForm({
    defaultValues: {
      title: '',
      slug: '',
      description: '',
      cover_image_url: '',
      start_date: new Date().toISOString().slice(0, 16),
      end_date: new Date(Date.now() + 7200000).toISOString().slice(0, 16),
      location: '',
      capacity: '' as any,
      requires_registration: true,
      status: 'DRAFT' as EventStatus,
      latitude: '',
      longitude: '',
    }
  });

  // Watch fields for mobile preview
  const watchedTitle = watch('title');
  const watchedDescription = watch('description');
  const watchedStartDate = watch('start_date');
  const watchedLocation = watch('location');
  const watchedCoverUrl = watch('cover_image_url');
  const watchedCapacity = watch('capacity');
  const watchedRequiresReg = watch('requires_registration');

  // 1. If editing, fetch event details
  const { data: event, isLoading: isFetchingDetails } = useQuery<Event>({
    queryKey: ['event', id],
    queryFn: async () => {
      const res = await apiClient.get(`/events/${id}/`);
      return res.data;
    },
    enabled: isEdit,
  });

  // 2. Fetch Attendees (Inscritos)
  const { data: attendees, isLoading: isLoadingAttendees } = useQuery<any>({
    queryKey: ['attendees', id],
    queryFn: async () => {
      const res = await apiClient.get(`/events/${id}/attendees/`);
      // DRF list wrapping
      return Array.isArray(res.data) ? res.data : res.data.results || [];
    },
    enabled: isEdit,
  });

  // Load details into form
  useEffect(() => {
    if (isEdit && event) {
      setValue('title', event.title);
      setValue('slug', event.slug);
      setValue('description', event.description);
      setValue('start_date', event.start_date ? event.start_date.slice(0, 16) : '');
      setValue('end_date', event.end_date ? event.end_date.slice(0, 16) : '');
      setValue('location', event.location);
      setValue('capacity', event.capacity !== null ? event.capacity : '');
      setValue('requires_registration', event.requires_registration);
      setValue('status', event.status);
      setValue('latitude', event.latitude !== null ? String(event.latitude) : '');
      setValue('longitude', event.longitude !== null ? String(event.longitude) : '');
      if (event.cover_image) {
        setValue('cover_image_url', event.cover_image);
      }
    }
  }, [isEdit, event, setValue]);

  // Handle Local File Selection & Upload
  const handleLocalFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadingImage(true);
    setUploadSuccess(false);
    setErrorMsg(null);

    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('title', file.name);
      formData.append('file_type', 'IMAGE');

      const res = await apiClient.post('/multimedia/', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });

      const uploadedUrl = res.data.file || res.data.file_url;
      if (uploadedUrl) {
        setValue('cover_image_url', uploadedUrl, { shouldValidate: true });
        setUploadSuccess(true);
      }
    } catch (err: any) {
      console.error('Error al subir imagen local:', err);
      setErrorMsg('No se pudo subir la imagen seleccionada desde tu equipo. Inténtalo de nuevo.');
    } finally {
      setUploadingImage(false);
    }
  };

  // Generate slug
  const handleTitleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setValue('title', val);
    const generatedSlug = val
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)+/g, '');
    setValue('slug', generatedSlug);
  };

  // Save Mutation
  const saveMutation = useMutation({
    mutationFn: async (formData: any) => {
      const payload = {
        title: formData.title,
        slug: formData.slug,
        description: formData.description,
        start_date: new Date(formData.start_date).toISOString(),
        end_date: new Date(formData.end_date).toISOString(),
        location: formData.location,
        capacity: formData.capacity ? parseInt(formData.capacity) : null,
        requires_registration: formData.requires_registration,
        status: formData.status,
        latitude: formData.latitude ? parseFloat(formData.latitude) : null,
        longitude: formData.longitude ? parseFloat(formData.longitude) : null,
        cover_image: formData.cover_image_url || null
      };

      if (isEdit) {
        return apiClient.put(`/events/${id}/`, payload);
      } else {
        return apiClient.post('/events/', payload);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['events'] });
      navigate('/eventos');
    },
    onError: (err: any) => {
      setErrorMsg(err.response?.data?.detail || 'Error al guardar el evento.');
    }
  });

  const onSubmit = (data: any) => {
    setErrorMsg(null);
    saveMutation.mutate(data);
  };

  // CSV Export utility
  const handleExportCSV = () => {
    if (!attendees || attendees.length === 0) return;
    
    // Header
    const headers = ['Nombre Completo', 'Email', 'Teléfono', 'Fecha Registro', 'Estado'];
    
    // Rows
    const rows = attendees.map((reg: EventRegistration) => [
      reg.user.full_name,
      reg.user.email,
      (reg.user as any).phone || '-',
      new Date(reg.registered_at).toLocaleString('es-PE'),
      reg.status
    ]);
    
    const csvContent = "data:text/csv;charset=utf-8,\uFEFF" 
      + [headers.join(','), ...rows.map((e: any[]) => e.map((val: string) => `"${val.replace(/"/g, '""')}"`).join(','))].join('\n');
      
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `asistentes_${event?.slug || 'evento'}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const formatPreviewDate = (dateStr: string) => {
    if (!dateStr) return '';
    try {
      const d = new Date(dateStr);
      return d.toLocaleDateString('es-PE', { weekday: 'short', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
    } catch {
      return dateStr;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link 
          to="/eventos" 
          className="p-2 rounded-xl bg-dark-teal bg-opacity-40 hover:bg-opacity-60 border border-white border-opacity-10 transition-colors"
        >
          <ArrowLeft size={16} />
        </Link>
        <div>
          <h1 className="text-xl font-extrabold text-crema leading-none">
            {isEdit ? 'Editar Evento' : 'Registrar Nuevo Evento'}
          </h1>
          <p className="text-xs text-crema text-opacity-50 mt-1">
            {isEdit ? 'Modifica detalles, ubicación, aforo y visualiza inscriptos.' : 'Ingresa la información básica y de registro para el evento.'}
          </p>
        </div>
      </div>

      {isFetchingDetails ? (
        <div className="p-12 flex flex-col items-center justify-center gap-3">
          <div className="w-8 h-8 border-4 border-dorado border-t-transparent rounded-full animate-spin" />
          <span className="text-xs text-crema text-opacity-50">Cargando detalles de evento...</span>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
          {/* Form */}
          <div className="lg:col-span-2 space-y-6">
            <div className="glass-panel p-6 bg-dark-teal bg-opacity-20">
              {errorMsg && (
                <div className="flex items-center gap-2 p-3.5 mb-6 bg-error-red bg-opacity-15 text-error-red border border-error-red border-opacity-20 rounded-xl text-xs">
                  <AlertCircle size={16} className="shrink-0" />
                  <span>{errorMsg}</span>
                </div>
              )}

              <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
                {/* Title & Slug */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Título del Evento</label>
                    <input
                      type="text"
                      placeholder="ej. Campamento de Jóvenes"
                      className="w-full glass-input text-xs"
                      {...register('title', { required: 'El título es obligatorio' })}
                      onChange={handleTitleChange}
                    />
                    {errors.title && (
                      <span className="text-[10px] text-error-red font-medium ml-1">{errors.title.message}</span>
                    )}
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Slug (URL)</label>
                    <input
                      type="text"
                      className="w-full glass-input text-xs"
                      {...register('slug', { required: 'El slug es obligatorio' })}
                    />
                    {errors.slug && (
                      <span className="text-[10px] text-error-red font-medium ml-1">{errors.slug.message}</span>
                    )}
                  </div>
                </div>

                {/* Dates */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Fecha y Hora de Inicio</label>
                    <input
                      type="datetime-local"
                      className="w-full glass-input text-xs"
                      {...register('start_date', { required: 'La fecha de inicio es obligatoria' })}
                    />
                    {errors.start_date && (
                      <span className="text-[10px] text-error-red font-medium ml-1">{errors.start_date.message}</span>
                    )}
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Fecha y Hora de Fin</label>
                    <input
                      type="datetime-local"
                      className="w-full glass-input text-xs"
                      {...register('end_date', { required: 'La fecha de fin es obligatoria' })}
                    />
                    {errors.end_date && (
                      <span className="text-[10px] text-error-red font-medium ml-1">{errors.end_date.message}</span>
                    )}
                  </div>
                </div>

                {/* Capacity, Registration & Status */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Aforo Máximo (Límite)</label>
                    <input
                      type="number"
                      placeholder="Sin límite"
                      className="w-full glass-input text-xs"
                      {...register('capacity')}
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Estado</label>
                    <select
                      className="w-full bg-dark-teal bg-opacity-50 border border-white border-opacity-10 rounded-xl px-4 py-3 text-xs text-crema focus:outline-none focus:border-dorado focus:ring-1 focus:ring-dorado"
                      {...register('status')}
                    >
                      <option value="DRAFT">Borrador</option>
                      <option value="PUBLISHED">Publicado</option>
                      <option value="ARCHIVED">Archivado</option>
                      <option value="CANCELLED">Cancelado</option>
                    </select>
                  </div>

                  <div className="flex items-center pt-6 pl-2">
                    <label className="flex items-center gap-2.5 text-xs text-crema text-opacity-70 cursor-pointer select-none">
                      <input
                        type="checkbox"
                        className="accent-dorado w-4 h-4 rounded border-white border-opacity-10 bg-deep-teal focus:ring-0"
                        {...register('requires_registration')}
                      />
                      Requiere inscripción
                    </label>
                  </div>
                </div>

                {/* Physical Location details */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="space-y-1.5 md:col-span-2">
                    <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Dirección / Ubicación Física</label>
                    <input
                      type="text"
                      placeholder="Dirección del evento"
                      className="w-full glass-input text-xs"
                      {...register('location', { required: 'La ubicación es obligatoria' })}
                    />
                    {errors.location && (
                      <span className="text-[10px] text-error-red font-medium ml-1">{errors.location.message}</span>
                    )}
                  </div>

                  <div className="space-y-2 md:col-span-3">
                    <label className="text-xs font-semibold text-crema text-opacity-65 ml-1 flex items-center justify-between">
                      <span>Imagen de Portada del Evento</span>
                      <span className="text-[10px] text-crema text-opacity-40">Archivos JPG, PNG, WEBP de tu equipo</span>
                    </label>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-3 items-center">
                      {/* Image Preview Box */}
                      <div className="relative w-full h-32 rounded-xl bg-deep-teal border border-white border-opacity-10 overflow-hidden flex flex-col items-center justify-center group">
                        {watchedCoverUrl ? (
                          <>
                            <img 
                              src={watchedCoverUrl} 
                              alt="Portada" 
                              className="w-full h-full object-cover" 
                            />
                            <button
                              type="button"
                              onClick={() => {
                                setValue('cover_image_url', '');
                                setUploadSuccess(false);
                              }}
                              className="absolute top-2 right-2 p-1.5 bg-black bg-opacity-60 hover:bg-opacity-90 text-white rounded-lg transition-all"
                              title="Quitar portada"
                            >
                              <X size={14} />
                            </button>
                          </>
                        ) : (
                          <div className="flex flex-col items-center text-center p-3 text-crema text-opacity-40">
                            <ImageIcon size={28} className="mb-1 text-dorado opacity-50" />
                            <span className="text-[10px]">Sin portada seleccionada</span>
                          </div>
                        )}
                      </div>

                      {/* File Picker & URL Options */}
                      <div className="md:col-span-2 space-y-2">
                        <div className="flex flex-wrap items-center gap-2">
                          <input 
                            ref={fileInputRef}
                            type="file" 
                            accept="image/*" 
                            className="hidden" 
                            onChange={handleLocalFileSelect} 
                          />
                          <button
                            type="button"
                            onClick={() => fileInputRef.current?.click()}
                            disabled={uploadingImage}
                            className="flex items-center gap-2 px-4 py-2.5 bg-dorado bg-opacity-15 hover:bg-opacity-25 text-dorado border border-dorado border-opacity-30 rounded-xl text-xs font-bold transition-all disabled:opacity-50"
                          >
                            {uploadingImage ? (
                              <>
                                <Loader2 size={16} className="animate-spin" />
                                Subiendo imagen local...
                              </>
                            ) : (
                              <>
                                <Upload size={16} />
                                Seleccionar Foto desde mi PC
                              </>
                            )}
                          </button>

                          {uploadSuccess && (
                            <span className="text-[11px] text-emerald-400 font-semibold flex items-center gap-1">
                              <Check size={14} /> Subida correctamente
                            </span>
                          )}
                        </div>

                        <div>
                          <input
                            type="text"
                            placeholder="O ingresa una URL de imagen externa..."
                            className="w-full glass-input text-xs"
                            {...register('cover_image_url')}
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Description */}
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Descripción del Evento</label>
                  <textarea
                    rows={5}
                    placeholder="Describe los detalles, objetivos y actividades del evento..."
                    className="w-full glass-input text-xs resize-y"
                    {...register('description', { required: 'La descripción es obligatoria' })}
                  />
                  {errors.description && (
                    <span className="text-[10px] text-error-red font-medium ml-1">{errors.description.message}</span>
                  )}
                </div>

                {/* Actions Buttons */}
                <div className="flex justify-end gap-3 pt-4 border-t border-white border-opacity-5">
                  <Link to="/eventos" className="btn-secondary text-xs font-semibold">
                    Cancelar
                  </Link>
                  <button
                    type="submit"
                    disabled={saveMutation.isPending}
                    className="flex items-center gap-2 btn-primary text-xs font-bold"
                  >
                    {saveMutation.isPending ? (
                      <div className="w-4 h-4 border-2 border-deep-teal border-t-transparent rounded-full animate-spin" />
                    ) : (
                      <>
                        <Save size={16} />
                        Guardar Evento
                      </>
                    )}
                  </button>
                </div>
              </form>
            </div>

            {/* Attendees list (Inscritos) shown only in EDIT mode */}
            {isEdit && (
              <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-sm font-bold text-crema leading-none">Miembros Inscritos</h3>
                    <p className="text-[10px] text-crema text-opacity-50 mt-1">Lista completa de inscriptos al evento.</p>
                  </div>
                  {attendees && attendees.length > 0 && (
                    <button
                      onClick={handleExportCSV}
                      className="flex items-center gap-1 text-[10px] font-bold text-dorado hover:text-dorado-light bg-dorado bg-opacity-10 border border-dorado border-opacity-20 px-2.5 py-1.5 rounded-lg focus:outline-none"
                    >
                      <Download size={12} />
                      Exportar Asistentes (CSV)
                    </button>
                  )}
                </div>

                {isLoadingAttendees ? (
                  <div className="py-8 flex justify-center text-xs text-crema text-opacity-50">
                    Cargando lista de asistentes...
                  </div>
                ) : !attendees || attendees.length === 0 ? (
                  <div className="p-8 text-center border border-dashed border-white border-opacity-10 rounded-xl text-xs text-crema text-opacity-40 italic">
                    Nadie se ha inscrito a este evento todavía.
                  </div>
                ) : (
                  <div className="overflow-hidden border border-white border-opacity-5 rounded-xl">
                    <table className="w-full text-left text-xs border-collapse">
                      <thead className="bg-deep-teal bg-opacity-20 text-[10px] font-bold uppercase tracking-wider text-crema text-opacity-40">
                        <tr>
                          <th className="px-4 py-3">Nombre</th>
                          <th className="px-4 py-3">Email</th>
                          <th className="px-4 py-3">Teléfono</th>
                          <th className="px-4 py-3">Fecha de Registro</th>
                          <th className="px-4 py-3 text-right">Estado</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-white divide-opacity-5">
                        {attendees.map((reg: EventRegistration) => (
                          <tr key={reg.id} className="hover:bg-white hover:bg-opacity-5 transition-colors">
                            <td className="px-4 py-3 font-bold">{reg.user.full_name}</td>
                            <td className="px-4 py-3 text-crema text-opacity-70">{reg.user.email}</td>
                            <td className="px-4 py-3 text-crema text-opacity-70">{(reg.user as any).phone || '-'}</td>
                            <td className="px-4 py-3 text-crema text-opacity-55">
                              {new Date(reg.registered_at).toLocaleDateString('es-PE')}
                            </td>
                            <td className="px-4 py-3 text-right font-bold text-[10px] text-exito">
                              {reg.status}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Sticky Mobile Preview */}
          <div className="hidden lg:block lg:sticky lg:top-6 space-y-4">
            <div className="flex items-center gap-2 text-xs font-bold text-crema text-opacity-50 pl-2">
              <Eye size={14} />
              <span>Previsualización del Evento (App)</span>
            </div>

            {/* Simulated Phone Frame */}
            <div className="w-[280px] h-[550px] mx-auto rounded-[38px] border-[10px] border-dark-teal bg-deep-teal shadow-2xl relative overflow-hidden flex flex-col">
              {/* Camera Notch */}
              <div className="absolute top-2 left-1/2 -translate-x-1/2 w-28 h-4 bg-dark-teal rounded-full z-30 flex items-center justify-center">
                <div className="w-2.5 h-2.5 bg-black rounded-full ml-auto mr-4 border border-white border-opacity-10" />
              </div>

              {/* Mobile Screen Header */}
              <div className="pt-8 px-4 pb-2 bg-dark-teal bg-opacity-40 border-b border-white border-opacity-5 flex items-center gap-2">
                <Logo size={20} variant="gold" />
                <span className="text-[10px] font-bold text-dorado uppercase tracking-widest">Génesis App</span>
              </div>

              {/* Screen Content */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4 text-left">
                {/* Image */}
                {watchedCoverUrl ? (
                  <div className="w-full h-32 rounded-xl bg-dark-teal overflow-hidden border border-white border-opacity-10">
                    <img src={watchedCoverUrl} alt="" className="w-full h-full object-cover" />
                  </div>
                ) : (
                  <div className="w-full h-32 rounded-xl bg-dark-teal border border-white border-opacity-5 flex items-center justify-center">
                    <Globe size={32} className="text-crema text-opacity-10" />
                  </div>
                )}

                {/* Badges / Header details */}
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="text-[8px] font-extrabold uppercase px-1.5 py-0.5 bg-dorado bg-opacity-10 text-dorado rounded">
                      CONFERENCIA
                    </span>
                    {watchedRequiresReg && (
                      <span className="text-[8px] font-extrabold uppercase px-1.5 py-0.5 bg-blue-500 bg-opacity-15 text-blue-400 rounded">
                        REQUIERE REGISTRO
                      </span>
                    )}
                  </div>
                  <h2 className="text-xs font-extrabold text-crema leading-snug">
                    {watchedTitle || 'Título del Evento'}
                  </h2>
                </div>

                {/* Details list */}
                <div className="space-y-2 text-[9px] text-crema text-opacity-70 border-y border-white border-opacity-5 py-2">
                  <div className="flex items-center gap-2">
                    <Calendar size={13} className="text-dorado" />
                    <span>{watchedStartDate ? formatPreviewDate(watchedStartDate) : 'Fecha de Inicio'}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <MapPin size={13} className="text-dorado" />
                    <span className="truncate">{watchedLocation || 'Dirección física'}</span>
                  </div>
                  {watchedRequiresReg && (
                    <div className="flex items-center gap-2">
                      <Users size={13} className="text-dorado" />
                      <span>Aforo Disponible: {watchedCapacity ? watchedCapacity : 'Ilimitado'}</span>
                    </div>
                  )}
                </div>

                {/* Description */}
                <div className="space-y-1">
                  <span className="text-[9px] font-extrabold text-dorado uppercase tracking-wider block">Acerca del evento</span>
                  <p className="text-[9px] text-crema text-opacity-80 leading-relaxed whitespace-pre-line">
                    {watchedDescription || 'Detalles descriptivos sobre el taller, horario o conferencistas invitados...'}
                  </p>
                </div>

                {/* Register Button in Mobile */}
                {watchedRequiresReg && (
                  <button 
                    disabled 
                    className="w-full py-2 bg-dorado text-deep-teal font-extrabold text-[10px] rounded-lg mt-4 text-center disabled:opacity-85 shadow"
                  >
                    Inscribirme al Evento
                  </button>
                )}
              </div>

              {/* Home Indicator */}
              <div className="pb-2 pt-1 flex justify-center bg-deep-teal bg-opacity-80">
                <div className="w-20 h-1 bg-white bg-opacity-30 rounded-full" />
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

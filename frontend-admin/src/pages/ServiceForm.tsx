import React, { useEffect, useState } from 'react';
import { useForm, useFieldArray } from 'react-hook-form';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  ArrowLeft, 
  Save, 
  Eye, 
  Radio, 
  BookOpen, 
  Plus, 
  Trash2, 
  Info,
  Youtube,
  Music
} from 'lucide-react';
import { apiClient } from '../api/client';
import { ServiceVerse } from '../features/services/types';
import { Logo } from '../components/ui/Logo';

export const ServiceForm: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const isEdit = !!id;
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const { register, control, handleSubmit, watch, setValue, formState: { errors } } = useForm({
    defaultValues: {
      title: '',
      slug: '',
      date: new Date().toISOString().split('T')[0],
      video_url: '',
      audio_url: '',
      sermon_notes: '',
      is_live: false,
      status: 'DRAFT',
      verses: [] as ServiceVerse[]
    }
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'verses'
  });

  // Watch fields for mobile preview
  const watchedTitle = watch('title');
  const watchedNotes = watch('sermon_notes');
  const watchedDate = watch('date');
  const watchedVideo = watch('video_url');
  const watchedAudio = watch('audio_url');
  const watchedLive = watch('is_live');
  const watchedVerses = watch('verses');

  // If editing, fetch details
  const { data: service, isLoading: isFetchingDetails } = useQuery({
    queryKey: ['service', id],
    queryFn: async () => {
      const res = await apiClient.get(`/services/${id}/`);
      return res.data;
    },
    enabled: isEdit,
  });

  // Load details into form
  useEffect(() => {
    if (isEdit && service) {
      setValue('title', service.title);
      setValue('slug', service.slug);
      setValue('date', service.date);
      setValue('video_url', service.video_url || '');
      setValue('audio_url', service.audio_url || '');
      setValue('sermon_notes', service.sermon_notes);
      setValue('is_live', service.is_live);
      setValue('status', service.status);
      setValue('verses', service.verses || []);
    }
  }, [isEdit, service, setValue]);

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
        date: formData.date,
        video_url: formData.video_url || null,
        audio_url: formData.audio_url || null,
        sermon_notes: formData.sermon_notes,
        is_live: formData.is_live,
        status: formData.status,
        verses: formData.verses.map((v: any) => ({
          id: v.id,
          book: v.book,
          chapter: parseInt(v.chapter),
          verses: v.verses,
          text: v.text
        }))
      };

      if (isEdit) {
        return apiClient.put(`/services/${id}/`, payload);
      } else {
        return apiClient.post('/services/', payload);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
      navigate('/servicios');
    },
    onError: (err: any) => {
      setErrorMsg(err.response?.data?.detail || 'Error al guardar el servicio.');
    }
  });

  const onSubmit = (data: any) => {
    setErrorMsg(null);
    saveMutation.mutate(data);
  };

  // Extract YouTube video ID for thumbnail preview
  const getYoutubeVideoId = (url: string) => {
    if (!url) return null;
    const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
    const match = url.match(regExp);
    return (match && match[2].length === 11) ? match[2] : null;
  };

  const videoId = getYoutubeVideoId(watchedVideo);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link 
          to="/servicios" 
          className="p-2 rounded-xl bg-dark-teal bg-opacity-40 hover:bg-opacity-60 border border-white border-opacity-10 transition-colors"
        >
          <ArrowLeft size={16} />
        </Link>
        <div>
          <h1 className="text-xl font-extrabold text-crema leading-none">
            {isEdit ? 'Editar Culto / Servicio' : 'Registrar Nuevo Culto'}
          </h1>
          <p className="text-xs text-crema text-opacity-50 mt-1">
            {isEdit ? 'Modifica detalles, enlaces y notas del sermón.' : 'Ingresa la información del sermón dominical realizado.'}
          </p>
        </div>
      </div>

      {isFetchingDetails ? (
        <div className="p-12 flex flex-col items-center justify-center gap-3">
          <div className="w-8 h-8 border-4 border-dorado border-t-transparent rounded-full animate-spin" />
          <span className="text-xs text-crema text-opacity-50">Cargando detalles del servicio...</span>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
          {/* Form */}
          <div className="lg:col-span-2 glass-panel p-6 bg-dark-teal bg-opacity-20">
            {errorMsg && (
              <div className="flex items-center gap-2 p-3.5 mb-6 bg-error-red bg-opacity-15 text-error-red border border-error-red border-opacity-20 rounded-xl text-xs">
                <Info size={16} />
                <span>{errorMsg}</span>
              </div>
            )}

            <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
              {/* Title & Slug */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Título del Sermón</label>
                  <input
                    type="text"
                    placeholder="ej. El Poder de la Fe"
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

              {/* Date, Status, Live */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Fecha del Culto</label>
                  <input
                    type="date"
                    className="w-full glass-input text-xs"
                    {...register('date', { required: 'La fecha es obligatoria' })}
                  />
                  {errors.date && (
                    <span className="text-[10px] text-error-red font-medium ml-1">{errors.date.message}</span>
                  )}
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
                  </select>
                </div>

                <div className="flex items-center pt-6 pl-2">
                  <label className="flex items-center gap-2.5 text-xs text-crema text-opacity-70 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      className="accent-dorado w-4 h-4 rounded border-white border-opacity-10 bg-deep-teal focus:ring-0"
                      {...register('is_live')}
                    />
                    ¿Culto en vivo? (Streaming)
                  </label>
                </div>
              </div>

              {/* Multimedia URLs */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1 flex items-center gap-1.5">
                    <Youtube size={14} className="text-red-500" />
                    Enlace de Video (YouTube/Vimeo)
                  </label>
                  <input
                    type="text"
                    placeholder="https://www.youtube.com/watch?v=..."
                    className="w-full glass-input text-xs"
                    {...register('video_url')}
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1 flex items-center gap-1.5">
                    <Music size={14} className="text-teal-400" />
                    Enlace de Audio (S3/Spotify)
                  </label>
                  <input
                    type="text"
                    placeholder="https://ejemplo.com/audio.mp3"
                    className="w-full glass-input text-xs"
                    {...register('audio_url')}
                  />
                </div>
              </div>

              {/* Sermon Notes */}
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Notas y Resumen del Sermón</label>
                <textarea
                  rows={6}
                  placeholder="Escribe los puntos clave tratados en la prédica..."
                  className="w-full glass-input text-xs resize-y"
                  {...register('sermon_notes')}
                />
              </div>

              {/* Versículos bíblicos dinámicos */}
              <div className="space-y-4 pt-2 border-t border-white border-opacity-5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-dorado uppercase tracking-wider flex items-center gap-1.5">
                    <BookOpen size={15} />
                    Versículos Bíblicos del Sermón
                  </span>
                  <button
                    type="button"
                    onClick={() => append({ book: '', chapter: 1, verses: '', text: '' })}
                    className="flex items-center gap-1 text-[10px] font-bold text-dorado hover:text-dorado-light bg-dorado bg-opacity-10 border border-dorado border-opacity-20 px-2.5 py-1.5 rounded-lg focus:outline-none"
                  >
                    <Plus size={12} />
                    Añadir Versículo
                  </button>
                </div>

                {fields.length === 0 ? (
                  <div className="p-4 text-center border border-dashed border-white border-opacity-10 rounded-xl">
                    <span className="text-[10px] text-crema text-opacity-40 italic">Ningún versículo bíblico asignado a este culto.</span>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {fields.map((field, index) => (
                      <div key={field.id} className="p-4 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl relative space-y-3">
                        <button
                          type="button"
                          onClick={() => remove(index)}
                          className="absolute top-3 right-3 p-1.5 rounded-lg text-error-red hover:bg-error-red hover:bg-opacity-10 focus:outline-none"
                        >
                          <Trash2 size={14} />
                        </button>

                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                          <div className="space-y-1">
                            <label className="text-[10px] font-semibold text-crema text-opacity-50">Libro</label>
                            <input
                              type="text"
                              placeholder="ej. Génesis"
                              className="w-full glass-input text-xs py-1.5 px-3"
                              {...register(`verses.${index}.book` as const, { required: true })}
                            />
                          </div>

                          <div className="space-y-1">
                            <label className="text-[10px] font-semibold text-crema text-opacity-50">Capítulo</label>
                            <input
                              type="number"
                              placeholder="1"
                              className="w-full glass-input text-xs py-1.5 px-3"
                              {...register(`verses.${index}.chapter` as const, { required: true, valueAsNumber: true })}
                            />
                          </div>

                          <div className="space-y-1">
                            <label className="text-[10px] font-semibold text-crema text-opacity-50">Versículos</label>
                            <input
                              type="text"
                              placeholder="ej. 1-3 o 15"
                              className="w-full glass-input text-xs py-1.5 px-3"
                              {...register(`verses.${index}.verses` as const, { required: true })}
                            />
                          </div>
                        </div>

                        <div className="space-y-1">
                          <label className="text-[10px] font-semibold text-crema text-opacity-50">Texto Bíblico</label>
                          <textarea
                            rows={2}
                            placeholder="Escribe el texto de los versículos..."
                            className="w-full glass-input text-xs py-1.5 px-3 resize-none"
                            {...register(`verses.${index}.text` as const, { required: true })}
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Actions Buttons */}
              <div className="flex justify-end gap-3 pt-4 border-t border-white border-opacity-5">
                <Link to="/servicios" className="btn-secondary text-xs font-semibold">
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
                      Guardar Culto
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>

          {/* Sticky Mobile Preview */}
          <div className="hidden lg:block lg:sticky lg:top-6 space-y-4">
            <div className="flex items-center gap-2 text-xs font-bold text-crema text-opacity-50 pl-2">
              <Eye size={14} />
              <span>Previsualización del Culto (App)</span>
            </div>

            {/* Simulated Phone Frame */}
            <div className="w-[280px] h-[550px] mx-auto rounded-[38px] border-[10px] border-dark-teal bg-deep-teal shadow-2xl relative overflow-hidden flex flex-col">
              {/* Camera Notch */}
              <div className="absolute top-2 left-1/2 -translate-x-1/2 w-28 h-4 bg-dark-teal rounded-full z-30 flex items-center justify-center">
                <div className="w-2.5 h-2.5 bg-black rounded-full ml-auto mr-4 border border-white border-opacity-10" />
              </div>

              {/* Mobile Screen Header */}
              <div className="pt-8 px-4 pb-2 bg-dark-teal bg-opacity-40 border-b border-white border-opacity-5 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Logo size={20} variant="gold" />
                  <span className="text-[10px] font-bold text-dorado uppercase tracking-widest">Génesis App</span>
                </div>
                {watchedLive && (
                  <span className="flex items-center gap-0.5 text-[8px] font-extrabold text-error-red bg-error-red bg-opacity-10 border border-error-red border-opacity-20 px-1.5 py-0.2 rounded-full">
                    <Radio size={8} className="animate-pulse" />
                    LIVE
                  </span>
                )}
              </div>

              {/* Screen Content */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4 text-left">
                {/* Video container */}
                {videoId ? (
                  <div className="w-full h-32 rounded-xl bg-black overflow-hidden border border-white border-opacity-10 relative">
                    <img 
                      src={`https://img.youtube.com/vi/${videoId}/hqdefault.jpg`} 
                      alt="" 
                      className="w-full h-full object-cover opacity-60" 
                    />
                    <div className="absolute inset-0 flex items-center justify-center">
                      <div className="w-12 h-12 bg-dorado rounded-full flex items-center justify-center shadow-lg">
                        <svg className="w-6 h-6 text-deep-teal ml-1" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M8 5v14l11-7z" />
                        </svg>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="w-full h-32 rounded-xl bg-dark-green bg-opacity-30 border border-white border-opacity-5 flex flex-col items-center justify-center gap-2">
                    <Youtube size={32} className="text-crema text-opacity-15" />
                    <span className="text-[9px] text-crema text-opacity-40 font-bold uppercase">Video no disponible</span>
                  </div>
                )}

                {/* Audio simulated bar */}
                {watchedAudio && (
                  <div className="p-2.5 bg-dark-teal bg-opacity-50 border border-white border-opacity-10 rounded-xl flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Music size={14} className="text-teal-400 animate-bounce" />
                      <span className="text-[9px] font-bold">Audio del Sermón</span>
                    </div>
                    <div className="flex gap-1.5">
                      <div className="w-1 h-3 bg-teal-400 rounded-full" />
                      <div className="w-1 h-4 bg-teal-400 rounded-full" />
                      <div className="w-1 h-2 bg-teal-400 rounded-full" />
                    </div>
                  </div>
                )}

                {/* Title & Date */}
                <div className="space-y-1">
                  <h2 className="text-xs font-extrabold text-crema leading-snug">
                    {watchedTitle || 'Título del Sermón Dominical'}
                  </h2>
                  <span className="text-[9px] text-crema text-opacity-50 block">
                    Culto del: {watchedDate ? new Date(watchedDate).toLocaleDateString('es-PE') : 'Fecha'}
                  </span>
                </div>

                {/* Verses */}
                {watchedVerses && watchedVerses.length > 0 && (
                  <div className="space-y-2">
                    <span className="text-[9px] font-extrabold text-dorado uppercase tracking-wider block">Lectura Bíblica</span>
                    <div className="space-y-1.5">
                      {watchedVerses.map((v: any, idx: number) => (
                        <div key={idx} className="p-2 bg-genesis-card-sec bg-opacity-50 border-l-2 border-dorado rounded-r-lg text-[9px] space-y-1">
                          <span className="font-bold text-dorado block">{v.book} {v.chapter}:{v.verses}</span>
                          <p className="text-crema text-opacity-70 leading-relaxed italic">"{v.text || '...'}"</p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Sermon Notes */}
                <div className="space-y-1.5">
                  <span className="text-[9px] font-extrabold text-dorado uppercase tracking-wider block">Notas del Sermón</span>
                  <p className="text-[10px] text-crema text-opacity-80 leading-relaxed whitespace-pre-line">
                    {watchedNotes || 'Puntos del mensaje...'}
                  </p>
                </div>
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

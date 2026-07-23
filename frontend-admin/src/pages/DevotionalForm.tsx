import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  ArrowLeft, 
  Save, 
  Eye, 
  Music, 
  BookOpen,
  Info
} from 'lucide-react';
import { apiClient } from '../api/client';
import { Logo } from '../components/ui/Logo';

export const DevotionalForm: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const isEdit = !!id;
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const { register, handleSubmit, watch, setValue, formState: { errors } } = useForm({
    defaultValues: {
      title: '',
      slug: '',
      date: new Date().toISOString().split('T')[0],
      bible_passage: '',
      bible_text: '',
      content: '',
      audio_url: '',
      status: 'DRAFT',
    }
  });

  // Watch fields for mobile preview
  const watchedTitle = watch('title');
  const watchedContent = watch('content');
  const watchedDate = watch('date');
  const watchedPassage = watch('bible_passage');
  const watchedPassageText = watch('bible_text');
  const watchedAudio = watch('audio_url');

  // If editing, fetch details
  const { data: devotional, isLoading: isFetchingDetails } = useQuery({
    queryKey: ['devotional', id],
    queryFn: async () => {
      const res = await apiClient.get(`/devotionals/${id}/`);
      return res.data;
    },
    enabled: isEdit,
  });

  // Load details into form
  useEffect(() => {
    if (isEdit && devotional) {
      setValue('title', devotional.title);
      setValue('slug', devotional.slug);
      setValue('date', devotional.date);
      setValue('bible_passage', devotional.bible_passage);
      setValue('bible_text', devotional.bible_text);
      setValue('content', devotional.content);
      setValue('audio_url', devotional.audio_url || '');
      setValue('status', devotional.status);
    }
  }, [isEdit, devotional, setValue]);

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
        bible_passage: formData.bible_passage,
        bible_text: formData.bible_text,
        content: formData.content,
        audio_url: formData.audio_url || null,
        status: formData.status,
      };

      if (isEdit) {
        return apiClient.put(`/devotionals/${id}/`, payload);
      } else {
        return apiClient.post('/devotionals/', payload);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['devotionals'] });
      navigate('/devocionales');
    },
    onError: (err: any) => {
      setErrorMsg(err.response?.data?.detail || err.response?.data?.date?.[0] || 'Error al guardar el devocional. Verifica si la fecha ya está en uso.');
    }
  });

  const onSubmit = (data: any) => {
    setErrorMsg(null);
    saveMutation.mutate(data);
  };

  const formatPreviewDate = (dateStr: string) => {
    if (!dateStr) return '';
    try {
      const parts = dateStr.split('-');
      const d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
      return d.toLocaleDateString('es-PE', { weekday: 'long', day: 'numeric', month: 'long' });
    } catch {
      return dateStr;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link 
          to="/devocionales" 
          className="p-2 rounded-xl bg-dark-teal bg-opacity-40 hover:bg-opacity-60 border border-white border-opacity-10 transition-colors"
        >
          <ArrowLeft size={16} />
        </Link>
        <div>
          <h1 className="text-xl font-extrabold text-crema leading-none">
            {isEdit ? 'Editar Devocional' : 'Nuevo Devocional Diario'}
          </h1>
          <p className="text-xs text-crema text-opacity-50 mt-1">
            {isEdit ? 'Modifica la reflexión y pasaje bíblico para este devocional.' : 'Redacta un nuevo devocional para nutrir la fe de la comunidad.'}
          </p>
        </div>
      </div>

      {isFetchingDetails ? (
        <div className="p-12 flex flex-col items-center justify-center gap-3">
          <div className="w-8 h-8 border-4 border-dorado border-t-transparent rounded-full animate-spin" />
          <span className="text-xs text-crema text-opacity-50">Cargando detalles de devocional...</span>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
          {/* Form */}
          <div className="lg:col-span-2 glass-panel p-6 bg-dark-teal bg-opacity-20">
            {errorMsg && (
              <div className="flex items-center gap-2 p-3.5 mb-6 bg-error-red bg-opacity-15 text-error-red border border-error-red border-opacity-20 rounded-xl text-xs">
                <Info size={16} className="shrink-0" />
                <span>{errorMsg}</span>
              </div>
            )}

            <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
              {/* Title & Slug */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Título del Devocional</label>
                  <input
                    type="text"
                    placeholder="ej. Un Nuevo Despertar"
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

              {/* Date, Status & Audio */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Fecha Asignada (Única)</label>
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

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1 flex items-center gap-1">
                    <Music size={14} className="text-teal-400" />
                    Audio Devocional (URL)
                  </label>
                  <input
                    type="text"
                    placeholder="https://ejemplo.com/audio.mp3"
                    className="w-full glass-input text-xs"
                    {...register('audio_url')}
                  />
                </div>
              </div>

              {/* Bible Passage & Bible Text */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="space-y-1.5 md:col-span-1">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1 flex items-center gap-1">
                    <BookOpen size={14} className="text-dorado" />
                    Pasaje Bíblico
                  </label>
                  <input
                    type="text"
                    placeholder="ej. Filipenses 4:13"
                    className="w-full glass-input text-xs"
                    {...register('bible_passage', { required: 'El pasaje de referencia es obligatorio' })}
                  />
                  {errors.bible_passage && (
                    <span className="text-[10px] text-error-red font-medium ml-1">{errors.bible_passage.message}</span>
                  )}
                </div>

                <div className="space-y-1.5 md:col-span-2">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Texto de la Escritura</label>
                  <textarea
                    rows={2}
                    placeholder="Escribe el texto bíblico para el devocional..."
                    className="w-full glass-input text-xs resize-none"
                    {...register('bible_text', { required: 'El texto bíblico es obligatorio' })}
                  />
                  {errors.bible_text && (
                    <span className="text-[10px] text-error-red font-medium ml-1">{errors.bible_text.message}</span>
                  )}
                </div>
              </div>

              {/* Devotional content (Reflection) */}
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Mensaje de Reflexión</label>
                <textarea
                  rows={8}
                  placeholder="Redacta la reflexión espiritual de hoy..."
                  className="w-full glass-input text-xs resize-y"
                  {...register('content', { required: 'La reflexión es obligatoria' })}
                />
                {errors.content && (
                  <span className="text-[10px] text-error-red font-medium ml-1">{errors.content.message}</span>
                )}
              </div>

              {/* Actions Buttons */}
              <div className="flex justify-end gap-3 pt-4 border-t border-white border-opacity-5">
                <Link to="/devocionales" className="btn-secondary text-xs font-semibold">
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
                      Guardar Devocional
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
              <span>Previsualización del Devocional (App)</span>
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
                {/* Daily tag and Date */}
                <div className="space-y-1">
                  <span className="text-[9px] font-extrabold text-dorado uppercase tracking-widest block">Devocional Diario</span>
                  <span className="text-[10px] text-crema text-opacity-50 block capitalize font-medium">
                    {watchedDate ? formatPreviewDate(watchedDate) : 'Fecha del Devocional'}
                  </span>
                </div>

                {/* Title */}
                <h2 className="text-sm font-extrabold text-crema leading-snug">
                  {watchedTitle || 'Título de Hoy'}
                </h2>

                {/* Simulated Audio Bar */}
                {watchedAudio && (
                  <div className="p-2.5 bg-dark-teal bg-opacity-50 border border-white border-opacity-10 rounded-xl flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Music size={14} className="text-teal-400 animate-pulse" />
                      <span className="text-[9px] font-bold">Escuchar Devocional</span>
                    </div>
                    <div className="w-6 h-6 rounded-full bg-dorado flex items-center justify-center text-deep-teal font-extrabold text-[10px]">
                      ▶
                    </div>
                  </div>
                )}

                {/* Scripture box */}
                {(watchedPassage || watchedPassageText) && (
                  <div className="p-3 bg-genesis-card-sec bg-opacity-40 border border-dorado border-opacity-20 rounded-xl text-[9px] space-y-1.5">
                    <span className="font-bold text-dorado block flex items-center gap-1">
                      <BookOpen size={12} />
                      {watchedPassage || 'Pasaje Bíblico'}
                    </span>
                    <p className="text-crema text-opacity-70 leading-relaxed italic">
                      "{watchedPassageText || 'Texto de las Escrituras...'}"
                    </p>
                  </div>
                )}

                {/* Content */}
                <p className="text-[10px] text-crema text-opacity-80 leading-relaxed whitespace-pre-line">
                  {watchedContent || 'Cuerpo del mensaje devocional...'}
                </p>
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

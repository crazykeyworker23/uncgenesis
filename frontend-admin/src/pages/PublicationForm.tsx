import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  ArrowLeft, 
  Save, 
  Eye, 
  Globe, 
  Settings, 
  Info
} from 'lucide-react';
import { apiClient } from '../api/client';
import { PublicationCategory, PublicationContentType } from '../features/publications/types';
import { Logo } from '../components/ui/Logo';

export const PublicationForm: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const isEdit = !!id;
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const { register, handleSubmit, watch, setValue, formState: { errors } } = useForm({
    defaultValues: {
      title: '',
      slug: '',
      summary: '',
      content: '',
      content_type: 'GENERAL' as PublicationContentType,
      category: '',
      status: 'DRAFT',
      is_featured: false,
      show_in_app: true,
      send_notification: false,
      seo_title: '',
      seo_description: '',
      cover_image_url: '', // Text input or simulated upload for demo simplicity
    }
  });

  // Watch fields for mobile preview
  const watchedTitle = watch('title');
  const watchedContent = watch('content');
  const watchedSummary = watch('summary');
  const watchedType = watch('content_type');
  const watchedCoverUrl = watch('cover_image_url');
  const watchedCategory = watch('category');

  // 1. Fetch Categories and Tags
  const { data: categories } = useQuery<PublicationCategory[]>({
    queryKey: ['categories'],
    queryFn: async () => {
      const res = await apiClient.get('/categories/');
      // Django DRF default pagination check
      return Array.isArray(res.data) ? res.data : res.data.results || [];
    }
  });

  // 2. If editing, fetch publication details
  const { data: publication, isLoading: isFetchingDetails } = useQuery({
    queryKey: ['publication', id],
    queryFn: async () => {
      const res = await apiClient.get(`/publications/${id}/?simple=true`);
      return res.data;
    },
    enabled: isEdit,
  });

  // Set form values on edit load
  useEffect(() => {
    if (isEdit && publication) {
      setValue('title', publication.title);
      setValue('slug', publication.slug);
      setValue('summary', publication.summary);
      setValue('content', publication.content);
      setValue('content_type', publication.content_type);
      setValue('category', publication.category ? String(publication.category) : '');
      setValue('status', publication.status);
      setValue('is_featured', publication.is_featured);
      setValue('show_in_app', publication.show_in_app);
      setValue('send_notification', publication.send_notification);
      setValue('seo_title', publication.seo_title);
      setValue('seo_description', publication.seo_description);
      if (publication.cover_image) {
        setValue('cover_image_url', publication.cover_image);
      }
    }
  }, [isEdit, publication, setValue]);

  // Generate slug automatically based on title in form
  const handleTitleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setValue('title', val);
    const generatedSlug = val
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)+/g, '');
    setValue('slug', generatedSlug);
  };

  // 3. Save Mutation
  const saveMutation = useMutation({
    mutationFn: async (formData: any) => {
      const payload = {
        title: formData.title,
        slug: formData.slug,
        summary: formData.summary,
        content: formData.content,
        content_type: formData.content_type,
        category: formData.category ? parseInt(formData.category) : null,
        status: formData.status,
        is_featured: formData.is_featured,
        show_in_app: formData.show_in_app,
        send_notification: formData.send_notification,
        seo_title: formData.seo_title,
        seo_description: formData.seo_description,
        // Since we are simulating, we can send a text image or handle files.
        // If it starts with http, we can pass it, otherwise send null/empty.
        cover_image: formData.cover_image_url || null
      };

      if (isEdit) {
        return apiClient.put(`/publications/${id}/`, payload);
      } else {
        return apiClient.post('/publications/', payload);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['publications'] });
      navigate('/publicaciones');
    },
    onError: (err: any) => {
      setErrorMsg(err.response?.data?.detail || 'Error al guardar la publicación.');
    }
  });

  const onSubmit = (data: any) => {
    setErrorMsg(null);
    saveMutation.mutate(data);
  };

  const getCategoryName = (catId: string) => {
    if (!categories) return '';
    const cat = categories.find(c => String(c.id) === catId);
    return cat ? cat.name : '';
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link 
          to="/publicaciones" 
          className="p-2 rounded-xl bg-dark-teal bg-opacity-40 hover:bg-opacity-60 border border-white border-opacity-10 transition-colors"
        >
          <ArrowLeft size={16} />
        </Link>
        <div>
          <h1 className="text-xl font-extrabold text-crema leading-none">
            {isEdit ? 'Editar Publicación' : 'Nueva Publicación'}
          </h1>
          <p className="text-xs text-crema text-opacity-50 mt-1">
            {isEdit ? 'Modifica el contenido o metadatos de la publicación.' : 'Escribe y diseña una nueva tarjeta de contenido.'}
          </p>
        </div>
      </div>

      {isFetchingDetails ? (
        <div className="p-12 flex flex-col items-center justify-center gap-3">
          <div className="w-8 h-8 border-4 border-dorado border-t-transparent rounded-full animate-spin" />
          <span className="text-xs text-crema text-opacity-50">Cargando detalles de publicación...</span>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
          {/* Form container */}
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
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Título</label>
                  <input
                    type="text"
                    placeholder="Título del artículo"
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
                    placeholder="url-del-articulo"
                    className="w-full glass-input text-xs"
                    {...register('slug', { required: 'El slug es obligatorio' })}
                  />
                  {errors.slug && (
                    <span className="text-[10px] text-error-red font-medium ml-1">{errors.slug.message}</span>
                  )}
                </div>
              </div>

              {/* Type, Category & Status */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Tipo de Contenido</label>
                  <select
                    className="w-full bg-dark-teal bg-opacity-50 border border-white border-opacity-10 rounded-xl px-4 py-3 text-xs text-crema focus:outline-none focus:border-dorado focus:ring-1 focus:ring-dorado"
                    {...register('content_type')}
                  >
                    <option value="GENERAL">General</option>
                    <option value="NEWS">Noticia</option>
                    <option value="SERVICE">Servicio</option>
                    <option value="DEVOTIONAL">Devocional</option>
                    <option value="EVENT">Evento</option>
                    <option value="YOUTH">Jóvenes</option>
                  </select>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Categoría</label>
                  <select
                    className="w-full bg-dark-teal bg-opacity-50 border border-white border-opacity-10 rounded-xl px-4 py-3 text-xs text-crema focus:outline-none focus:border-dorado focus:ring-1 focus:ring-dorado"
                    {...register('category')}
                  >
                    <option value="">Sin Categoría</option>
                    {categories?.map((cat) => (
                      <option key={cat.id} value={cat.id}>{cat.name}</option>
                    ))}
                  </select>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Estado de Publicación</label>
                  <select
                    className="w-full bg-dark-teal bg-opacity-50 border border-white border-opacity-10 rounded-xl px-4 py-3 text-xs text-crema focus:outline-none focus:border-dorado focus:ring-1 focus:ring-dorado"
                    {...register('status')}
                  >
                    <option value="DRAFT">Borrador</option>
                    <option value="PUBLISHED">Publicado</option>
                    <option value="SCHEDULED">Programado</option>
                    <option value="ARCHIVED">Archivado</option>
                  </select>
                </div>
              </div>

              {/* Cover Image Input */}
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">URL de Portada (Simulado)</label>
                <input
                  type="text"
                  placeholder="https://ejemplo.com/portada.jpg"
                  className="w-full glass-input text-xs"
                  {...register('cover_image_url')}
                />
              </div>

              {/* Summary */}
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Resumen (Breve resumen para tarjetas)</label>
                <textarea
                  rows={2}
                  placeholder="Escribe un breve resumen de esta publicación..."
                  className="w-full glass-input text-xs resize-none"
                  {...register('summary')}
                />
              </div>

              {/* Content */}
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Cuerpo del Contenido</label>
                <textarea
                  rows={8}
                  placeholder="Escribe todo el contenido de tu publicación aquí..."
                  className="w-full glass-input text-xs resize-y"
                  {...register('content', { required: 'El cuerpo del contenido es obligatorio' })}
                />
                {errors.content && (
                  <span className="text-[10px] text-error-red font-medium ml-1">{errors.content.message}</span>
                )}
              </div>

              {/* Checkboxes Options */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 py-2 border-y border-white border-opacity-5">
                <label className="flex items-center gap-2.5 text-xs text-crema text-opacity-70 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    className="accent-dorado w-4 h-4 rounded border-white border-opacity-10 bg-deep-teal focus:ring-0"
                    {...register('is_featured')}
                  />
                  Destacar en Inicio
                </label>

                <label className="flex items-center gap-2.5 text-xs text-crema text-opacity-70 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    className="accent-dorado w-4 h-4 rounded border-white border-opacity-10 bg-deep-teal focus:ring-0"
                    {...register('show_in_app')}
                  />
                  Mostrar en la App
                </label>

                <label className="flex items-center gap-2.5 text-xs text-crema text-opacity-70 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    className="accent-dorado w-4 h-4 rounded border-white border-opacity-10 bg-deep-teal focus:ring-0"
                    {...register('send_notification')}
                  />
                  Enviar Notificación Push
                </label>
              </div>

              {/* SEO details */}
              <div className="space-y-4">
                <div className="flex items-center gap-2 text-xs font-bold text-dorado uppercase tracking-wider py-1">
                  <Settings size={14} />
                  <span>Configuración SEO</span>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Título SEO</label>
                    <input
                      type="text"
                      placeholder="Título SEO (opcional)"
                      className="w-full glass-input text-xs"
                      {...register('seo_title')}
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-crema text-opacity-65 ml-1">Descripción SEO</label>
                    <input
                      type="text"
                      placeholder="Meta descripción SEO (opcional)"
                      className="w-full glass-input text-xs"
                      {...register('seo_description')}
                    />
                  </div>
                </div>
              </div>

              {/* Actions Buttons */}
              <div className="flex justify-end gap-3 pt-4 border-t border-white border-opacity-5">
                <Link to="/publicaciones" className="btn-secondary text-xs font-semibold">
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
                      Guardar Cambios
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
              <span>Previsualización Móvil (App)</span>
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
                {/* Simulated Article Details */}
                {watchedCoverUrl ? (
                  <div className="w-full h-32 rounded-xl bg-dark-teal overflow-hidden border border-white border-opacity-10">
                    <img src={watchedCoverUrl} alt="" className="w-full h-full object-cover" />
                  </div>
                ) : (
                  <div className="w-full h-32 rounded-xl bg-dark-teal border border-white border-opacity-5 flex items-center justify-center">
                    <Globe size={32} className="text-crema text-opacity-10" />
                  </div>
                )}

                {/* Article Header info */}
                <div className="space-y-1.5">
                  <div className="flex items-center gap-2">
                    <span className="text-[9px] font-bold uppercase px-1.5 py-0.5 bg-dorado bg-opacity-10 text-dorado rounded">
                      {watchedType ? watchedType : 'GENERAL'}
                    </span>
                    {watchedCategory && (
                      <span className="text-[9px] text-crema text-opacity-50">
                        • {getCategoryName(watchedCategory)}
                      </span>
                    )}
                  </div>
                  <h2 className="text-sm font-extrabold text-crema leading-snug">
                    {watchedTitle || 'Título de la Publicación'}
                  </h2>
                </div>

                {/* Summary */}
                {watchedSummary && (
                  <p className="text-[10px] text-crema text-opacity-60 italic leading-relaxed border-l-2 border-dorado pl-2">
                    {watchedSummary}
                  </p>
                )}

                {/* Content */}
                <p className="text-[10px] text-crema text-opacity-80 leading-relaxed whitespace-pre-line">
                  {watchedContent || 'Aquí se mostrará el cuerpo del contenido redactado en el formulario...'}
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

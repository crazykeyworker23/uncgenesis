import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Image, FileText, Music, Video, File, Search, Plus, Trash2,
  Copy, Check, X, Upload, AlertCircle, ArrowLeft, ArrowRight, ExternalLink
} from 'lucide-react';
import { apiClient } from '../api/client';
import {
  Multimedia, MediaType, PaginatedMultimedia,
  MEDIA_TYPE_LABELS, MEDIA_TYPE_COLORS
} from '../features/multimedia/types';

// Helper to format file sizes
const formatBytes = (bytes: number, decimals = 2) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
};

// Icon Selector by Media Type
const getMediaIcon = (type: MediaType, className = "w-6 h-6") => {
  switch (type) {
    case 'IMAGE': return <Image className={`${className} text-emerald-400`} />;
    case 'PDF': return <FileText className={`${className} text-red-400`} />;
    case 'AUDIO': return <Music className={`${className} text-violet-400`} />;
    case 'VIDEO': return <Video className={`${className} text-amber-400`} />;
    default: return <File className={`${className} text-gray-400`} />;
  }
};

export const MultimediaList: React.FC = () => {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [page, setPage] = useState(1);

  // Upload modal state
  const [isUploadOpen, setIsUploadOpen] = useState(false);
  const [uploadTitle, setUploadTitle] = useState('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploadError, setUploadError] = useState<string | null>(null);

  // Clipboard copy feedback
  const [copiedId, setCopiedId] = useState<number | null>(null);

  // Fetch paginated media items
  const { data, isLoading, isError } = useQuery<PaginatedMultimedia>({
    queryKey: ['multimedia', search, typeFilter, page],
    queryFn: async () => {
      const res = await apiClient.get('/multimedia/', {
        params: {
          search: search || undefined,
          file_type: typeFilter || undefined,
          page,
        },
      });
      return res.data;
    },
  });

  // Upload Mutation
  const uploadMutation = useMutation({
    mutationFn: async (payload: { title: string; file: File }) => {
      const formData = new FormData();
      formData.append('title', payload.title);
      formData.append('file', payload.file);
      const res = await apiClient.post('/multimedia/', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['multimedia'] });
      setIsUploadOpen(false);
      setUploadTitle('');
      setSelectedFile(null);
      setUploadError(null);
    },
    onError: (err: any) => {
      const details = err.response?.data;
      if (typeof details === 'object') {
        const msg = Object.entries(details)
          .map(([key, val]) => `${key}: ${Array.isArray(val) ? val.join(', ') : val}`)
          .join(' | ');
        setUploadError(msg);
      } else {
        setUploadError('Error de red al subir el archivo.');
      }
    },
  });

  // Delete Mutation
  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      await apiClient.delete(`/multimedia/${id}/`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['multimedia'] });
    },
  });

  const handleCopyLink = (item: Multimedia) => {
    const url = item.file_url || item.file;
    navigator.clipboard.writeText(url).then(() => {
      setCopiedId(item.id);
      setTimeout(() => setCopiedId(null), 2000);
    });
  };

  const handleDelete = (item: Multimedia) => {
    if (window.confirm(`¿Seguro que deseas eliminar permanentemente el archivo "${item.title}" de la biblioteca?`)) {
      deleteMutation.mutate(item.id);
    }
  };

  const handleUploadSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setUploadError(null);
    if (!uploadTitle.trim()) {
      setUploadError('El título es obligatorio.');
      return;
    }
    if (!selectedFile) {
      setUploadError('Debes seleccionar un archivo para subir.');
      return;
    }
    uploadMutation.mutate({ title: uploadTitle, file: selectedFile });
  };

  const results = data?.results ?? [];
  const totalPages = data ? Math.ceil(data.count / 10) : 1;

  return (
    <div className="space-y-6">
      {/* Upload Modal overlay */}
      {isUploadOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black bg-opacity-40 backdrop-blur-sm" onClick={() => setIsUploadOpen(false)} />
          <div className="relative w-full max-w-md bg-gray-900 border border-white/10 rounded-3xl p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-white/5 pb-3">
              <h3 className="text-base font-bold text-white flex items-center gap-2">
                <Upload className="w-5 h-5 text-dorado" />
                Subir Archivo a Biblioteca
              </h3>
              <button
                onClick={() => setIsUploadOpen(false)}
                className="p-1 text-gray-400 hover:text-white rounded-lg hover:bg-gray-800 transition-all"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {uploadError && (
              <div className="p-3 bg-red-950/30 border border-red-900/40 rounded-xl text-red-300 text-xs flex items-center gap-2">
                <AlertCircle className="w-4 h-4 text-red-400 shrink-0" />
                <span>{uploadError}</span>
              </div>
            )}

            <form onSubmit={handleUploadSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <label className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
                  Nombre descriptivo / Título *
                </label>
                <input
                  type="text"
                  placeholder="ej. Foto Campamento 2026"
                  value={uploadTitle}
                  onChange={(e) => setUploadTitle(e.target.value)}
                  className="w-full px-4 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl text-white placeholder-crema placeholder-opacity-35 text-xs focus:outline-none focus:border-dorado"
                />
              </div>

              <div className="space-y-1.5">
                <label className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
                  Seleccionar Archivo *
                </label>
                <div className="flex items-center justify-center border-2 border-dashed border-white/15 hover:border-dorado/50 rounded-2xl p-6 transition-colors relative bg-deep-teal/10">
                  <input
                    type="file"
                    onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
                    className="absolute inset-0 opacity-0 cursor-pointer w-full h-full"
                  />
                  <div className="text-center space-y-2 pointer-events-none">
                    <Upload className="w-8 h-8 text-crema/40 mx-auto" />
                    <p className="text-xs text-white font-medium">
                      {selectedFile ? selectedFile.name : 'Haz clic o arrastra un archivo'}
                    </p>
                    <p className="text-[10px] text-crema/40">
                      Soporta imágenes, videos, audios y documentos PDF
                    </p>
                  </div>
                </div>
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="submit"
                  disabled={uploadMutation.isPending}
                  className="flex-1 py-2.5 bg-teal-600 hover:bg-teal-500 disabled:opacity-50 text-white rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-2 shadow"
                >
                  {uploadMutation.isPending ? (
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <Upload className="w-4 h-4" />
                  )}
                  Iniciar Carga
                </button>
                <button
                  type="button"
                  onClick={() => setIsUploadOpen(false)}
                  className="px-4 py-2.5 bg-gray-800 hover:bg-gray-700 text-crema text-opacity-70 hover:text-white rounded-xl text-xs font-semibold transition-all"
                >
                  Cancelar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <Image className="w-6 h-6 text-dorado" />
            Biblioteca Multimedia
          </h1>
          <p className="text-sm text-crema text-opacity-50 mt-1">
            Gestión y almacenamiento centralizado de recursos visuales y documentos
          </p>
        </div>
        <button
          onClick={() => setIsUploadOpen(true)}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-teal-600 hover:bg-teal-500 text-white rounded-xl text-sm font-semibold transition-all shadow"
        >
          <Plus className="w-4 h-4" />
          Subir Archivo
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-crema text-opacity-40" />
          <input
            id="media-search"
            type="text"
            placeholder="Buscar por título de archivo..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            className="w-full pl-10 pr-4 py-2.5 bg-deep-teal bg-opacity-30 border border-white border-opacity-10 text-white rounded-xl text-sm placeholder-crema placeholder-opacity-40 focus:outline-none focus:border-dorado transition-all"
          />
        </div>
        <select
          id="media-type-filter"
          value={typeFilter}
          onChange={(e) => {
            setTypeFilter(e.target.value);
            setPage(1);
          }}
          className="px-3 py-2.5 bg-deep-teal bg-opacity-30 border border-white border-opacity-10 text-crema rounded-xl text-sm focus:outline-none focus:border-dorado transition-all"
        >
          <option value="" className="bg-gray-900 text-crema">Todos los tipos</option>
          <option value="IMAGE" className="bg-gray-900 text-crema">Imágenes</option>
          <option value="PDF" className="bg-gray-900 text-crema">Documentos PDF</option>
          <option value="AUDIO" className="bg-gray-900 text-crema">Audios</option>
          <option value="VIDEO" className="bg-gray-900 text-crema">Videos</option>
          <option value="OTHER" className="bg-gray-900 text-crema">Otros archivos</option>
        </select>
      </div>

      {/* Grid Display */}
      {isLoading ? (
        <div className="flex flex-col items-center justify-center py-20 text-crema text-opacity-50">
          <div className="animate-spin w-8 h-8 border-4 border-dorado border-t-transparent rounded-full mb-3" />
          Cargando archivos multimedia...
        </div>
      ) : isError ? (
        <div className="flex items-center justify-center gap-2 py-20 text-error-red">
          <AlertCircle className="w-5 h-5" />
          Error al cargar la biblioteca. Intenta de nuevo.
        </div>
      ) : results.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-crema text-opacity-40 italic glass-panel border border-white/5 rounded-2xl">
          <File className="w-12 h-12 mb-3 opacity-20" />
          <p>No se encontraron archivos en la biblioteca</p>
        </div>
      ) : (
        <div className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {results.map((item) => (
              <div
                key={item.id}
                className="glass-panel bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl overflow-hidden flex flex-col justify-between group hover:border-white/10 transition-all shadow-md"
              >
                {/* Visual Thumbnail */}
                <div className="h-40 bg-deep-teal/40 flex items-center justify-center relative overflow-hidden">
                  {item.file_type === 'IMAGE' && item.file ? (
                    <img
                      src={item.file}
                      alt={item.title}
                      className="w-full h-full object-cover group-hover:scale-[1.03] transition-transform duration-300"
                    />
                  ) : (
                    <div className="p-4 bg-dark-teal/20 rounded-full">
                      {getMediaIcon(item.file_type, "w-10 h-10")}
                    </div>
                  )}
                  <span className={`absolute top-3 left-3 px-2 py-0.5 rounded-lg text-[9px] font-bold border ${MEDIA_TYPE_COLORS[item.file_type]}`}>
                    {MEDIA_TYPE_LABELS[item.file_type]}
                  </span>
                </div>

                {/* Details */}
                <div className="p-4 space-y-3 flex-1 flex flex-col justify-between">
                  <div className="space-y-1">
                    <h4 className="font-bold text-white text-xs line-clamp-2 leading-snug group-hover:text-dorado transition-colors" title={item.title}>
                      {item.title}
                    </h4>
                    <p className="text-[10px] text-crema/40 font-mono truncate" title={item.file.split('/').pop()}>
                      Archivo: {item.file.split('/').pop()}
                    </p>
                    <p className="text-[10px] text-crema text-opacity-50">
                      Tamaño: <span className="font-medium text-white">{formatBytes(item.file_size)}</span>
                    </p>
                  </div>

                  <div className="flex items-center justify-between pt-3 border-t border-white/5 text-[10px] text-crema/40">
                    <span>Subido por {item.uploaded_by?.full_name || 'Sistema'}</span>
                  </div>

                  {/* Actions */}
                  <div className="flex gap-2 pt-2">
                    <button
                      id={`copy-url-btn-${item.id}`}
                      onClick={() => handleCopyLink(item)}
                      className={`flex-1 py-1.5 rounded-lg text-[10px] font-bold flex items-center justify-center gap-1 transition-all border ${
                        copiedId === item.id
                          ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                          : 'bg-white/5 text-white border-white/5 hover:bg-white/10 hover:border-white/10'
                      }`}
                    >
                      {copiedId === item.id ? (
                        <>
                          <Check className="w-3.5 h-3.5" /> Copiado
                        </>
                      ) : (
                        <>
                          <Copy className="w-3.5 h-3.5" /> Copiar Enlace
                        </>
                      )}
                    </button>
                    <a
                      href={item.file_url || item.file}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-1.5 bg-white/5 hover:bg-white/10 border border-white/5 hover:border-white/10 rounded-lg text-crema/70 hover:text-white transition-all flex items-center justify-center"
                      title="Abrir en pestaña nueva"
                    >
                      <ExternalLink className="w-3.5 h-3.5" />
                    </a>
                    <button
                      id={`delete-media-btn-${item.id}`}
                      onClick={() => handleDelete(item)}
                      className="p-1.5 bg-red-950/20 hover:bg-red-500/10 border border-red-950/30 hover:border-red-500/20 rounded-lg text-red-400 transition-all flex items-center justify-center"
                      title="Eliminar archivo"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Pagination Footer */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between px-6 py-4 border border-white border-opacity-5 rounded-2xl bg-deep-teal bg-opacity-40">
              <p className="text-xs text-crema text-opacity-50">
                Página <span className="text-white font-semibold">{page}</span> de <span className="text-white font-semibold">{totalPages}</span>
              </p>
              <div className="flex items-center gap-2">
                <button
                  id="media-prev"
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="p-2 text-crema hover:text-white disabled:opacity-25 transition-all"
                >
                  <ArrowLeft className="w-4 h-4" />
                </button>
                <button
                  id="media-next"
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="p-2 text-crema hover:text-white disabled:opacity-25 transition-all"
                >
                  <ArrowRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

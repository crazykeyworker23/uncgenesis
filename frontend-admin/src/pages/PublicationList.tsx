import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { 
  Plus, 
  Search, 
  Filter, 
  Edit, 
  Copy, 
  Archive, 
  Trash2, 
  Globe, 
  Eye, 
  Calendar,
  AlertCircle
} from 'lucide-react';
import { apiClient } from '../api/client';
import { Can } from '../components/auth/Can';
import { Publication, PublicationStatus, PublicationContentType } from '../features/publications/types';

export const PublicationList: React.FC = () => {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [typeFilter, setTypeFilter] = useState<string>('');
  const [page, setPage] = useState(1);

  // 1. Fetch Publications using TanStack Query
  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['publications', search, statusFilter, typeFilter, page],
    queryFn: async () => {
      const response = await apiClient.get('/publications/', {
        params: {
          search: search || undefined,
          status: statusFilter || undefined,
          content_type: typeFilter || undefined,
          page: page,
        }
      });
      return response.data;
    }
  });

  // 2. Actions Mutations
  const publishMutation = useMutation({
    mutationFn: (id: number) => apiClient.post(`/publications/${id}/publish/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['publications'] });
    }
  });

  const archiveMutation = useMutation({
    mutationFn: (id: number) => apiClient.post(`/publications/${id}/archive/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['publications'] });
    }
  });

  const duplicateMutation = useMutation({
    mutationFn: (id: number) => apiClient.post(`/publications/${id}/duplicate/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['publications'] });
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => apiClient.delete(`/publications/${id}/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['publications'] });
    }
  });

  const getStatusBadge = (status: PublicationStatus) => {
    switch (status) {
      case 'PUBLISHED':
        return <span className="px-2.5 py-1 bg-exito bg-opacity-10 text-exito rounded-full text-[10px] font-bold border border-exito border-opacity-15">Publicado</span>;
      case 'DRAFT':
        return <span className="px-2.5 py-1 bg-crema bg-opacity-10 text-crema text-opacity-70 rounded-full text-[10px] font-bold border border-white border-opacity-10">Borrador</span>;
      case 'SCHEDULED':
        return <span className="px-2.5 py-1 bg-advertencia bg-opacity-10 text-advertencia rounded-full text-[10px] font-bold border border-advertencia border-opacity-15">Programado</span>;
      case 'ARCHIVED':
        return <span className="px-2.5 py-1 bg-blue-500 bg-opacity-10 text-blue-400 rounded-full text-[10px] font-bold border border-blue-500 border-opacity-15">Archivado</span>;
      default:
        return null;
    }
  };

  const getContentTypeLabel = (type: PublicationContentType) => {
    const labels: Record<PublicationContentType, string> = {
      NEWS: 'Noticia',
      SERVICE: 'Servicio',
      DEVOTIONAL: 'Devocional',
      EVENT: 'Evento',
      YOUTH: 'Jóvenes',
      GENERAL: 'General',
    };
    return labels[type] || type;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-crema leading-none">Publicaciones</h1>
          <p className="text-xs text-crema text-opacity-50 mt-1.5">Redacta, edita y programa contenido oficial para Génesis App.</p>
        </div>
        <Can permission="PUBLICATIONS_CREATE">
        <Link 
          to="/publicaciones/nueva" 
          className="flex items-center justify-center gap-2 btn-primary text-xs font-bold self-start sm:self-center"
        >
          <Plus size={16} />
          Nueva Publicación
        </Link>
        </Can>
      </div>

      {/* Filters Bar */}
      <div className="glass-panel p-4 bg-dark-teal bg-opacity-20 flex flex-col md:flex-row gap-4 items-center">
        {/* Search */}
        <div className="flex items-center gap-2 px-3 py-2 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl w-full md:w-80 text-xs">
          <Search size={16} className="text-crema text-opacity-40" />
          <input 
            type="text" 
            placeholder="Buscar por título, contenido..." 
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            className="bg-transparent border-none text-crema placeholder-crema placeholder-opacity-40 focus:outline-none w-full"
          />
        </div>

        {/* Filters */}
        <div className="flex flex-wrap items-center gap-3 w-full md:w-auto md:ml-auto">
          {/* Status Filter */}
          <div className="flex items-center gap-2">
            <Filter size={14} className="text-crema text-opacity-40" />
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setPage(1);
              }}
              className="bg-dark-teal bg-opacity-50 border border-white border-opacity-10 rounded-xl px-3 py-2 text-xs text-crema focus:outline-none focus:border-dorado"
            >
              <option value="">Todos los Estados</option>
              <option value="DRAFT">Borrador</option>
              <option value="PUBLISHED">Publicado</option>
              <option value="SCHEDULED">Programado</option>
              <option value="ARCHIVED">Archivado</option>
            </select>
          </div>

          {/* Type Filter */}
          <select
            value={typeFilter}
            onChange={(e) => {
              setTypeFilter(e.target.value);
              setPage(1);
            }}
            className="bg-dark-teal bg-opacity-50 border border-white border-opacity-10 rounded-xl px-3 py-2 text-xs text-crema focus:outline-none focus:border-dorado"
          >
            <option value="">Todos los Tipos</option>
            <option value="NEWS">Noticia</option>
            <option value="SERVICE">Servicio</option>
            <option value="DEVOTIONAL">Devocional</option>
            <option value="EVENT">Evento</option>
            <option value="YOUTH">Jóvenes</option>
            <option value="GENERAL">General</option>
          </select>
        </div>
      </div>

      {/* Errors alert */}
      {isError && (
        <div className="flex items-center gap-2 p-3 bg-error-red bg-opacity-15 text-error-red border border-error-red border-opacity-20 rounded-xl text-xs">
          <AlertCircle size={16} />
          <span>Error al cargar las publicaciones: {(error as any)?.message}</span>
        </div>
      )}

      {/* Publications Table */}
      <div className="glass-panel bg-dark-teal bg-opacity-15 overflow-hidden">
        {isLoading ? (
          <div className="p-12 flex flex-col items-center justify-center gap-3">
            <div className="w-8 h-8 border-4 border-dorado border-t-transparent rounded-full animate-spin" />
            <span className="text-xs text-crema text-opacity-50">Cargando publicaciones...</span>
          </div>
        ) : !data?.results || data.results.length === 0 ? (
          <div className="p-12 text-center">
            <span className="text-xs text-crema text-opacity-40">No se encontraron publicaciones.</span>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-white border-opacity-5 text-[10px] font-bold uppercase tracking-wider text-crema text-opacity-40 bg-deep-teal bg-opacity-20">
                  <th className="px-6 py-4">Portada</th>
                  <th className="px-6 py-4">Título</th>
                  <th className="px-6 py-4">Tipo</th>
                  <th className="px-6 py-4">Categoría</th>
                  <th className="px-6 py-4">Estado</th>
                  <th className="px-6 py-4">Vistas</th>
                  <th className="px-6 py-4">Publicado</th>
                  <th className="px-6 py-4 text-right">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white divide-opacity-5 text-xs">
                {data.results.map((pub: Publication) => (
                  <tr key={pub.id} className="hover:bg-white hover:bg-opacity-5 transition-colors">
                    {/* Cover image */}
                    <td className="px-6 py-4">
                      <div className="w-12 h-10 rounded-lg bg-deep-teal border border-white border-opacity-10 overflow-hidden flex items-center justify-center">
                        {pub.cover_image ? (
                          <img src={pub.cover_image} alt="" className="w-full h-full object-cover" />
                        ) : (
                          <Globe size={16} className="text-crema text-opacity-25" />
                        )}
                      </div>
                    </td>

                    {/* Title */}
                    <td className="px-6 py-4 font-bold text-crema max-w-xs truncate">
                      <span title={pub.title}>{pub.title}</span>
                    </td>

                    {/* Type */}
                    <td className="px-6 py-4 text-crema text-opacity-70">
                      {getContentTypeLabel(pub.content_type)}
                    </td>

                    {/* Category */}
                    <td className="px-6 py-4 text-crema text-opacity-70">
                      {pub.category?.name || 'Sin Categoría'}
                    </td>

                    {/* Status */}
                    <td className="px-6 py-4">
                      {getStatusBadge(pub.status)}
                    </td>

                    {/* Views */}
                    <td className="px-6 py-4 font-semibold text-crema text-opacity-80">
                      <div className="flex items-center gap-1.5">
                        <Eye size={14} className="text-crema text-opacity-35" />
                        {pub.views_count}
                      </div>
                    </td>

                    {/* Date */}
                    <td className="px-6 py-4 text-crema text-opacity-55">
                      {pub.published_at ? (
                        <div className="flex items-center gap-1.5">
                          <Calendar size={13} className="text-crema text-opacity-35" />
                          {new Date(pub.published_at).toLocaleDateString('es-PE')}
                        </div>
                      ) : (
                        <span className="text-[10px] italic">No publicado</span>
                      )}
                    </td>

                    {/* Inline Actions */}
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-1.5 whitespace-nowrap">
                        <Can permission="PUBLICATIONS_EDIT">
                          <Link 
                          to={`/publicaciones/${pub.id}/editar`}
                          className="p-2 bg-white/5 hover:bg-dorado/20 text-crema hover:text-dorado border border-white/10 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                          title="Editar Publicación"
                        >
                          <Edit size={14} />
                          <span className="hidden xl:inline">Editar</span>
                        </Link>
                        </Can>

                        {pub.status !== 'PUBLISHED' && (
                          <button
                            onClick={() => publishMutation.mutate(pub.id)}
                            className="p-2 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                            title="Publicar"
                          >
                            <Globe size={14} />
                            <span className="hidden xl:inline">Publicar</span>
                          </button>
                        )}

                        {pub.status === 'PUBLISHED' && (
                          <button
                            onClick={() => archiveMutation.mutate(pub.id)}
                            className="p-2 bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 border border-blue-500/20 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                            title="Archivar"
                          >
                            <Archive size={14} />
                            <span className="hidden xl:inline">Archivar</span>
                          </button>
                        )}

                        <Can permission="PUBLICATIONS_CREATE">
                          <button
                          onClick={() => duplicateMutation.mutate(pub.id)}
                          className="p-2 bg-white/5 hover:bg-white/10 text-crema/70 hover:text-crema border border-white/10 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                          title="Duplicar"
                        >
                          <Copy size={14} />
                        </button>
                        </Can>

                        <Can permission="PUBLICATIONS_DELETE">
                          <button
                          onClick={() => {
                            if (window.confirm('¿Seguro que deseas eliminar esta publicación?')) {
                              deleteMutation.mutate(pub.id);
                            }
                          }}
                          className="p-2 bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/20 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                          title="Eliminar"
                        >
                          <Trash2 size={14} />
                        </button>
                        </Can>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Paginación */}
        {data?.count && data.count > 10 && (
          <div className="flex items-center justify-between px-6 py-4 border-t border-white border-opacity-5 bg-deep-teal bg-opacity-10 text-xs">
            <span className="text-crema text-opacity-40">
              Mostrando {data.results.length} de {data.count} publicaciones
            </span>
            <div className="flex gap-2">
              <button
                disabled={page === 1}
                onClick={() => setPage(p => Math.max(1, p - 1))}
                className="px-3 py-1.5 bg-genesis-card-sec border border-white border-opacity-10 rounded-lg disabled:opacity-30"
              >
                Anterior
              </button>
              <button
                disabled={!data.next}
                onClick={() => setPage(p => p + 1)}
                className="px-3 py-1.5 bg-genesis-card-sec border border-white border-opacity-10 rounded-lg disabled:opacity-30"
              >
                Siguiente
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

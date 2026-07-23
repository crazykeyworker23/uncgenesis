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
  Video, 
  Music, 
  Calendar,
  AlertCircle,
  Radio,
  Eye
} from 'lucide-react';
import { apiClient } from '../api/client';
import { ChurchService, ServiceStatus } from '../features/services/types';

export const ServiceList: React.FC = () => {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [isLiveFilter, setIsLiveFilter] = useState<string>('');
  const [page, setPage] = useState(1);

  // 1. Fetch Services
  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['services', search, statusFilter, isLiveFilter, page],
    queryFn: async () => {
      const response = await apiClient.get('/services/', {
        params: {
          search: search || undefined,
          status: statusFilter || undefined,
          is_live: isLiveFilter === 'true' ? true : isLiveFilter === 'false' ? false : undefined,
          page: page,
        }
      });
      return response.data;
    }
  });

  // 2. Actions Mutations
  const publishMutation = useMutation({
    mutationFn: (id: number) => apiClient.post(`/services/${id}/publish/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
    }
  });

  const archiveMutation = useMutation({
    mutationFn: (id: number) => apiClient.post(`/services/${id}/archive/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
    }
  });

  const duplicateMutation = useMutation({
    mutationFn: (id: number) => apiClient.post(`/services/${id}/duplicate/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => apiClient.delete(`/services/${id}/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
    }
  });

  const getStatusBadge = (status: ServiceStatus) => {
    switch (status) {
      case 'PUBLISHED':
        return <span className="px-2.5 py-1 bg-exito bg-opacity-10 text-exito rounded-full text-[10px] font-bold border border-exito border-opacity-15">Publicado</span>;
      case 'DRAFT':
        return <span className="px-2.5 py-1 bg-crema bg-opacity-10 text-crema text-opacity-70 rounded-full text-[10px] font-bold border border-white border-opacity-10">Borrador</span>;
      case 'ARCHIVED':
        return <span className="px-2.5 py-1 bg-blue-500 bg-opacity-10 text-blue-400 rounded-full text-[10px] font-bold border border-blue-500 border-opacity-15">Archivado</span>;
      default:
        return null;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-crema leading-none">Servicios Religiosos</h1>
          <p className="text-xs text-crema text-opacity-50 mt-1.5">Administra las prédicas dominicales, versículos leídos y transmisiones en vivo.</p>
        </div>
        <Link 
          to="/servicios/nuevo" 
          className="flex items-center justify-center gap-2 btn-primary text-xs font-bold self-start sm:self-center"
        >
          <Plus size={16} />
          Registrar Culto
        </Link>
      </div>

      {/* Filters Bar */}
      <div className="glass-panel p-4 bg-dark-teal bg-opacity-20 flex flex-col md:flex-row gap-4 items-center">
        {/* Search */}
        <div className="flex items-center gap-2 px-3 py-2 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl w-full md:w-80 text-xs">
          <Search size={16} className="text-crema text-opacity-40" />
          <input 
            type="text" 
            placeholder="Buscar por título, notas..." 
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
              <option value="ARCHIVED">Archivado</option>
            </select>
          </div>

          {/* Live Filter */}
          <select
            value={isLiveFilter}
            onChange={(e) => {
              setIsLiveFilter(e.target.value);
              setPage(1);
            }}
            className="bg-dark-teal bg-opacity-50 border border-white border-opacity-10 rounded-xl px-3 py-2 text-xs text-crema focus:outline-none focus:border-dorado"
          >
            <option value="">¿Transmitido En Vivo?</option>
            <option value="true">Sí (En Vivo)</option>
            <option value="false">No (Grabación)</option>
          </select>
        </div>
      </div>

      {/* Errors alert */}
      {isError && (
        <div className="flex items-center gap-2 p-3 bg-error-red bg-opacity-15 text-error-red border border-error-red border-opacity-20 rounded-xl text-xs">
          <AlertCircle size={16} />
          <span>Error al cargar los servicios: {(error as any)?.message}</span>
        </div>
      )}

      {/* Services Table */}
      <div className="glass-panel bg-dark-teal bg-opacity-15 overflow-hidden">
        {isLoading ? (
          <div className="p-12 flex flex-col items-center justify-center gap-3">
            <div className="w-8 h-8 border-4 border-dorado border-t-transparent rounded-full animate-spin" />
            <span className="text-xs text-crema text-opacity-50">Cargando servicios religiosos...</span>
          </div>
        ) : !data?.results || data.results.length === 0 ? (
          <div className="p-12 text-center">
            <span className="text-xs text-crema text-opacity-40">No se encontraron servicios registrados.</span>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-white border-opacity-5 text-[10px] font-bold uppercase tracking-wider text-crema text-opacity-40 bg-deep-teal bg-opacity-20">
                  <th className="px-6 py-4">Fecha</th>
                  <th className="px-6 py-4">Título del Sermón</th>
                  <th className="px-6 py-4">Transmisión</th>
                  <th className="px-6 py-4">Multimedia</th>
                  <th className="px-6 py-4">Versículos</th>
                  <th className="px-6 py-4">Estado</th>
                  <th className="px-6 py-4">Vistas</th>
                  <th className="px-6 py-4 text-right">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white divide-opacity-5 text-xs">
                {data.results.map((serv: ChurchService) => (
                  <tr key={serv.id} className="hover:bg-white hover:bg-opacity-5 transition-colors">
                    {/* Date */}
                    <td className="px-6 py-4 text-crema text-opacity-70 font-semibold">
                      <div className="flex items-center gap-1.5">
                        <Calendar size={14} className="text-crema text-opacity-35" />
                        {new Date(serv.date).toLocaleDateString('es-PE')}
                      </div>
                    </td>

                    {/* Title */}
                    <td className="px-6 py-4 font-bold text-crema max-w-xs truncate">
                      <span title={serv.title}>{serv.title}</span>
                    </td>

                    {/* Live Stream */}
                    <td className="px-6 py-4">
                      {serv.is_live ? (
                        <span className="flex items-center gap-1 text-[10px] font-extrabold text-error-red bg-error-red bg-opacity-10 border border-error-red border-opacity-15 px-2 py-0.5 rounded-full w-max">
                          <Radio size={10} className="animate-pulse" />
                          EN VIVO
                        </span>
                      ) : (
                        <span className="text-[10px] text-crema text-opacity-40">Grabado</span>
                      )}
                    </td>

                    {/* Media present */}
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2 text-crema text-opacity-40">
                        {serv.video_url && (
                          <span title="Video disponible">
                            <Video size={16} className="text-dorado" />
                          </span>
                        )}
                        {serv.audio_url && (
                          <span title="Audio disponible">
                            <Music size={16} className="text-teal-400" />
                          </span>
                        )}
                        {!serv.video_url && !serv.audio_url && '-'}
                      </div>
                    </td>

                    {/* Verses Count */}
                    <td className="px-6 py-4 font-medium text-crema text-opacity-60">
                      {serv.verses ? serv.verses.length : 0} versos
                    </td>

                    {/* Status */}
                    <td className="px-6 py-4">
                      {getStatusBadge(serv.status)}
                    </td>

                    {/* Views */}
                    <td className="px-6 py-4 font-semibold text-crema text-opacity-80">
                      <div className="flex items-center gap-1.5">
                        <Eye size={14} className="text-crema text-opacity-35" />
                        {serv.views_count}
                      </div>
                    </td>

                      {/* Inline Actions */}
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-1.5 whitespace-nowrap">
                          <Link 
                            to={`/servicios/${serv.id}/editar`}
                            className="p-2 bg-white/5 hover:bg-dorado/20 text-crema hover:text-dorado border border-white/10 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                            title="Editar Servicio"
                          >
                            <Edit size={14} />
                            <span className="hidden xl:inline">Editar</span>
                          </Link>

                          {serv.status !== 'PUBLISHED' && (
                            <button
                              onClick={() => publishMutation.mutate(serv.id)}
                              className="p-2 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                              title="Publicar"
                            >
                              <Radio size={14} />
                              <span className="hidden xl:inline">Publicar</span>
                            </button>
                          )}

                          {serv.status === 'PUBLISHED' && (
                            <button
                              onClick={() => archiveMutation.mutate(serv.id)}
                              className="p-2 bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 border border-blue-500/20 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                              title="Archivar"
                            >
                              <Archive size={14} />
                              <span className="hidden xl:inline">Archivar</span>
                            </button>
                          )}

                          <button
                            onClick={() => duplicateMutation.mutate(serv.id)}
                            className="p-2 bg-white/5 hover:bg-white/10 text-crema/70 hover:text-crema border border-white/10 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                            title="Duplicar"
                          >
                            <Copy size={14} />
                          </button>

                          <button
                            onClick={() => {
                              if (window.confirm('¿Seguro que deseas eliminar este servicio?')) {
                                deleteMutation.mutate(serv.id);
                              }
                            }}
                            className="p-2 bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/20 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                            title="Eliminar"
                          >
                            <Trash2 size={14} />
                          </button>
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
              Mostrando {data.results.length} de {data.count} cultos
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

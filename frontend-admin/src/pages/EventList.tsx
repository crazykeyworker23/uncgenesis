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
  MapPin, 
  Calendar,
  AlertCircle,
  Users,
  XCircle,
  Globe
} from 'lucide-react';
import { apiClient } from '../api/client';
import { Event, EventStatus } from '../features/events/types';

export const EventList: React.FC = () => {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [page, setPage] = useState(1);

  // 1. Fetch Events
  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['events', search, statusFilter, page],
    queryFn: async () => {
      const response = await apiClient.get('/events/', {
        params: {
          search: search || undefined,
          status: statusFilter || undefined,
          page: page,
        }
      });
      return response.data;
    }
  });

  // 2. Mutations
  const publishMutation = useMutation({
    mutationFn: (id: number) => apiClient.post(`/events/${id}/publish/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['events'] });
    }
  });

  const archiveMutation = useMutation({
    mutationFn: (id: number) => apiClient.post(`/events/${id}/archive/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['events'] });
    }
  });

  const cancelMutation = useMutation({
    mutationFn: (id: number) => apiClient.post(`/events/${id}/cancel/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['events'] });
    }
  });

  const duplicateMutation = useMutation({
    mutationFn: (id: number) => apiClient.post(`/events/${id}/duplicate/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['events'] });
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => apiClient.delete(`/events/${id}/`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['events'] });
    }
  });

  const getStatusBadge = (status: EventStatus) => {
    switch (status) {
      case 'PUBLISHED':
        return <span className="px-2.5 py-1 bg-exito bg-opacity-10 text-exito rounded-full text-[10px] font-bold border border-exito border-opacity-15">Publicado</span>;
      case 'DRAFT':
        return <span className="px-2.5 py-1 bg-crema bg-opacity-10 text-crema text-opacity-70 rounded-full text-[10px] font-bold border border-white border-opacity-10">Borrador</span>;
      case 'CANCELLED':
        return <span className="px-2.5 py-1 bg-error-red bg-opacity-10 text-error-red rounded-full text-[10px] font-bold border border-error-red border-opacity-15">Cancelado</span>;
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
          <h1 className="text-2xl font-extrabold text-crema leading-none">Eventos y Conferencias</h1>
          <p className="text-xs text-crema text-opacity-50 mt-1.5">Organiza eventos de la iglesia, talleres, conferencias y monitorea las inscripciones.</p>
        </div>
        <Link 
          to="/eventos/nuevo" 
          className="flex items-center justify-center gap-2 btn-primary text-xs font-bold self-start sm:self-center"
        >
          <Plus size={16} />
          Nuevo Evento
        </Link>
      </div>

      {/* Filters Bar */}
      <div className="glass-panel p-4 bg-dark-teal bg-opacity-20 flex flex-col md:flex-row gap-4 items-center">
        {/* Search */}
        <div className="flex items-center gap-2 px-3 py-2 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl w-full md:w-80 text-xs">
          <Search size={16} className="text-crema text-opacity-40" />
          <input 
            type="text" 
            placeholder="Buscar por título, ubicación..." 
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
              <option value="CANCELLED">Cancelado</option>
              <option value="ARCHIVED">Archivado</option>
            </select>
          </div>
        </div>
      </div>

      {/* Errors alert */}
      {isError && (
        <div className="flex items-center gap-2 p-3 bg-error-red bg-opacity-15 text-error-red border border-error-red border-opacity-20 rounded-xl text-xs">
          <AlertCircle size={16} />
          <span>Error al cargar los eventos: {(error as any)?.message}</span>
        </div>
      )}

      {/* Events Table */}
      <div className="glass-panel bg-dark-teal bg-opacity-15 overflow-hidden">
        {isLoading ? (
          <div className="p-12 flex flex-col items-center justify-center gap-3">
            <div className="w-8 h-8 border-4 border-dorado border-t-transparent rounded-full animate-spin" />
            <span className="text-xs text-crema text-opacity-50">Cargando eventos...</span>
          </div>
        ) : !data?.results || data.results.length === 0 ? (
          <div className="p-12 text-center">
            <span className="text-xs text-crema text-opacity-40">No se encontraron eventos registrados.</span>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-white border-opacity-5 text-[10px] font-bold uppercase tracking-wider text-crema text-opacity-40 bg-deep-teal bg-opacity-20">
                  <th className="px-6 py-4">Portada</th>
                  <th className="px-6 py-4">Título</th>
                  <th className="px-6 py-4">Fecha de Inicio</th>
                  <th className="px-6 py-4">Ubicación</th>
                  <th className="px-6 py-4">Aforo / Inscriptos</th>
                  <th className="px-6 py-4">Estado</th>
                  <th className="px-6 py-4 text-right">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white divide-opacity-5 text-xs">
                {data.results.map((evt: Event) => {
                  const capacityPercent = evt.capacity ? Math.min(100, Math.round((evt.registered_count / evt.capacity) * 100)) : 0;
                  return (
                    <tr key={evt.id} className="hover:bg-white hover:bg-opacity-5 transition-colors">
                      {/* Image cover */}
                      <td className="px-6 py-4">
                        <div className="w-12 h-10 rounded-lg bg-deep-teal border border-white border-opacity-10 overflow-hidden flex items-center justify-center">
                          {evt.cover_image ? (
                            <img src={evt.cover_image} alt="" className="w-full h-full object-cover" />
                          ) : (
                            <Globe size={16} className="text-crema text-opacity-25" />
                          )}
                        </div>
                      </td>

                      {/* Title */}
                      <td className="px-6 py-4 font-bold text-crema max-w-xs truncate">
                        <span title={evt.title}>{evt.title}</span>
                      </td>

                      {/* Start date */}
                      <td className="px-6 py-4 text-crema text-opacity-70 font-semibold">
                        <div className="flex items-center gap-1.5">
                          <Calendar size={14} className="text-crema text-opacity-35" />
                          {new Date(evt.start_date).toLocaleString('es-PE', { dateStyle: 'short', timeStyle: 'short' })}
                        </div>
                      </td>

                      {/* Location */}
                      <td className="px-6 py-4 text-crema text-opacity-65 max-w-xs truncate">
                        <div className="flex items-center gap-1">
                          <MapPin size={14} className="text-crema text-opacity-35" />
                          {evt.location}
                        </div>
                      </td>

                      {/* Capacity progress */}
                      <td className="px-6 py-4">
                        {evt.requires_registration ? (
                          <div className="space-y-1.5 w-32">
                            <div className="flex justify-between items-center text-[10px] font-semibold text-crema text-opacity-60">
                              <span className="flex items-center gap-0.5">
                                <Users size={12} />
                                {evt.registered_count}
                              </span>
                              <span>{evt.capacity ? `/ ${evt.capacity}` : 'Ilimitado'}</span>
                            </div>
                            {evt.capacity && (
                              <div className="w-full h-1.5 bg-dark-teal rounded-full overflow-hidden">
                                <div 
                                  className={`h-full rounded-full transition-all duration-300 ${
                                    capacityPercent >= 90 ? 'bg-error-red' : capacityPercent >= 50 ? 'bg-advertencia' : 'bg-dorado'
                                  }`}
                                  style={{ width: `${capacityPercent}%` }}
                                />
                              </div>
                            )}
                          </div>
                        ) : (
                          <span className="text-[10px] text-crema text-opacity-40 italic">No requiere reg.</span>
                        )}
                      </td>

                      {/* Status */}
                      <td className="px-6 py-4">
                        {getStatusBadge(evt.status)}
                      </td>

                      {/* Inline Actions */}
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-1.5 whitespace-nowrap">
                          <Link 
                            to={`/eventos/${evt.id}/editar`}
                            className="p-2 bg-white/5 hover:bg-dorado/20 text-crema hover:text-dorado border border-white/10 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                            title="Editar Evento"
                          >
                            <Edit size={14} />
                            <span className="hidden xl:inline">Editar</span>
                          </Link>

                          {evt.status !== 'PUBLISHED' && (
                            <button
                              onClick={() => publishMutation.mutate(evt.id)}
                              className="p-2 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                              title="Publicar Evento"
                            >
                              <Globe size={14} />
                              <span className="hidden xl:inline">Publicar</span>
                            </button>
                          )}

                          {evt.status === 'PUBLISHED' && (
                            <button
                              onClick={() => archiveMutation.mutate(evt.id)}
                              className="p-2 bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 border border-blue-500/20 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                              title="Archivar Evento"
                            >
                              <Archive size={14} />
                              <span className="hidden xl:inline">Archivar</span>
                            </button>
                          )}

                          {evt.status !== 'CANCELLED' && (
                            <button
                              onClick={() => cancelMutation.mutate(evt.id)}
                              className="p-2 bg-amber-500/10 hover:bg-amber-500/20 text-amber-400 border border-amber-500/20 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                              title="Cancelar Evento"
                            >
                              <XCircle size={14} />
                              <span className="hidden xl:inline">Cancelar</span>
                            </button>
                          )}

                          <button
                            onClick={() => duplicateMutation.mutate(evt.id)}
                            className="p-2 bg-white/5 hover:bg-white/10 text-crema/70 hover:text-crema border border-white/10 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                            title="Duplicar Evento"
                          >
                            <Copy size={14} />
                          </button>

                          <button
                            onClick={() => {
                              if (window.confirm('¿Seguro que deseas eliminar este evento?')) {
                                deleteMutation.mutate(evt.id);
                              }
                            }}
                            className="p-2 bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/20 rounded-xl transition-all flex items-center gap-1 text-xs font-semibold"
                            title="Eliminar Evento"
                          >
                            <Trash2 size={14} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Paginación */}
        {data?.count && data.count > 10 && (
          <div className="flex items-center justify-between px-6 py-4 border-t border-white border-opacity-5 bg-deep-teal bg-opacity-10 text-xs">
            <span className="text-crema text-opacity-40">
              Mostrando {data.results.length} de {data.count} eventos
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

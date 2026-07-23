import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

const RequestsTabs: React.FC = () => {
  const location = useLocation();
  const isPrayers = location.pathname.includes('/oraciones');
  const isVisitors = location.pathname.includes('/visitas');

  return (
    <div className="flex border-b border-white border-opacity-5 mb-6">
      <Link
        to="/solicitudes/oraciones"
        className={`px-4 py-2.5 text-xs font-bold border-b-2 transition-all ${
          isPrayers
            ? 'border-dorado text-dorado font-bold'
            : 'border-transparent text-crema text-opacity-50 hover:text-white'
        }`}
      >
        Peticiones de Oración
      </Link>
      <Link
        to="/solicitudes/visitas"
        className={`px-4 py-2.5 text-xs font-bold border-b-2 transition-all ${
          isVisitors
            ? 'border-dorado text-dorado font-bold'
            : 'border-transparent text-crema text-opacity-50 hover:text-white'
        }`}
      >
        Solicitudes de Visita
      </Link>
    </div>
  );
};
import {
  Search, Heart, ChevronLeft, ChevronRight, X, UserCheck,
  Trash2, Eye, Clock,
} from 'lucide-react';
import { apiClient } from '../api/client';
import {
  PrayerRequest, RequestStatus, REQUEST_STATUS_CONFIG,
  PaginatedRequests,
} from '../features/requests/types';

// ── Detail Slide-over Panel ─────────────────────────────────────────────────
interface PrayerDetailProps {
  item: PrayerRequest;
  onClose: () => void;
  onStatusChange: (id: number, status: RequestStatus, notes: string) => void;
  users: { id: number; first_name: string; last_name: string; email: string }[];
  onAssign: (id: number, userId: number | null) => void;
}

const PrayerDetail: React.FC<PrayerDetailProps> = ({ item, onClose, onStatusChange, users, onAssign }) => {
  const [newStatus, setNewStatus] = useState<RequestStatus>(item.status);
  const [notes, setNotes] = useState(item.notes);
  const [assignee, setAssignee] = useState(item.assigned_to?.id?.toString() ?? '');

  const cfg = REQUEST_STATUS_CONFIG[item.status];

  return (
    <div className="fixed inset-0 z-50 flex justify-end" onClick={onClose}>
      <div
        className="w-full max-w-md h-full bg-gray-900 border-l border-gray-800 flex flex-col shadow-2xl overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-800">
          <div className="flex items-center gap-2">
            <Heart className="w-5 h-5 text-rose-400" />
            <span className="font-semibold text-white">Solicitud de Oración</span>
          </div>
          <button id="prayer-detail-close" onClick={onClose} className="p-1.5 text-gray-400 hover:text-white transition-colors">
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="flex-1 p-5 space-y-5">
          {/* Requester */}
          <div>
            <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">Solicitante</p>
            <p className="text-white font-semibold">
              {item.is_anonymous ? '🔒 Anónimo' : item.requester_name}
            </p>
            {!item.is_anonymous && (
              <div className="text-sm text-gray-400 mt-0.5 space-y-0.5">
                {item.requester_email && <p>✉ {item.requester_email}</p>}
                {item.requester_phone && <p>📞 {item.requester_phone}</p>}
              </div>
            )}
          </div>

          {/* Subject & description */}
          <div>
            <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">Asunto</p>
            <p className="text-teal-300 font-medium">{item.subject}</p>
            <p className="text-gray-300 text-sm mt-2 leading-relaxed">{item.description}</p>
          </div>

          {/* Status badge */}
          <div className="flex items-center gap-2">
            <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${cfg.classes}`}>
              {cfg.label}
            </span>
            <span className="text-xs text-gray-500 flex items-center gap-1">
              <Clock className="w-3 h-3" />
              {new Date(item.created_at).toLocaleDateString('es-PE', { day:'2-digit', month:'short', year:'numeric' })}
            </span>
          </div>

          <hr className="border-gray-800" />

          {/* Assign */}
          <div>
            <label htmlFor={`prayer-assign-${item.id}`} className="block text-xs text-gray-500 uppercase tracking-wider mb-1.5">
              <UserCheck className="inline w-3 h-3 mr-1" />Asignar responsable
            </label>
            <div className="flex gap-2">
              <select
                id={`prayer-assign-${item.id}`}
                value={assignee}
                onChange={(e) => setAssignee(e.target.value)}
                className="flex-1 px-3 py-2 bg-gray-800 border border-gray-700 text-white rounded-lg text-sm focus:outline-none focus:border-teal-500"
              >
                <option value="">Sin asignar</option>
                {users.map((u) => (
                  <option key={u.id} value={u.id}>
                    {u.first_name} {u.last_name}
                  </option>
                ))}
              </select>
              <button
                id={`prayer-save-assign-${item.id}`}
                onClick={() => onAssign(item.id, assignee ? parseInt(assignee) : null)}
                className="px-3 py-2 bg-teal-600 hover:bg-teal-500 text-white rounded-lg text-sm transition-colors"
              >
                Guardar
              </button>
            </div>
          </div>

          {/* Change status */}
          <div>
            <label className="block text-xs text-gray-500 uppercase tracking-wider mb-2">Cambiar estado</label>
            <div className="grid grid-cols-2 gap-2">
              {(Object.keys(REQUEST_STATUS_CONFIG) as RequestStatus[]).map((s) => (
                <button
                  key={s}
                  id={`prayer-status-${s}-${item.id}`}
                  onClick={() => setNewStatus(s)}
                  className={`py-1.5 px-2 rounded-lg text-xs font-medium border transition-colors ${
                    newStatus === s
                      ? REQUEST_STATUS_CONFIG[s].classes
                      : 'border-gray-700 text-gray-500 hover:border-gray-600'
                  }`}
                >
                  {REQUEST_STATUS_CONFIG[s].label}
                </button>
              ))}
            </div>
          </div>

          {/* Internal notes */}
          <div>
            <label htmlFor={`prayer-notes-${item.id}`} className="block text-xs text-gray-500 uppercase tracking-wider mb-1.5">
              Notas internas (visibles solo para el equipo)
            </label>
            <textarea
              id={`prayer-notes-${item.id}`}
              rows={3}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Agrega notas de seguimiento…"
              className="w-full px-3 py-2 bg-gray-800 border border-gray-700 text-white placeholder-gray-600 rounded-lg text-sm focus:outline-none focus:border-teal-500 resize-none"
            />
          </div>

          <button
            id={`prayer-update-${item.id}`}
            onClick={() => onStatusChange(item.id, newStatus, notes)}
            className="w-full py-2.5 bg-teal-600 hover:bg-teal-500 text-white rounded-lg text-sm font-semibold transition-colors"
          >
            Actualizar solicitud
          </button>
        </div>
      </div>
    </div>
  );
};

// ── Main List Page ───────────────────────────────────────────────────────────
export const PrayerRequestList: React.FC = () => {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<PrayerRequest | null>(null);

  const { data, isLoading, isError } = useQuery<PaginatedRequests<PrayerRequest>>({
    queryKey: ['prayer-requests', search, statusFilter, page],
    queryFn: async () => {
      const res = await apiClient.get('/prayer-requests/', {
        params: { search: search || undefined, status: statusFilter || undefined, page },
      });
      return res.data;
    },
  });

  const { data: usersData } = useQuery({
    queryKey: ['users-list'],
    queryFn: async () => {
      const res = await apiClient.get('/users/', { params: { page_size: 200 } });
      return res.data;
    },
  });
  const users = usersData?.results ?? [];

  const changeStatusMutation = useMutation({
    mutationFn: ({ id, status, notes }: { id: number; status: RequestStatus; notes: string }) =>
      apiClient.post(`/prayer-requests/${id}/change-status/`, { status, notes }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['prayer-requests'] });
      setSelected(null);
    },
  });

  const assignMutation = useMutation({
    mutationFn: ({ id, assigned_to_id }: { id: number; assigned_to_id: number | null }) =>
      apiClient.post(`/prayer-requests/${id}/assign/`, { assigned_to_id }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['prayer-requests'] });
      setSelected(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => apiClient.delete(`/prayer-requests/${id}/`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['prayer-requests'] }),
  });

  const items = data?.results ?? [];
  const totalPages = data ? Math.ceil(data.count / 10) : 1;

  return (
    <>
      {selected && (
        <PrayerDetail
          item={selected}
          onClose={() => setSelected(null)}
          users={users}
          onStatusChange={(id, status, notes) => changeStatusMutation.mutate({ id, status, notes })}
          onAssign={(id, userId) => assignMutation.mutate({ id, assigned_to_id: userId })}
        />
      )}

      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-white flex items-center gap-2">
              <Heart className="w-6 h-6 text-rose-400" />
              Solicitudes de Oración
            </h1>
            <p className="text-sm text-gray-400 mt-1">{data?.count ?? 0} solicitudes registradas</p>
          </div>
        </div>

        <RequestsTabs />

        {/* Filters */}
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              id="prayer-search"
              type="text"
              placeholder="Buscar por nombre o asunto…"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-700 text-white rounded-lg text-sm placeholder-gray-500 focus:outline-none focus:border-teal-500"
            />
          </div>
          <select
            id="prayer-status-filter"
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
            className="px-3 py-2 bg-gray-800 border border-gray-700 text-white rounded-lg text-sm focus:outline-none focus:border-teal-500"
          >
            <option value="">Todos los estados</option>
            {(Object.keys(REQUEST_STATUS_CONFIG) as RequestStatus[]).map((s) => (
              <option key={s} value={s}>{REQUEST_STATUS_CONFIG[s].label}</option>
            ))}
          </select>
        </div>

        {/* Table */}
        <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
          {isLoading ? (
            <div className="flex items-center justify-center py-20 text-gray-400">
              <div className="animate-spin w-6 h-6 border-2 border-rose-400 border-t-transparent rounded-full mr-3" />
              Cargando solicitudes…
            </div>
          ) : isError ? (
            <div className="flex items-center justify-center gap-2 py-20 text-red-400">
              Error al cargar. Intenta nuevamente.
            </div>
          ) : items.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-gray-500">
              <Heart className="w-10 h-10 mb-3 opacity-30" />
              <p>No hay solicitudes de oración</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-800 text-gray-400 text-xs uppercase tracking-wider">
                    <th className="px-4 py-3 text-left">Solicitante</th>
                    <th className="px-4 py-3 text-left">Asunto</th>
                    <th className="px-4 py-3 text-left">Responsable</th>
                    <th className="px-4 py-3 text-center">Estado</th>
                    <th className="px-4 py-3 text-center">Fecha</th>
                    <th className="px-4 py-3 text-center">Acciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-800">
                  {items.map((item) => {
                    const cfg = REQUEST_STATUS_CONFIG[item.status];
                    return (
                      <tr
                        key={item.id}
                        className="hover:bg-gray-800/50 transition-colors cursor-pointer group"
                        onClick={() => setSelected(item)}
                      >
                        <td className="px-4 py-3">
                          <div className="font-medium text-white group-hover:text-rose-300 transition-colors">
                            {item.is_anonymous ? '🔒 Anónimo' : item.requester_name}
                          </div>
                          {item.requester_email && !item.is_anonymous && (
                            <div className="text-xs text-gray-500">{item.requester_email}</div>
                          )}
                        </td>
                        <td className="px-4 py-3">
                          <p className="text-white line-clamp-1">{item.subject}</p>
                          <p className="text-xs text-gray-500 line-clamp-1 mt-0.5">{item.description}</p>
                        </td>
                        <td className="px-4 py-3">
                          {item.assigned_to ? (
                            <div className="flex items-center gap-1.5">
                              <div className="w-6 h-6 rounded-full bg-teal-700 flex items-center justify-center flex-shrink-0">
                                <span className="text-[9px] text-white font-bold">
                                  {item.assigned_to.first_name?.[0]?.toUpperCase()}
                                </span>
                              </div>
                              <span className="text-sm text-gray-300">
                                {item.assigned_to.first_name} {item.assigned_to.last_name}
                              </span>
                            </div>
                          ) : (
                            <span className="text-xs text-gray-600 italic">Sin asignar</span>
                          )}
                        </td>
                        <td className="px-4 py-3 text-center">
                          <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium border ${cfg.classes}`}>
                            {cfg.label}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-center text-xs text-gray-500">
                          {new Date(item.created_at).toLocaleDateString('es-PE')}
                        </td>
                        <td className="px-4 py-3 text-right" onClick={(e) => e.stopPropagation()}>
                          <div className="flex items-center justify-end gap-1.5 whitespace-nowrap">
                            <button
                              id={`prayer-view-${item.id}`}
                              onClick={() => setSelected(item)}
                              className="p-2 bg-white/5 hover:bg-rose-500/20 text-crema hover:text-rose-300 border border-white/10 rounded-xl transition-all flex items-center gap-1.5 text-xs font-semibold"
                              title="Ver detalle"
                            >
                              <Eye className="w-3.5 h-3.5" />
                              <span>Ver</span>
                            </button>
                            <button
                              id={`prayer-delete-${item.id}`}
                              onClick={() => {
                                if (window.confirm(`¿Eliminar solicitud de "${item.is_anonymous ? 'Anónimo' : item.requester_name}"?`)) {
                                  deleteMutation.mutate(item.id);
                                }
                              }}
                              className="p-2 bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/20 rounded-xl transition-all flex items-center gap-1.5 text-xs font-semibold"
                              title="Eliminar"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
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

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between px-4 py-3 border-t border-gray-800">
              <p className="text-xs text-gray-500">Página {page} de {totalPages}</p>
              <div className="flex items-center gap-2">
                <button
                  id="prayer-prev-page"
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="p-1.5 text-gray-400 hover:text-white disabled:opacity-30 transition-colors"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <button
                  id="prayer-next-page"
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="p-1.5 text-gray-400 hover:text-white disabled:opacity-30 transition-colors"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </>
  );
};

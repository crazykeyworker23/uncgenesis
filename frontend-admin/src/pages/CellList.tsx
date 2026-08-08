import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  Plus,
  Search,
  Edit,
  Trash2,
  MapPin,
  Users,
  Clock,
  Activity,
  XCircle,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import { apiClient } from '../api/client';
import { Can } from '../components/auth/Can';
import { CellGroup, CellStatus, MeetingDay, MEETING_DAY_LABELS, PaginatedCells } from '../features/cells/types';

const STATUS_CONFIG: Record<CellStatus, { label: string; classes: string }> = {
  ACTIVE:   { label: 'Activo',   classes: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30' },
  INACTIVE: { label: 'Inactivo', classes: 'bg-gray-500/20  text-gray-400   border-gray-500/30'  },
};

const DAY_COLOR: Record<MeetingDay, string> = {
  MONDAY:    'bg-blue-500/20 text-blue-300',
  TUESDAY:   'bg-purple-500/20 text-purple-300',
  WEDNESDAY: 'bg-teal-500/20 text-teal-300',
  THURSDAY:  'bg-orange-500/20 text-orange-300',
  FRIDAY:    'bg-pink-500/20 text-pink-300',
  SATURDAY:  'bg-yellow-500/20 text-yellow-300',
  SUNDAY:    'bg-red-500/20 text-red-300',
};

export const CellList: React.FC = () => {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [page, setPage] = useState(1);

  const { data, isLoading, isError } = useQuery<PaginatedCells>({
    queryKey: ['cells', search, statusFilter, page],
    queryFn: async () => {
      const res = await apiClient.get('/cells/', {
        params: {
          search: search || undefined,
          status: statusFilter || undefined,
          page,
        },
      });
      return res.data;
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => apiClient.delete(`/cells/${id}/`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['cells'] }),
  });

  const handleDelete = (cell: CellGroup) => {
    if (window.confirm(`¿Eliminar el grupo "${cell.name}"? Esta acción no se puede deshacer.`)) {
      deleteMutation.mutate(cell.id);
    }
  };

  const cells = data?.results ?? [];
  const totalPages = data ? Math.ceil(data.count / 10) : 1;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">Grupos de Célula</h1>
          <p className="text-sm text-gray-400 mt-1">
            {data?.count ?? 0} grupos registrados en total
          </p>
        </div>
        <Can permission="CELLS_CREATE">
        <Link
          to="/celulas/nueva"
          className="inline-flex items-center gap-2 px-4 py-2 bg-teal-600 hover:bg-teal-500 text-white rounded-lg text-sm font-medium transition-colors"
        >
          <Plus className="w-4 h-4" />
          Nueva Célula
        </Link>
        </Can>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            id="cells-search"
            type="text"
            placeholder="Buscar por nombre, líder o dirección…"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-700 text-white rounded-lg text-sm placeholder-gray-500 focus:outline-none focus:border-teal-500 transition-colors"
          />
        </div>
        <select
          id="cells-status-filter"
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
          className="px-3 py-2 bg-gray-800 border border-gray-700 text-white rounded-lg text-sm focus:outline-none focus:border-teal-500 transition-colors"
        >
          <option value="">Todos los estados</option>
          <option value="ACTIVE">Activos</option>
          <option value="INACTIVE">Inactivos</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center py-20 text-gray-400">
            <div className="animate-spin w-6 h-6 border-2 border-teal-500 border-t-transparent rounded-full mr-3" />
            Cargando grupos…
          </div>
        ) : isError ? (
          <div className="flex items-center justify-center gap-2 py-20 text-red-400">
            <XCircle className="w-5 h-5" />
            Error al cargar los grupos. Intenta nuevamente.
          </div>
        ) : cells.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-gray-500">
            <Users className="w-10 h-10 mb-3 opacity-40" />
            <p className="font-medium">No hay grupos de célula</p>
            <p className="text-sm mt-1">Crea el primer grupo usando el botón superior.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-800 text-gray-400 text-xs uppercase tracking-wider">
                  <th className="px-4 py-3 text-left">Nombre del Grupo</th>
                  <th className="px-4 py-3 text-left">Líder</th>
                  <th className="px-4 py-3 text-left">Reunión</th>
                  <th className="px-4 py-3 text-left">Ubicación</th>
                  <th className="px-4 py-3 text-center">Estado</th>
                  <th className="px-4 py-3 text-center">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-800">
                {cells.map((cell) => {
                  const statusInfo = STATUS_CONFIG[cell.status];
                  const dayColor = DAY_COLOR[cell.meeting_day] ?? 'bg-gray-700 text-gray-300';
                  const meetingTime = cell.meeting_time?.slice(0, 5) ?? '';
                  return (
                    <tr
                      key={cell.id}
                      className="hover:bg-gray-800/50 transition-colors group"
                    >
                      {/* Name */}
                      <td className="px-4 py-3">
                        <div className="font-semibold text-white group-hover:text-teal-400 transition-colors">
                          {cell.name}
                        </div>
                        <div className="text-xs text-gray-500 font-mono">{cell.slug}</div>
                      </td>

                      {/* Leader */}
                      <td className="px-4 py-3">
                        {cell.leader ? (
                          <div>
                            <div className="text-white font-medium">
                              {cell.leader.first_name} {cell.leader.last_name}
                            </div>
                            <div className="text-xs text-gray-500">{cell.leader.email}</div>
                          </div>
                        ) : (
                          <span className="text-gray-500 italic text-xs">Sin líder asignado</span>
                        )}
                      </td>

                      {/* Meeting */}
                      <td className="px-4 py-3">
                        <div className="flex flex-col gap-1">
                          <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full w-fit ${dayColor}`}>
                            {MEETING_DAY_LABELS[cell.meeting_day]}
                          </span>
                          <span className="flex items-center gap-1 text-xs text-gray-400">
                            <Clock className="w-3 h-3" />
                            {meetingTime}
                          </span>
                        </div>
                      </td>

                      {/* Location */}
                      <td className="px-4 py-3">
                        <div className="flex items-start gap-1 text-gray-300 text-xs max-w-[200px]">
                          <MapPin className="w-3 h-3 text-teal-400 mt-0.5 flex-shrink-0" />
                          <span className="line-clamp-2">{cell.address}</span>
                        </div>
                        {cell.latitude && cell.longitude && (
                          <div className="flex items-center gap-1 mt-1 text-gray-500 text-xs">
                            <Activity className="w-3 h-3" />
                            {parseFloat(cell.latitude).toFixed(4)}, {parseFloat(cell.longitude).toFixed(4)}
                          </div>
                        )}
                      </td>

                      {/* Status */}
                      <td className="px-4 py-3 text-center">
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium border ${statusInfo.classes}`}>
                          {statusInfo.label}
                        </span>
                      </td>

                      {/* Actions */}
                      <td className="px-4 py-3 text-right">
                        <div className="flex items-center justify-end gap-1.5 whitespace-nowrap">
                          <Link
                            to={`/celulas/${cell.id}/editar`}
                            id={`cell-edit-${cell.id}`}
                            className="p-2 bg-white/5 hover:bg-dorado/20 text-crema hover:text-dorado border border-white/10 rounded-xl transition-all flex items-center gap-1.5 text-xs font-semibold"
                            title="Editar grupo"
                          >
                            <Edit className="w-3.5 h-3.5" />
                            <span>Editar</span>
                          </Link>
                          <button
                            id={`cell-delete-${cell.id}`}
                            onClick={() => handleDelete(cell)}
                            className="p-2 bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/20 rounded-xl transition-all flex items-center gap-1.5 text-xs font-semibold"
                            title="Eliminar grupo"
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
            <p className="text-xs text-gray-500">
              Página {page} de {totalPages} — {data?.count} grupos
            </p>
            <div className="flex items-center gap-2">
              <button
                id="cells-prev-page"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-1.5 text-gray-400 hover:text-white disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <button
                id="cells-next-page"
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-1.5 text-gray-400 hover:text-white disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  Bell, Search, Plus, Trash2, Send, Eye, X, Info,
  AlertTriangle, CheckCircle2, Clock, Users, ArrowLeft, ArrowRight
} from 'lucide-react';
import { apiClient } from '../api/client';
import {
  Notification, TARGET_AUDIENCE_LABELS,
  NOTIFICATION_STATUS_CONFIG, PaginatedNotifications
} from '../features/notifications/types';

// ── Detail Slide-over Drawer ────────────────────────────────────────────────
interface NotificationDetailProps {
  item: Notification;
  onClose: () => void;
  onSendNow: (id: number) => void;
  isSending: boolean;
}

const NotificationDetail: React.FC<NotificationDetailProps> = ({
  item, onClose, onSendNow, isSending
}) => {
  const statusCfg = NOTIFICATION_STATUS_CONFIG[item.status];
  const formattedScheduled = item.scheduled_for
    ? new Date(item.scheduled_for).toLocaleString('es-PE')
    : null;
  const formattedSent = item.sent_at
    ? new Date(item.sent_at).toLocaleString('es-PE')
    : null;
  const formattedCreated = new Date(item.created_at).toLocaleString('es-PE');

  return (
    <div className="fixed inset-0 z-50 flex justify-end" onClick={onClose}>
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black bg-opacity-40 backdrop-blur-sm" />

      {/* Drawer */}
      <div
        className="relative w-full max-w-md h-full bg-gray-900 border-l border-gray-800 flex flex-col shadow-2xl overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-800 bg-deep-teal bg-opacity-30">
          <div className="flex items-center gap-2">
            <Bell className="w-5 h-5 text-dorado animate-pulse" />
            <span className="font-semibold text-white">Detalle de Notificación</span>
          </div>
          <button
            id="notification-detail-close"
            onClick={onClose}
            className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-800 rounded-lg transition-all"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 p-5 space-y-6">
          {/* Status & Audience badges */}
          <div className="flex flex-wrap items-center gap-2">
            <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold border ${statusCfg.classes}`}>
              {statusCfg.label}
            </span>
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-teal-900/30 text-teal-300 border border-teal-800/30">
              <Users className="w-3.5 h-3.5" />
              {item.target_audience === 'USER' && item.target_user_detail
                ? `Para: ${item.target_user_detail.full_name || item.target_user_detail.email}`
                : TARGET_AUDIENCE_LABELS[item.target_audience]}
            </span>
          </div>

          {/* Title & Body */}
          <div className="space-y-2">
            <p className="text-xs text-gray-500 uppercase tracking-wider font-semibold">Mensaje</p>
            <h2 className="text-lg font-bold text-white leading-snug">{item.title}</h2>
            <p className="text-sm text-gray-300 leading-relaxed bg-gray-950/40 p-4 rounded-xl border border-white/5 whitespace-pre-wrap">
              {item.body}
            </p>
          </div>

          <hr className="border-gray-800" />

          {/* Tracking Details */}
          <div className="grid grid-cols-2 gap-4 text-xs text-gray-400">
            <div className="bg-gray-950/20 p-3 rounded-lg border border-white/5">
              <p className="text-gray-500 font-medium mb-1">Creado por</p>
              <p className="text-white font-semibold">{item.sender?.full_name || 'Desconocido'}</p>
              <p className="text-[10px] text-gray-500 truncate mt-0.5">{item.sender?.email}</p>
            </div>
            <div className="bg-gray-950/20 p-3 rounded-lg border border-white/5">
              <p className="text-gray-500 font-medium mb-1">Fecha de Creación</p>
              <p className="text-white font-semibold">{formattedCreated}</p>
            </div>

            {formattedScheduled && (
              <div className="bg-gray-950/20 p-3 rounded-lg border border-white/5 col-span-2">
                <p className="text-gray-500 font-medium mb-1 flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5 text-yellow-500" /> Programado Para
                </p>
                <p className="text-yellow-400 font-semibold">{formattedScheduled}</p>
              </div>
            )}

            {formattedSent && (
              <div className="bg-gray-950/20 p-3 rounded-lg border border-white/5 col-span-2">
                <p className="text-gray-500 font-medium mb-1 flex items-center gap-1">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" /> Enviado El
                </p>
                <p className="text-emerald-400 font-semibold">{formattedSent}</p>
              </div>
            )}
          </div>

          {/* Error Message */}
          {item.error_message && (
            <div className="p-3 bg-red-950/30 border border-red-900/40 rounded-xl text-red-300 text-xs">
              <p className="font-bold flex items-center gap-1.5 mb-1 text-red-400">
                <AlertTriangle className="w-3.5 h-3.5" /> Estado del Envío
              </p>
              <p className="leading-relaxed font-mono">{item.error_message}</p>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        {item.status !== 'SENT' && (
          <div className="p-4 border-t border-gray-800 bg-gray-950/20">
            <button
              id={`detail-send-now-${item.id}`}
              disabled={isSending}
              onClick={() => onSendNow(item.id)}
              className="w-full py-2.5 bg-teal-600 hover:bg-teal-500 disabled:opacity-50 text-white rounded-xl text-sm font-semibold transition-all flex items-center justify-center gap-2 shadow"
            >
              {isSending ? (
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <Send className="w-4 h-4" />
              )}
              Enviar Ahora
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

// ── Main Page Component ─────────────────────────────────────────────────────
export const NotificationList: React.FC = () => {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [audienceFilter, setAudienceFilter] = useState('');
  const [page, setPage] = useState(1);
  const [selectedItem, setSelectedItem] = useState<Notification | null>(null);

  // Fetch paginated notifications
  const { data, isLoading, isError } = useQuery<PaginatedNotifications>({
    queryKey: ['notifications', search, statusFilter, audienceFilter, page],
    queryFn: async () => {
      const res = await apiClient.get('/notifications/', {
        params: {
          search: search || undefined,
          status: statusFilter || undefined,
          target_audience: audienceFilter || undefined,
          page,
        },
      });
      return res.data;
    },
  });

  // Send Now Mutation
  const sendMutation = useMutation({
    mutationFn: async (id: number) => {
      const res = await apiClient.post(`/notifications/${id}/send-now/`);
      return res.data;
    },
    onSuccess: (updated) => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      // Keep detail view updated
      if (selectedItem?.id === updated.id) {
        setSelectedItem(updated);
      }
    },
  });

  // Delete Mutation
  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      await apiClient.delete(`/notifications/${id}/`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      setSelectedItem(null);
    },
  });

  const handleDelete = (item: Notification) => {
    if (window.confirm(`¿Seguro que deseas eliminar la notificación "${item.title}"?`)) {
      deleteMutation.mutate(item.id);
    }
  };

  const results = data?.results ?? [];
  const totalPages = data ? Math.ceil(data.count / 10) : 1;

  return (
    <div className="space-y-6">
      {/* Slide-over Detail panel */}
      {selectedItem && (
        <NotificationDetail
          item={selectedItem}
          onClose={() => setSelectedItem(null)}
          onSendNow={(id) => sendMutation.mutate(id)}
          isSending={sendMutation.isPending}
        />
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <Bell className="w-6 h-6 text-dorado" />
            Notificaciones Push
          </h1>
          <p className="text-sm text-crema text-opacity-50 mt-1">
            {data?.count ?? 0} notificaciones enviadas o programadas
          </p>
        </div>
        <Link
          to="/notificaciones/nueva"
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-teal-600 hover:bg-teal-500 text-white rounded-xl text-sm font-semibold transition-all shadow"
        >
          <Plus className="w-4 h-4" />
          Nueva Notificación
        </Link>
      </div>

      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-crema text-opacity-40" />
          <input
            id="notifications-search"
            type="text"
            placeholder="Buscar por título, cuerpo o remitente..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            className="w-full pl-10 pr-4 py-2.5 bg-deep-teal bg-opacity-30 border border-white border-opacity-10 text-white rounded-xl text-sm placeholder-crema placeholder-opacity-40 focus:outline-none focus:border-dorado transition-all"
          />
        </div>
        <select
          id="notifications-status-filter"
          value={statusFilter}
          onChange={(e) => {
            setStatusFilter(e.target.value);
            setPage(1);
          }}
          className="px-3 py-2.5 bg-deep-teal bg-opacity-30 border border-white border-opacity-10 text-crema rounded-xl text-sm focus:outline-none focus:border-dorado transition-all"
        >
          <option value="" className="bg-gray-900 text-crema">Todos los estados</option>
          <option value="PENDING" className="bg-gray-900 text-crema">Pendientes</option>
          <option value="SENT" className="bg-gray-900 text-crema">Enviados</option>
          <option value="FAILED" className="bg-gray-900 text-crema">Fallidos</option>
        </select>
        <select
          id="notifications-audience-filter"
          value={audienceFilter}
          onChange={(e) => {
            setAudienceFilter(e.target.value);
            setPage(1);
          }}
          className="px-3 py-2.5 bg-deep-teal bg-opacity-30 border border-white border-opacity-10 text-crema rounded-xl text-sm focus:outline-none focus:border-dorado transition-all"
        >
          <option value="" className="bg-gray-900 text-crema">Toda la audiencia</option>
          <option value="ALL" className="bg-gray-900 text-crema">Todos los dispositivos</option>
          <option value="LEADERS" className="bg-gray-900 text-crema">Líderes de Célula</option>
          <option value="MEMBERS" className="bg-gray-900 text-crema">Miembros Registrados</option>
          <option value="USER" className="bg-gray-900 text-crema">Usuario Específico (Por Persona)</option>
        </select>
      </div>

      {/* Main Table */}
      <div className="glass-panel border border-white border-opacity-5 rounded-2xl overflow-hidden bg-dark-teal bg-opacity-20">
        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-20 text-crema text-opacity-50">
            <div className="animate-spin w-8 h-8 border-4 border-dorado border-t-transparent rounded-full mb-3" />
            Cargando historial de notificaciones...
          </div>
        ) : isError ? (
          <div className="flex items-center justify-center gap-2 py-20 text-error-red">
            <Info className="w-5 h-5" />
            Error al cargar el historial. Intenta de nuevo.
          </div>
        ) : results.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-crema text-opacity-40 italic">
            <Bell className="w-12 h-12 mb-3 opacity-20" />
            <p>No se encontraron notificaciones</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm border-collapse">
              <thead>
                <tr className="border-b border-white border-opacity-5 bg-deep-teal bg-opacity-40 text-crema text-opacity-50 text-[11px] font-bold uppercase tracking-wider">
                  <th className="px-6 py-4">Notificación</th>
                  <th className="px-6 py-4">Remitente</th>
                  <th className="px-6 py-4">Audiencia</th>
                  <th className="px-6 py-4 text-center">Estado</th>
                  <th className="px-6 py-4">Fecha Programada / Envío</th>
                  <th className="px-6 py-4 text-center">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white divide-opacity-5">
                {results.map((item) => {
                  const cfg = NOTIFICATION_STATUS_CONFIG[item.status];
                  const displayDate = item.sent_at || item.scheduled_for;
                  const formattedDate = displayDate
                    ? new Date(displayDate).toLocaleString('es-PE', {
                        day: '2-digit',
                        month: 'short',
                        hour: '2-digit',
                        minute: '2-digit'
                      })
                    : 'Inmediata';

                  return (
                    <tr
                      key={item.id}
                      onClick={() => setSelectedItem(item)}
                      className="hover:bg-white hover:bg-opacity-5 transition-colors cursor-pointer group"
                    >
                      <td className="px-6 py-4 max-w-[280px]">
                        <div className="font-bold text-white group-hover:text-dorado transition-colors line-clamp-1">
                          {item.title}
                        </div>
                        <div className="text-xs text-crema text-opacity-65 line-clamp-1 mt-0.5">
                          {item.body}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-white font-medium">
                          {item.sender?.full_name || 'Sistema'}
                        </div>
                        <div className="text-[10px] text-crema text-opacity-50 mt-0.5">
                          {item.sender?.email}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="inline-flex items-center px-2 py-0.5 rounded-lg text-xs font-semibold bg-teal-900 bg-opacity-30 text-teal-300 border border-teal-800 border-opacity-35">
                          {item.target_audience === 'USER' && item.target_user_detail
                            ? `Para: ${item.target_user_detail.full_name || item.target_user_detail.email}`
                            : TARGET_AUDIENCE_LABELS[item.target_audience]}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-center">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${cfg.classes}`}>
                          {cfg.label}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-xs text-crema text-opacity-80 flex items-center gap-1.5">
                          {item.scheduled_for ? (
                            <Clock className="w-3.5 h-3.5 text-yellow-500" />
                          ) : (
                            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                          )}
                          {formattedDate}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-right" onClick={(e) => e.stopPropagation()}>
                        <div className="flex items-center justify-end gap-1.5 whitespace-nowrap">
                          <button
                            id={`view-btn-${item.id}`}
                            onClick={() => setSelectedItem(item)}
                            className="p-2 bg-white/5 hover:bg-dorado/20 text-crema hover:text-dorado border border-white/10 rounded-xl transition-all flex items-center gap-1.5 text-xs font-semibold"
                            title="Ver Detalle"
                          >
                            <Eye className="w-3.5 h-3.5" />
                            <span>Ver</span>
                          </button>
                          {item.status !== 'SENT' && (
                            <button
                              id={`send-btn-${item.id}`}
                              disabled={sendMutation.isPending}
                              onClick={() => sendMutation.mutate(item.id)}
                              className="p-2 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 rounded-xl transition-all flex items-center gap-1.5 text-xs font-semibold"
                              title="Enviar Ahora"
                            >
                              <Send className="w-3.5 h-3.5" />
                              <span>Enviar</span>
                            </button>
                          )}
                          <button
                            id={`delete-btn-${item.id}`}
                            onClick={() => handleDelete(item)}
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

        {/* Pagination Footer */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-6 py-4 border-t border-white border-opacity-5 bg-deep-teal bg-opacity-40">
            <p className="text-xs text-crema text-opacity-50">
              Página <span className="text-white font-semibold">{page}</span> de <span className="text-white font-semibold">{totalPages}</span>
            </p>
            <div className="flex items-center gap-2">
              <button
                id="notifications-prev"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-2 text-crema hover:text-white disabled:opacity-25 transition-all"
              >
                <ArrowLeft className="w-4 h-4" />
              </button>
              <button
                id="notifications-next"
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
    </div>
  );
};

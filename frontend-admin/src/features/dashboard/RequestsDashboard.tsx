import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { HeartHandshake, UserPlus, Clock, CheckCircle2, Loader2, ArrowUpRight } from 'lucide-react';
import { apiClient } from '../../api/client';

/**
 * Tablero de Soporte y Consejería.
 *
 * Su trabajo entero son las solicitudes, así que entra viendo cuántas le
 * esperan y cuáles son las últimas. Antes aterrizaba en el tablero de la
 * iglesia, cuyas cifras exigen permisos de reportes que este rol no tiene:
 * veía un título de bienvenida y una caja vacía, porque hasta el bloque de
 * solicitudes sacaba sus datos del informe general que el servidor le niega.
 */

interface PagedResponse<T> {
  count: number;
  results: T[];
}

interface PrayerRequest {
  id: number;
  requester_name: string;
  subject: string;
  is_anonymous: boolean;
  status: string;
  created_at: string;
}

interface VisitorRequest {
  id: number;
  full_name: string;
  message: string;
  status: string;
  created_at: string;
}

/** Consulta un listado acotado por estado. Sólo interesan el total y los primeros. */
function useRequests<T>(resource: string, status: string) {
  return useQuery<PagedResponse<T>>({
    queryKey: [resource, status],
    queryFn: async () => (await apiClient.get(`/${resource}/`, { params: { status } })).data,
  });
}

export const RequestsDashboard: React.FC = () => {
  const oracionesPendientes = useRequests<PrayerRequest>('prayer-requests', 'PENDING');
  const oracionesEnProceso = useRequests<PrayerRequest>('prayer-requests', 'IN_PROGRESS');
  const visitasPendientes = useRequests<VisitorRequest>('visitor-requests', 'PENDING');
  const visitasEnProceso = useRequests<VisitorRequest>('visitor-requests', 'IN_PROGRESS');

  const cargando =
    oracionesPendientes.isLoading ||
    visitasPendientes.isLoading ||
    oracionesEnProceso.isLoading ||
    visitasEnProceso.isLoading;

  const porAtender =
    (oracionesPendientes.data?.count ?? 0) + (visitasPendientes.data?.count ?? 0);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-extrabold text-crema leading-none">Consejería y Soporte</h1>
        <p className="text-xs text-crema text-opacity-50 mt-1.5">
          {cargando
            ? 'Revisando lo que hay pendiente…'
            : porAtender === 0
              ? 'No hay solicitudes esperando. Todo al día.'
              : `Hay ${porAtender} solicitud(es) esperando respuesta.`}
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="Oraciones pendientes"
          value={oracionesPendientes.data?.count}
          loading={oracionesPendientes.isLoading}
          icon={HeartHandshake}
          tone="text-dorado"
        />
        <StatCard
          label="Visitas pendientes"
          value={visitasPendientes.data?.count}
          loading={visitasPendientes.isLoading}
          icon={UserPlus}
          tone="text-teal-400"
        />
        <StatCard
          label="Oraciones en proceso"
          value={oracionesEnProceso.data?.count}
          loading={oracionesEnProceso.isLoading}
          icon={Clock}
          tone="text-blue-400"
        />
        <StatCard
          label="Visitas en proceso"
          value={visitasEnProceso.data?.count}
          loading={visitasEnProceso.isLoading}
          icon={CheckCircle2}
          tone="text-emerald-400"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <RequestPanel
          title="Peticiones de oración"
          to="/solicitudes/oraciones"
          loading={oracionesPendientes.isLoading}
          empty="Ninguna petición esperando."
          items={(oracionesPendientes.data?.results ?? []).slice(0, 5).map((r) => ({
            id: r.id,
            // Una petición anónima se respeta como tal también aquí.
            title: r.is_anonymous ? 'Anónimo' : r.requester_name,
            detail: r.subject,
            date: r.created_at,
          }))}
        />
        <RequestPanel
          title="Quiero conocer la iglesia"
          to="/solicitudes/visitas"
          loading={visitasPendientes.isLoading}
          empty="Ninguna visita esperando."
          items={(visitasPendientes.data?.results ?? []).slice(0, 5).map((r) => ({
            id: r.id,
            title: r.full_name,
            detail: r.message,
            date: r.created_at,
          }))}
        />
      </div>
    </div>
  );
};

function StatCard({
  label,
  value,
  loading,
  icon: Icon,
  tone,
}: {
  label: string;
  value?: number;
  loading: boolean;
  icon: typeof HeartHandshake;
  tone: string;
}) {
  return (
    <div className="glass-panel p-5 bg-dark-teal bg-opacity-20">
      <div className="flex items-center justify-between">
        <span className="text-[11px] font-semibold text-crema text-opacity-50 uppercase tracking-wider">
          {label}
        </span>
        <div className={`p-2 bg-deep-teal bg-opacity-50 border border-white border-opacity-5 rounded-lg ${tone}`}>
          <Icon size={16} />
        </div>
      </div>
      <div className="mt-3">
        {loading ? (
          <Loader2 className="animate-spin text-dorado my-1" size={20} />
        ) : (
          <span className="text-2xl font-extrabold text-crema leading-none">{value ?? 0}</span>
        )}
      </div>
    </div>
  );
}

interface PanelItem {
  id: number;
  title: string;
  detail: string;
  date: string;
}

function RequestPanel({
  title,
  to,
  items,
  loading,
  empty,
}: {
  title: string;
  to: string;
  items: PanelItem[];
  loading: boolean;
  empty: string;
}) {
  return (
    <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-bold text-crema leading-none">{title}</h3>
        <Link to={to} className="text-[10px] text-dorado hover:underline flex items-center gap-1">
          Ver todas <ArrowUpRight size={11} />
        </Link>
      </div>

      {loading ? (
        <div className="flex items-center justify-center p-6 text-crema/40 text-xs">
          <Loader2 className="animate-spin mr-2" size={16} /> Cargando…
        </div>
      ) : items.length === 0 ? (
        <p className="text-xs text-crema text-opacity-40 p-4 text-center">{empty}</p>
      ) : (
        <div className="space-y-3">
          {items.map((item) => (
            <Link
              key={item.id}
              to={to}
              className="flex items-start justify-between gap-3 p-3 bg-deep-teal bg-opacity-40 border border-white border-opacity-5 rounded-xl text-xs hover:bg-opacity-60 transition-all"
            >
              <div className="flex flex-col min-w-0">
                <span className="font-bold truncate">{item.title}</span>
                <span className="text-[10px] text-crema text-opacity-50 mt-1 line-clamp-2">
                  {item.detail}
                </span>
              </div>
              <span className="text-[9px] text-crema text-opacity-40 shrink-0">
                {new Date(item.date).toLocaleDateString('es-PE')}
              </span>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

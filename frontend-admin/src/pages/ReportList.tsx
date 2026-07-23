import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  FileSpreadsheet, Download, RefreshCw,
  Activity, Map, Calendar, CheckCircle2, AlertCircle
} from 'lucide-react';
import { apiClient } from '../api/client';
import { ReportSummary } from '../features/reports/types';

export const ReportList: React.FC = () => {
  const [downloadingType, setDownloadingType] = useState<string | null>(null);

  // Fetch summary metrics
  const { data: summary, isLoading, isError, refetch, isRefetching } = useQuery<ReportSummary>({
    queryKey: ['reports-summary'],
    queryFn: async () => {
      const res = await apiClient.get('/reports/summary/');
      return res.data;
    },
  });

  // Secure CSV downloader using API client
  const handleDownload = async (type: string) => {
    setDownloadingType(type);
    try {
      const response = await apiClient.get(`/reports/export/?type=${type}`, {
        responseType: 'blob',
      });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `reporte_${type}_${new Date().toISOString().slice(0,10)}.csv`);
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (err) {
      alert('Error de red al exportar el archivo CSV.');
    } finally {
      setDownloadingType(null);
    }
  };

  const cellPercentage = summary && summary.cells.total > 0
    ? Math.round((summary.cells.active / summary.cells.total) * 100)
    : 0;

  const prayerResolvedPercent = summary && summary.requests.prayer.total > 0
    ? Math.round((summary.requests.prayer.resolved / summary.requests.prayer.total) * 100)
    : 0;

  const visitorResolvedPercent = summary && summary.requests.visitor.total > 0
    ? Math.round((summary.requests.visitor.resolved / summary.requests.visitor.total) * 100)
    : 0;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <FileSpreadsheet className="w-6 h-6 text-dorado" />
            Reportes y Analíticas
          </h1>
          <p className="text-sm text-crema text-opacity-50 mt-1">
            Visualización estadística de indicadores del ministerio y exportaciones a hojas de cálculo
          </p>
        </div>
        <button
          onClick={() => refetch()}
          disabled={isLoading || isRefetching}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 text-white rounded-xl text-xs font-semibold hover:border-dorado transition-all disabled:opacity-40"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${isRefetching ? 'animate-spin' : ''}`} />
          Actualizar Datos
        </button>
      </div>

      {isLoading ? (
        <div className="flex flex-col items-center justify-center py-20 text-crema text-opacity-50">
          <div className="animate-spin w-8 h-8 border-4 border-dorado border-t-transparent rounded-full mb-3" />
          Procesando estadísticas consolidadas...
        </div>
      ) : isError || !summary ? (
        <div className="flex items-center justify-center gap-2 py-20 text-error-red">
          <AlertCircle className="w-5 h-5" />
          Error al cargar los reportes. Intenta de nuevo.
        </div>
      ) : (
        <div className="space-y-8">
          {/* Summary Cards Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* Cell groups metrics */}
            <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-dorado uppercase tracking-wider">Células de Conexión</span>
                <Map className="w-5 h-5 text-teal-400" />
              </div>
              <div className="space-y-1">
                <p className="text-3xl font-extrabold text-white">{summary.cells.total}</p>
                <p className="text-xs text-crema text-opacity-50">Grupos de células registrados</p>
              </div>
              <div className="space-y-1.5 pt-2">
                <div className="flex items-center justify-between text-xs text-crema/70">
                  <span>Células Activas ({summary.cells.active})</span>
                  <span>{cellPercentage}%</span>
                </div>
                <div className="w-full bg-deep-teal/40 h-2 rounded-full overflow-hidden">
                  <div className="bg-emerald-500 h-full rounded-full transition-all" style={{ width: `${cellPercentage}%` }} />
                </div>
              </div>
            </div>

            {/* Events metrics */}
            <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-dorado uppercase tracking-wider">Eventos y Registros</span>
                <Calendar className="w-5 h-5 text-amber-400" />
              </div>
              <div className="space-y-1">
                <p className="text-3xl font-extrabold text-white">{summary.events.registrations}</p>
                <p className="text-xs text-crema text-opacity-50">Miembros registrados a eventos</p>
              </div>
              <div className="flex items-center justify-between pt-2 text-xs text-crema/70">
                <span>Eventos Totales Organizados</span>
                <span className="font-bold text-white">{summary.events.total}</span>
              </div>
            </div>

            {/* Notifications metrics */}
            <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-dorado uppercase tracking-wider">Push / Dispositivos</span>
                <Activity className="w-5 h-5 text-violet-400" />
              </div>
              <div className="space-y-1">
                <p className="text-3xl font-extrabold text-white">{summary.notifications.devices}</p>
                <p className="text-xs text-crema text-opacity-50">Dispositivos móviles enlazados</p>
              </div>
              <div className="flex items-center justify-between pt-2 text-xs text-crema/70">
                <span>Notificaciones Push Enviadas</span>
                <span className="font-bold text-white">{summary.notifications.sent}</span>
              </div>
            </div>
          </div>

          {/* Detailed Request status & User breakdown */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Requests Metrics */}
            <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl space-y-6">
              <h3 className="text-sm font-bold text-white border-b border-white/5 pb-2">
                Atención a Oraciones y Visitas
              </h3>

              <div className="space-y-5">
                {/* Prayer requests progress */}
                <div className="space-y-2">
                  <div className="flex items-center justify-between text-xs text-crema">
                    <span className="font-bold">Oraciones Respondidas ({summary.requests.prayer.resolved} de {summary.requests.prayer.total})</span>
                    <span>{prayerResolvedPercent}%</span>
                  </div>
                  <div className="w-full bg-deep-teal/40 h-2.5 rounded-full overflow-hidden">
                    <div className="bg-teal-500 h-full rounded-full transition-all" style={{ width: `${prayerResolvedPercent}%` }} />
                  </div>
                  <div className="grid grid-cols-2 gap-2 text-[10px] text-crema/50">
                    <div>Pendientes: <span className="text-yellow-500 font-semibold">{summary.requests.prayer.pending}</span></div>
                    <div>En Progreso: <span className="text-violet-400 font-semibold">{summary.requests.prayer.in_progress}</span></div>
                  </div>
                </div>

                {/* Visitor requests progress */}
                <div className="space-y-2">
                  <div className="flex items-center justify-between text-xs text-crema">
                    <span className="font-bold">Visitas Atendidas ({summary.requests.visitor.resolved} de {summary.requests.visitor.total})</span>
                    <span>{visitorResolvedPercent}%</span>
                  </div>
                  <div className="w-full bg-deep-teal/40 h-2.5 rounded-full overflow-hidden">
                    <div className="bg-amber-500 h-full rounded-full transition-all" style={{ width: `${visitorResolvedPercent}%` }} />
                  </div>
                  <div className="grid grid-cols-2 gap-2 text-[10px] text-crema/50">
                    <div>Pendientes: <span className="text-yellow-500 font-semibold">{summary.requests.visitor.pending}</span></div>
                    <div>En Progreso: <span className="text-violet-400 font-semibold">{summary.requests.visitor.in_progress}</span></div>
                  </div>
                </div>
              </div>
            </div>

            {/* Users status distribution */}
            <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl space-y-6">
              <h3 className="text-sm font-bold text-white border-b border-white/5 pb-2">
                Distribución de Usuarios
              </h3>

              <div className="space-y-4">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-crema">Miembros Activos</span>
                  <span className="font-bold text-white">{summary.users.active}</span>
                </div>
                <div className="w-full bg-emerald-500/10 border border-emerald-500/20 p-3 rounded-xl flex items-center justify-between text-xs text-emerald-400">
                  <span className="font-medium flex items-center gap-1.5"><CheckCircle2 className="w-4 h-4" /> Cuentas Activas</span>
                  <span>{summary.users.active} / {summary.users.total}</span>
                </div>

                <div className="flex justify-between items-center gap-4 text-xs pt-2">
                  <div className="flex-1 bg-red-950/20 border border-red-900/30 p-3 rounded-xl flex flex-col items-center">
                    <span className="text-crema text-opacity-50 text-[10px]">BLOQUEADOS</span>
                    <span className="text-red-400 font-extrabold text-base mt-1">{summary.users.blocked}</span>
                  </div>
                  <div className="flex-1 bg-gray-800/30 border border-white/5 p-3 rounded-xl flex flex-col items-center">
                    <span className="text-crema text-opacity-50 text-[10px]">INACTIVOS</span>
                    <span className="text-crema font-extrabold text-base mt-1">{summary.users.inactive}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* CSV Export Center */}
          <div className="space-y-4">
            <h3 className="text-sm font-bold text-white border-b border-white/5 pb-2 flex items-center gap-2">
              <FileSpreadsheet className="w-4 h-4 text-dorado" />
              Centro de Exportaciones CSV
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Cells CSV Card */}
              <div className="glass-panel p-5 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl flex flex-col justify-between space-y-4">
                <div className="space-y-1">
                  <p className="text-xs font-bold text-dorado uppercase tracking-wider">Reporte de Células</p>
                  <p className="text-[10px] text-crema text-opacity-50 leading-normal">
                    Exporta la lista de grupos celulares, líderes asignados, horarios y coordenadas geográficas.
                  </p>
                </div>
                <button
                  id="export-cells-btn"
                  disabled={downloadingType === 'cells'}
                  onClick={() => handleDownload('cells')}
                  className="w-full py-2 bg-teal-600 hover:bg-teal-500 disabled:opacity-50 text-white rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 shadow"
                >
                  {downloadingType === 'cells' ? (
                    <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <Download className="w-3.5 h-3.5" />
                  )}
                  Descargar CSV
                </button>
              </div>

              {/* Requests CSV Card */}
              <div className="glass-panel p-5 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl flex flex-col justify-between space-y-4">
                <div className="space-y-1">
                  <p className="text-xs font-bold text-dorado uppercase tracking-wider">Bitácora de Solicitudes</p>
                  <p className="text-[10px] text-crema text-opacity-50 leading-normal">
                    Exporta la bitácora unificada de oraciones y visitas de consejería, sus estados y sus responsables.
                  </p>
                </div>
                <button
                  id="export-requests-btn"
                  disabled={downloadingType === 'requests'}
                  onClick={() => handleDownload('requests')}
                  className="w-full py-2 bg-teal-600 hover:bg-teal-500 disabled:opacity-50 text-white rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 shadow"
                >
                  {downloadingType === 'requests' ? (
                    <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <Download className="w-3.5 h-3.5" />
                  )}
                  Descargar CSV
                </button>
              </div>

              {/* Users CSV Card */}
              <div className="glass-panel p-5 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl flex flex-col justify-between space-y-4">
                <div className="space-y-1">
                  <p className="text-xs font-bold text-dorado uppercase tracking-wider">Directorio de Usuarios</p>
                  <p className="text-[10px] text-crema text-opacity-50 leading-normal">
                    Exporta el directorio administrativo con cuentas, correos, privilegios y fecha de registro.
                  </p>
                </div>
                <button
                  id="export-users-btn"
                  disabled={downloadingType === 'users'}
                  onClick={() => handleDownload('users')}
                  className="w-full py-2 bg-teal-600 hover:bg-teal-500 disabled:opacity-50 text-white rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 shadow"
                >
                  {downloadingType === 'users' ? (
                    <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <Download className="w-3.5 h-3.5" />
                  )}
                  Descargar CSV
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

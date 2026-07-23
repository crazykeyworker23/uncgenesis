import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { 
  FileText, 
  Video, 
  Users, 
  MessageSquare, 
  Plus, 
  Send, 
  BookOpen, 
  TrendingUp,
  ArrowUpRight,
  Sparkles,
  Loader2
} from 'lucide-react';
import { 
  ResponsiveContainer, 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  Tooltip, 
  CartesianGrid,
  BarChart,
  Bar
} from 'recharts';
import { apiClient } from '../api/client';

interface DashboardData {
  kpis: {
    active_publications: number;
    recorded_services: number;
    total_users: number;
    pending_requests: number;
    urgent_requests: number;
  };
  content_distribution: Array<{ name: string; count: number }>;
  activity_data: Array<{ name: string; visitas: number; registros: number }>;
  recent_requests: Array<{
    id: string;
    type: string;
    description: string;
    status: string;
    created_at: string;
  }>;
}

export const Dashboard: React.FC = () => {
  const { data, isLoading } = useQuery<DashboardData>({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const res = await apiClient.get('/reports/dashboard/');
      return res.data;
    },
  });

  const stats = [
    { name: 'Publicaciones Activas', value: data?.kpis?.active_publications ?? 0, change: 'En plataforma', icon: FileText, color: 'text-dorado' },
    { name: 'Servicios Grabados', value: data?.kpis?.recorded_services ?? 0, change: 'Prédicas publicadas', icon: Video, color: 'text-teal-400' },
    { name: 'Usuarios Totales', value: data?.kpis?.total_users ?? 0, change: 'Registrados', icon: Users, color: 'text-blue-400' },
    { name: 'Solicitudes Pendientes', value: data?.kpis?.pending_requests ?? 0, change: `${data?.kpis?.urgent_requests ?? 0} oraciones`, icon: MessageSquare, color: 'text-error-red' },
  ];

  const quickActions = [
    { title: 'Nueva Publicación', desc: 'Redactar noticia, artículo o boletín', icon: Plus, color: 'bg-dorado text-deep-teal', link: '/publicaciones/nueva' },
    { title: 'Programar Notificación', desc: 'Enviar push global o a grupo', icon: Send, color: 'bg-teal-500 text-deep-teal', link: '/notificaciones' },
    { title: 'Crear Devocional', desc: 'Agregar estudio diario o audio', icon: BookOpen, color: 'bg-blue-500 text-crema', link: '/devocionales/nuevo' },
    { title: 'Nuevo Servicio', desc: 'Publicar prédica, audios y versos', icon: Sparkles, color: 'bg-purple-500 text-crema', link: '/servicios/nuevo' },
  ];

  const activityChartData = data?.activity_data?.length ? data.activity_data : [
    { name: 'Ene', visitas: 0, registros: 0 },
    { name: 'Feb', visitas: 0, registros: 0 },
  ];

  const contentChartData = data?.content_distribution?.length ? data.content_distribution : [
    { name: 'Prédicas', count: 0 },
    { name: 'Devocionales', count: 0 },
    { name: 'Noticias', count: 0 },
    { name: 'Eventos', count: 0 },
  ];

  return (
    <div className="space-y-6">
      {/* Welcome Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-crema leading-none">Bienvenido al Centro de Control</h1>
          <p className="text-xs text-crema text-opacity-50 mt-1.5">Monitorea y administra la actividad, contenido y solicitudes de Génesis.</p>
        </div>
        <div className="flex items-center gap-2 text-xs bg-dark-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl p-2 px-3 self-start">
          <TrendingUp size={16} className="text-dorado" />
          <span className="font-semibold text-dorado">Base de Datos Conectada</span>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.name} className="glass-panel p-5 bg-dark-teal bg-opacity-20 hover:bg-opacity-30 transition-all duration-300">
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-semibold text-crema text-opacity-50 uppercase tracking-wider">{stat.name}</span>
                <div className={`p-2 bg-deep-teal bg-opacity-50 border border-white border-opacity-5 rounded-lg ${stat.color}`}>
                  <Icon size={16} />
                </div>
              </div>
              <div className="mt-3 flex items-baseline gap-2">
                {isLoading ? (
                  <Loader2 className="animate-spin text-dorado my-1" size={20} />
                ) : (
                  <span className="text-2xl font-extrabold text-crema leading-none">{stat.value}</span>
                )}
                <span className="text-[10px] text-dorado font-medium">{stat.change}</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Charts section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Activity Chart */}
        <div className="glass-panel p-5 lg:col-span-2 bg-dark-teal bg-opacity-20 flex flex-col h-[320px]">
          <div className="flex items-center justify-between mb-4">
            <span className="text-sm font-bold text-crema">Actividad General (Registros y Solicitudes)</span>
            <span className="text-[10px] text-crema text-opacity-40 flex items-center gap-1">
              Últimos meses <ArrowUpRight size={12} />
            </span>
          </div>
          <div className="flex-1 w-full text-xs">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={activityChartData}>
                <defs>
                  <linearGradient id="colorVisitas" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#D4AF37" stopOpacity={0.4}/>
                    <stop offset="95%" stopColor="#D4AF37" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="colorRegistros" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#22C55E" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#22C55E" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis dataKey="name" stroke="rgba(248, 241, 228, 0.4)" />
                <YAxis stroke="rgba(248, 241, 228, 0.4)" />
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: '#043B3B', 
                    borderColor: 'rgba(255,255,255,0.1)', 
                    borderRadius: '12px',
                    color: '#F8F1E4' 
                  }} 
                />
                <Area type="monotone" dataKey="visitas" stroke="#D4AF37" strokeWidth={2} fillOpacity={1} fill="url(#colorVisitas)" />
                <Area type="monotone" dataKey="registros" stroke="#22C55E" strokeWidth={2} fillOpacity={1} fill="url(#colorRegistros)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Section Stats Chart */}
        <div className="glass-panel p-5 bg-dark-teal bg-opacity-20 flex flex-col h-[320px]">
          <div className="flex items-center justify-between mb-4">
            <span className="text-sm font-bold text-crema">Distribución de Contenido Real</span>
          </div>
          <div className="flex-1 w-full text-xs">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={contentChartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis dataKey="name" stroke="rgba(248, 241, 228, 0.4)" />
                <YAxis stroke="rgba(248, 241, 228, 0.4)" />
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: '#043B3B', 
                    borderColor: 'rgba(255,255,255,0.1)', 
                    borderRadius: '12px',
                    color: '#F8F1E4' 
                  }} 
                />
                <Bar dataKey="count" fill="#D4AF37" radius={[6, 6, 0, 0]} barSize={36} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Quick Actions & Recent updates */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Quick Actions List */}
        <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 space-y-4">
          <h3 className="text-sm font-bold text-crema leading-none">Acciones Rápidas</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {quickActions.map((action) => {
              const Icon = action.icon;
              return (
                <Link 
                  key={action.title}
                  to={action.link}
                  className="flex items-start gap-3 p-3.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-5 rounded-xl hover:border-dorado/30 hover:scale-[1.01] transition-all text-left group focus:outline-none"
                >
                  <div className={`p-2 rounded-lg shrink-0 ${action.color}`}>
                    <Icon size={16} />
                  </div>
                  <div>
                    <h4 className="text-xs font-bold group-hover:text-dorado transition-colors">{action.title}</h4>
                    <p className="text-[10px] text-crema text-opacity-50 mt-1">{action.desc}</p>
                  </div>
                </Link>
              );
            })}
          </div>
        </div>

        {/* Recent Prayer/Visitor Requests */}
        <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-crema leading-none">Solicitudes Recientes</h3>
            <Link to="/solicitudes" className="text-[10px] text-dorado hover:underline cursor-pointer">Ver todas</Link>
          </div>
          <div className="space-y-3">
            {isLoading ? (
              <div className="flex items-center justify-center p-6 text-crema/40 text-xs">
                <Loader2 className="animate-spin mr-2" size={16} /> Cargando solicitudes...
              </div>
            ) : data?.recent_requests?.length ? (
              data.recent_requests.map((req) => (
                <div key={req.id} className="flex items-center justify-between p-3 bg-deep-teal bg-opacity-40 border border-white border-opacity-5 rounded-xl text-xs">
                  <div className="flex flex-col">
                    <span className="font-bold">{req.type}</span>
                    <span className="text-[10px] text-crema text-opacity-50 mt-1">{req.description}</span>
                  </div>
                  <span className={`px-2 py-0.5 rounded-full text-[9px] font-semibold ${
                    req.status === 'NUEVO' || req.status === 'PENDING'
                      ? 'bg-dorado bg-opacity-10 text-dorado'
                      : 'bg-teal-500 bg-opacity-10 text-teal-300'
                  }`}>
                    {req.status}
                  </span>
                </div>
              ))
            ) : (
              <div className="text-center p-4 text-xs text-crema text-opacity-40">
                No hay solicitudes recientes registradas.
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

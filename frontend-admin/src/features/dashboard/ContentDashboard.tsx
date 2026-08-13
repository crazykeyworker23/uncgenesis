import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { BookOpen, MessageSquare, Calendar, FileText, Plus, Loader2, ArrowUpRight } from 'lucide-react';
import { apiClient } from '../../api/client';
import { usePermissions } from '../../store/authStore';

/**
 * Tablero del Editor de Contenidos.
 *
 * Lo suyo es publicar, así que entra viendo lo que tiene a medias: cuántos
 * borradores le esperan en cada sección y cuáles son los últimos, con su
 * enlace para seguir. Antes aterrizaba en el tablero de la iglesia, cuyas
 * cifras exigen permisos de reportes que no tiene: veía un encabezado y tres
 * botones, sin un solo dato.
 */

interface PagedResponse<T> {
  count: number;
  results: T[];
}

interface ContentItem {
  id: number;
  title: string;
  updated_at?: string;
  created_at?: string;
}

/** Borradores de una sección. Sólo interesan el total y los primeros. */
function useDrafts(resource: string, enabled: boolean) {
  return useQuery<PagedResponse<ContentItem>>({
    queryKey: [resource, 'DRAFT'],
    queryFn: async () =>
      (await apiClient.get(`/${resource}/`, { params: { status: 'DRAFT' } })).data,
    enabled,
  });
}

export const ContentDashboard: React.FC = () => {
  const { can } = usePermissions();

  // Cada sección se consulta sólo si el rol puede verla: así este tablero
  // sirve igual si mañana se recorta o se amplía lo que el editor gestiona.
  const publicaciones = useDrafts('publications', can('PUBLICATIONS_VIEW'));
  const devocionales = useDrafts('devotionals', can('DEVOTIONALS_VIEW'));
  const servicios = useDrafts('services', can('SERVICES_VIEW'));
  const eventos = useDrafts('events', can('EVENTS_VIEW'));

  const secciones = [
    {
      label: 'Publicaciones',
      query: publicaciones,
      icon: FileText,
      tone: 'text-dorado',
      path: '/publicaciones',
      visible: can('PUBLICATIONS_VIEW'),
    },
    {
      label: 'Devocionales',
      query: devocionales,
      icon: BookOpen,
      tone: 'text-blue-400',
      path: '/devocionales',
      visible: can('DEVOTIONALS_VIEW'),
    },
    {
      label: 'Servicios',
      query: servicios,
      icon: MessageSquare,
      tone: 'text-teal-400',
      path: '/servicios',
      visible: can('SERVICES_VIEW'),
    },
    {
      label: 'Eventos',
      query: eventos,
      icon: Calendar,
      tone: 'text-purple-400',
      path: '/eventos',
      visible: can('EVENTS_VIEW'),
    },
  ].filter((s) => s.visible);

  const cargando = secciones.some((s) => s.query.isLoading);
  const pendientes = secciones.reduce((total, s) => total + (s.query.data?.count ?? 0), 0);

  const atajos = [
    { label: 'Nueva publicación', to: '/publicaciones/nueva', permission: 'PUBLICATIONS_CREATE' },
    { label: 'Nuevo devocional', to: '/devocionales/nuevo', permission: 'DEVOTIONALS_CREATE' },
    { label: 'Nuevo servicio', to: '/servicios/nuevo', permission: 'SERVICES_CREATE' },
    { label: 'Nuevo evento', to: '/eventos/nuevo', permission: 'EVENTS_CREATE' },
  ].filter((a) => can(a.permission));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-extrabold text-crema leading-none">Contenido</h1>
        <p className="text-xs text-crema text-opacity-50 mt-1.5">
          {cargando
            ? 'Buscando lo que tienes a medias…'
            : pendientes === 0
              ? 'No tienes borradores pendientes. Todo publicado.'
              : `Tienes ${pendientes} borrador(es) sin publicar.`}
        </p>
      </div>

      {secciones.length > 0 && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {secciones.map(({ label, query, icon: Icon, tone, path }) => (
            <Link
              key={label}
              to={path}
              className="glass-panel p-5 bg-dark-teal bg-opacity-20 hover:bg-opacity-30 transition-all"
            >
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-semibold text-crema text-opacity-50 uppercase tracking-wider">
                  {label}
                </span>
                <div className={`p-2 bg-deep-teal bg-opacity-50 border border-white border-opacity-5 rounded-lg ${tone}`}>
                  <Icon size={16} />
                </div>
              </div>
              <div className="mt-3 flex items-baseline gap-2">
                {query.isLoading ? (
                  <Loader2 className="animate-spin text-dorado my-1" size={20} />
                ) : (
                  <span className="text-2xl font-extrabold text-crema leading-none">
                    {query.data?.count ?? 0}
                  </span>
                )}
                <span className="text-[10px] text-dorado font-medium">en borrador</span>
              </div>
            </Link>
          ))}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <DraftList
            loading={publicaciones.isLoading}
            items={(publicaciones.data?.results ?? []).slice(0, 6)}
            // Sin permiso de edición el borrador lleva al listado, no al
            // formulario: un enlace que acaba en «sección no disponible» es
            // peor que no ofrecerlo.
            canEdit={can(['PUBLICATIONS_CREATE', 'PUBLICATIONS_EDIT'])}
          />
        </div>

        {atajos.length > 0 && (
          <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 space-y-3">
            <h3 className="text-sm font-bold text-crema leading-none mb-4">Crear</h3>
            {atajos.map((atajo) => (
              <Link
                key={atajo.to}
                to={atajo.to}
                className="flex items-center gap-3 p-3 bg-deep-teal bg-opacity-40 border border-white border-opacity-5 rounded-xl text-xs hover:bg-opacity-60 transition-all"
              >
                <div className="p-1.5 rounded-lg bg-dorado bg-opacity-15 text-dorado">
                  <Plus size={13} />
                </div>
                <span className="font-semibold">{atajo.label}</span>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

function DraftList({
  items,
  loading,
  canEdit,
}: {
  items: ContentItem[];
  loading: boolean;
  canEdit: boolean;
}) {
  return (
    <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 space-y-4 h-full">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-bold text-crema leading-none">Publicaciones sin publicar</h3>
        <Link
          to="/publicaciones"
          className="text-[10px] text-dorado hover:underline flex items-center gap-1"
        >
          Ver todas <ArrowUpRight size={11} />
        </Link>
      </div>

      {loading ? (
        <div className="flex items-center justify-center p-6 text-crema/40 text-xs">
          <Loader2 className="animate-spin mr-2" size={16} /> Cargando…
        </div>
      ) : items.length === 0 ? (
        <p className="text-xs text-crema text-opacity-40 p-4 text-center">
          No tienes publicaciones en borrador.
        </p>
      ) : (
        <div className="space-y-2">
          {items.map((item) => (
            <Link
              key={item.id}
              to={canEdit ? `/publicaciones/${item.id}/editar` : '/publicaciones'}
              className="flex items-center justify-between gap-3 p-3 bg-deep-teal bg-opacity-40 border border-white border-opacity-5 rounded-xl text-xs hover:bg-opacity-60 transition-all"
            >
              <span className="font-semibold truncate">{item.title}</span>
              <span className="text-[9px] text-crema text-opacity-40 shrink-0">
                {item.updated_at ? new Date(item.updated_at).toLocaleDateString('es-PE') : ''}
              </span>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

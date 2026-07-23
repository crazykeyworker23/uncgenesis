import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  Users, Search, UserPlus, Edit,
  Lock, Unlock, ArrowLeft, ArrowRight, AlertCircle
} from 'lucide-react';
import { apiClient } from '../api/client';
import { User, PaginatedUsers, USER_STATUS_CONFIG } from '../features/users/types';
import { ROLE_LABELS, ROLE_BADGE_COLORS } from '../features/roles/types';

export const UserList: React.FC = () => {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [page, setPage] = useState(1);

  // Fetch paginated users
  const { data, isLoading, isError } = useQuery<PaginatedUsers>({
    queryKey: ['users', search, statusFilter, page],
    queryFn: async () => {
      const res = await apiClient.get('/users/', {
        params: {
          search: search || undefined,
          status: statusFilter || undefined,
          page,
        },
      });
      return res.data;
    },
  });

  // Block User Mutation
  const blockMutation = useMutation({
    mutationFn: async (id: number) => {
      const res = await apiClient.post(`/users/${id}/block/`);
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });

  // Unblock User Mutation
  const unblockMutation = useMutation({
    mutationFn: async (id: number) => {
      const res = await apiClient.post(`/users/${id}/unblock/`);
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });

  const handleToggleBlock = (item: User) => {
    if (item.status === 'BLOCKED') {
      unblockMutation.mutate(item.id);
    } else {
      if (window.confirm(`¿Seguro que deseas bloquear la cuenta de "${item.full_name}"?`)) {
        blockMutation.mutate(item.id);
      }
    }
  };

  const results = data?.results ?? [];
  const totalPages = data ? Math.ceil(data.count / 10) : 1;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <Users className="w-6 h-6 text-dorado" />
            Control de Usuarios
          </h1>
          <p className="text-sm text-crema text-opacity-50 mt-1">
            {data?.count ?? 0} cuentas registradas en total
          </p>
        </div>
        <Link
          to="/usuarios/nuevo"
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-teal-600 hover:bg-teal-500 text-white rounded-xl text-sm font-semibold transition-all shadow"
        >
          <UserPlus className="w-4 h-4" />
          Registrar Usuario
        </Link>
      </div>

      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-crema text-opacity-40" />
          <input
            id="users-search"
            type="text"
            placeholder="Buscar por nombre, correo electrónico o teléfono..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            className="w-full pl-10 pr-4 py-2.5 bg-deep-teal bg-opacity-30 border border-white border-opacity-10 text-white rounded-xl text-sm placeholder-crema placeholder-opacity-40 focus:outline-none focus:border-dorado transition-all"
          />
        </div>
        <select
          id="users-status-filter"
          value={statusFilter}
          onChange={(e) => {
            setStatusFilter(e.target.value);
            setPage(1);
          }}
          className="px-3 py-2.5 bg-deep-teal bg-opacity-30 border border-white border-opacity-10 text-crema rounded-xl text-sm focus:outline-none focus:border-dorado transition-all"
        >
          <option value="" className="bg-gray-900 text-crema">Todos los estados</option>
          <option value="ACTIVE" className="bg-gray-900 text-crema">Activos</option>
          <option value="INACTIVE" className="bg-gray-900 text-crema">Inactivos</option>
          <option value="BLOCKED" className="bg-gray-900 text-crema">Bloqueados</option>
        </select>
      </div>

      {/* Main Table */}
      <div className="glass-panel border border-white border-opacity-5 rounded-2xl overflow-hidden bg-dark-teal bg-opacity-20">
        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-20 text-crema text-opacity-50">
            <div className="animate-spin w-8 h-8 border-4 border-dorado border-t-transparent rounded-full mb-3" />
            Cargando cuentas de usuarios...
          </div>
        ) : isError ? (
          <div className="flex items-center justify-center gap-2 py-20 text-error-red">
            <AlertCircle className="w-5 h-5" />
            Error al cargar usuarios. Intenta de nuevo.
          </div>
        ) : results.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-crema text-opacity-40 italic">
            <Users className="w-12 h-12 mb-3 opacity-20" />
            <p>No se encontraron usuarios</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm border-collapse">
              <thead>
                <tr className="border-b border-white border-opacity-5 bg-deep-teal bg-opacity-40 text-crema text-opacity-50 text-[11px] font-bold uppercase tracking-wider">
                  <th className="px-6 py-4">Usuario</th>
                  <th className="px-6 py-4">Contacto</th>
                  <th className="px-6 py-4">Roles de Acceso</th>
                  <th className="px-6 py-4 text-center">Estado</th>
                  <th className="px-6 py-4">Miembro desde</th>
                  <th className="px-6 py-4 text-center">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white divide-opacity-5">
                {results.map((item) => {
                  const statusCfg = USER_STATUS_CONFIG[item.status] || USER_STATUS_CONFIG.ACTIVE;
                  const formattedDate = new Date(item.created_at).toLocaleDateString('es-PE', {
                    day: '2-digit',
                    month: 'short',
                    year: 'numeric'
                  });

                  return (
                    <tr
                      key={item.id}
                      className="hover:bg-white hover:bg-opacity-5 transition-colors group"
                    >
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          {item.avatar ? (
                            <img
                              src={item.avatar}
                              alt={item.full_name}
                              className="w-10 h-10 rounded-xl object-cover border border-white/10"
                            />
                          ) : (
                            <div className="w-10 h-10 rounded-xl bg-dorado/10 border border-dorado/20 flex items-center justify-center font-bold text-dorado">
                              {item.first_name[0]?.toUpperCase() || '?'}
                            </div>
                          )}
                          <div>
                            <div className="font-bold text-white group-hover:text-dorado transition-colors">
                              {item.full_name || `${item.first_name} ${item.last_name}`}
                            </div>
                            <div className="text-[10px] text-crema text-opacity-40 font-mono mt-0.5">
                              ID: {item.id}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-white font-medium">{item.email}</div>
                        <div className="text-xs text-crema text-opacity-50 mt-0.5">
                          {item.phone || 'Sin teléfono'}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex flex-wrap gap-1 max-w-[250px]">
                          {item.is_superuser && (
                            <span className="inline-flex items-center px-2 py-0.5 rounded-lg text-[10px] font-bold bg-red-900/20 text-red-400 border border-red-800/30">
                              SUPERADMIN
                            </span>
                          )}
                          {item.roles.map((r) => (
                            <span
                              key={r}
                              className={`inline-flex items-center px-2 py-0.5 rounded-lg text-[10px] font-bold border ${
                                ROLE_BADGE_COLORS[r] || 'bg-teal-900/10 text-teal-300 border-teal-800/20'
                              }`}
                            >
                              {ROLE_LABELS[r] || r}
                            </span>
                          ))}
                          {!item.is_superuser && item.roles.length === 0 && (
                            <span className="text-xs text-crema text-opacity-30 italic">
                              Sin roles asignados
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-center">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border ${statusCfg.classes}`}>
                          {statusCfg.label}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-xs text-crema text-opacity-70">
                        {formattedDate}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-1.5 whitespace-nowrap">
                          <Link
                            to={`/usuarios/${item.id}/editar`}
                            className="p-2 bg-white/5 hover:bg-dorado/20 text-crema hover:text-dorado border border-white/10 rounded-xl transition-all flex items-center gap-1.5 text-xs font-semibold"
                            title="Editar Perfil"
                          >
                            <Edit className="w-3.5 h-3.5" />
                            <span>Editar</span>
                          </Link>
                          <button
                            id={`block-btn-${item.id}`}
                            onClick={() => handleToggleBlock(item)}
                            className={`p-2 rounded-xl border transition-all flex items-center gap-1.5 text-xs font-semibold ${
                              item.status === 'BLOCKED'
                                ? 'bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border-emerald-500/20'
                                : 'bg-red-500/10 hover:bg-red-500/20 text-red-400 border-red-500/20'
                            }`}
                            title={item.status === 'BLOCKED' ? 'Desbloquear Cuenta' : 'Bloquear Cuenta'}
                          >
                            {item.status === 'BLOCKED' ? (
                              <>
                                <Unlock className="w-3.5 h-3.5" />
                                <span>Desbloquear</span>
                              </>
                            ) : (
                              <>
                                <Lock className="w-3.5 h-3.5" />
                                <span>Bloquear</span>
                              </>
                            )}
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
                id="users-prev"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-2 text-crema hover:text-white disabled:opacity-25 transition-all"
              >
                <ArrowLeft className="w-4 h-4" />
              </button>
              <button
                id="users-next"
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

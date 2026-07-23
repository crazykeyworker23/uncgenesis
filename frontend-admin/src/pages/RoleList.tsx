import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Shield, Key, AlertCircle, Save, X, Edit2 } from 'lucide-react';
import { apiClient } from '../api/client';
import { Role, Permission, ROLE_LABELS } from '../features/roles/types';

// ── Edit Permissions Drawer ──────────────────────────────────────────────────
interface PermissionsDrawerProps {
  role: Role;
  allPermissions: Permission[];
  onClose: () => void;
  onSave: (roleId: number, permissions: string[]) => void;
  isSaving: boolean;
}

const PermissionsDrawer: React.FC<PermissionsDrawerProps> = ({
  role, allPermissions, onClose, onSave, isSaving
}) => {
  const [selectedPerms, setSelectedPerms] = useState<string[]>(role.permissions);

  const handleToggle = (codename: string) => {
    const current = [...selectedPerms];
    const index = current.indexOf(codename);
    if (index > -1) {
      current.splice(index, 1);
    } else {
      current.push(codename);
    }
    setSelectedPerms(current);
  };

  const handleSelectAll = () => {
    if (selectedPerms.length === allPermissions.length) {
      setSelectedPerms([]);
    } else {
      setSelectedPerms(allPermissions.map(p => p.codename));
    }
  };

  // Group permissions by category (first word of codename before underscore, e.g. "PUBLICATIONS_VIEW" -> "PUBLICATIONS")
  const categories = allPermissions.reduce((acc, perm) => {
    const parts = perm.codename.split('_');
    const category = parts[0] || 'OTROS';
    if (!acc[category]) acc[category] = [];
    acc[category].push(perm);
    return acc;
  }, {} as Record<string, Permission[]>);

  return (
    <div className="fixed inset-0 z-50 flex justify-end" onClick={onClose}>
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black bg-opacity-40 backdrop-blur-sm" />

      {/* Drawer */}
      <div
        className="relative w-full max-w-lg h-full bg-gray-900 border-l border-gray-800 flex flex-col shadow-2xl overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-800 bg-deep-teal bg-opacity-30">
          <div className="flex items-center gap-2">
            <Shield className="w-5 h-5 text-dorado" />
            <div>
              <span className="font-semibold text-white">Configurar Permisos</span>
              <p className="text-[10px] text-crema text-opacity-50">Rol: {ROLE_LABELS[role.name] || role.name}</p>
            </div>
          </div>
          <button
            id="permissions-drawer-close"
            onClick={onClose}
            className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-800 rounded-lg transition-all"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Categories checklist */}
        <div className="flex-1 p-5 space-y-6 overflow-y-auto">
          <div className="flex items-center justify-between border-b border-white/5 pb-2">
            <span className="text-xs text-crema text-opacity-65 font-bold">Matriz de Permisos</span>
            <button
              type="button"
              onClick={handleSelectAll}
              className="text-xs text-dorado hover:text-yellow-400 transition-colors"
            >
              {selectedPerms.length === allPermissions.length ? 'Desmarcar Todos' : 'Marcar Todos'}
            </button>
          </div>

          {Object.entries(categories).map(([categoryName, perms]) => (
            <div key={categoryName} className="space-y-2">
              <h4 className="text-[10px] font-bold text-dorado uppercase tracking-widest">{categoryName}</h4>
              <div className="grid grid-cols-1 gap-2">
                {perms.map((perm) => {
                  const isChecked = selectedPerms.includes(perm.codename);
                  return (
                    <div
                      key={perm.id}
                      onClick={() => handleToggle(perm.codename)}
                      className={`p-3 rounded-xl border transition-all cursor-pointer flex items-start gap-2.5 select-none ${
                        isChecked
                          ? 'bg-teal-900/30 border-dorado/40 text-white'
                          : 'bg-deep-teal/10 border-white/5 text-gray-400 hover:border-white/10'
                      }`}
                    >
                      <input
                        type="checkbox"
                        checked={isChecked}
                        readOnly
                        className="mt-0.5 accent-dorado shrink-0"
                      />
                      <div className="min-w-0">
                        <p className="text-[11px] font-bold text-white leading-none">{perm.name}</p>
                        <p className="text-[9px] text-crema/50 leading-normal mt-1">{perm.description || perm.codename}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-gray-800 bg-gray-950/20 flex gap-2">
          <button
            id="permissions-save-btn"
            disabled={isSaving}
            onClick={() => onSave(role.id, selectedPerms)}
            className="flex-1 py-2.5 bg-teal-600 hover:bg-teal-500 disabled:opacity-50 text-white rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-2 shadow"
          >
            {isSaving ? (
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : (
              <Save className="w-4 h-4" />
            )}
            Guardar Cambios
          </button>
          <button
            onClick={onClose}
            className="px-4 py-2.5 bg-gray-800 hover:bg-gray-700 text-crema text-opacity-70 hover:text-white rounded-xl text-xs font-semibold transition-all"
          >
            Cancelar
          </button>
        </div>
      </div>
    </div>
  );
};

// ── Main Page Component ───────────────────────────────────────────────────────
export const RoleList: React.FC = () => {
  const queryClient = useQueryClient();
  const [editingRole, setEditingRole] = useState<Role | null>(null);

  // Fetch all roles
  const { data: roles = [], isLoading: isLoadingRoles, isError: isErrorRoles } = useQuery<Role[]>({
    queryKey: ['roles'],
    queryFn: async () => {
      const res = await apiClient.get('/roles/');
      return res.data;
    },
  });

  // Fetch all permissions (matrix lookup)
  const { data: permissions = [] } = useQuery<Permission[]>({
    queryKey: ['permissions'],
    queryFn: async () => {
      const res = await apiClient.get('/roles/permissions/');
      return res.data;
    },
  });

  // Mutation to update permissions mapping of a role
  const updateMutation = useMutation({
    mutationFn: async ({ roleId, assigned_permissions }: { roleId: number; assigned_permissions: string[] }) => {
      const res = await apiClient.patch(`/roles/${roleId}/`, { assigned_permissions });
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['roles'] });
      setEditingRole(null);
    },
  });

  return (
    <div className="space-y-6">
      {/* Edit Drawer */}
      {editingRole && (
        <PermissionsDrawer
          role={editingRole}
          allPermissions={permissions}
          onClose={() => setEditingRole(null)}
          onSave={(id, perms) => updateMutation.mutate({ roleId: id, assigned_permissions: perms })}
          isSaving={updateMutation.isPending}
        />
      )}

      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-white flex items-center gap-2">
          <Shield className="w-6 h-6 text-dorado" />
          Roles y Permisos de Seguridad
        </h1>
        <p className="text-sm text-crema text-opacity-50 mt-1">
          Configura y edita los privilegios asociados a los perfiles del sistema
        </p>
      </div>

      {isLoadingRoles ? (
        <div className="flex flex-col items-center justify-center py-20 text-crema text-opacity-50">
          <div className="animate-spin w-8 h-8 border-4 border-dorado border-t-transparent rounded-full mb-3" />
          Cargando roles del sistema...
        </div>
      ) : isErrorRoles ? (
        <div className="flex items-center justify-center gap-2 py-20 text-error-red">
          <AlertCircle className="w-5 h-5" />
          Error al cargar roles. Intenta de nuevo.
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {roles.map((role) => (
            <div
              key={role.id}
              className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl flex flex-col justify-between"
            >
              <div>
                <div className="flex items-start justify-between border-b border-white/5 pb-3 mb-4">
                  <div>
                    <h3 className="text-base font-bold text-white">{ROLE_LABELS[role.name] || role.name}</h3>
                    <p className="text-xs text-crema text-opacity-50 mt-0.5 font-mono text-[10px]">
                      Clave: {role.name}
                    </p>
                  </div>
                  <button
                    id={`edit-perms-btn-${role.id}`}
                    onClick={() => setEditingRole(role)}
                    className="inline-flex items-center gap-1 px-3 py-1.5 bg-dorado/15 hover:bg-dorado/20 text-dorado rounded-xl text-xs font-semibold transition-all border border-dorado/20"
                  >
                    <Edit2 className="w-3.5 h-3.5" />
                    Editar Permisos
                  </button>
                </div>

                <p className="text-xs text-crema text-opacity-70 leading-relaxed mb-4">
                  {role.description || 'Sin descripción asignada.'}
                </p>

                <div className="space-y-2">
                  <span className="text-[10px] font-bold text-dorado uppercase tracking-wider block">
                    Permisos Asignados ({role.permissions.length})
                  </span>
                  <div className="flex flex-wrap gap-1.5 max-h-[140px] overflow-y-auto pr-1">
                    {role.permissions.length === 0 ? (
                      <span className="text-xs text-crema text-opacity-35 italic">
                        Este rol no tiene permisos asociados.
                      </span>
                    ) : (
                      role.permissions.map((codename) => (
                        <span
                          key={codename}
                          className="inline-flex items-center gap-1 px-2 py-0.5 rounded-lg text-[9px] font-bold bg-teal-900 bg-opacity-30 text-teal-300 border border-teal-800 border-opacity-30"
                        >
                          <Key className="w-2.5 h-2.5 text-dorado" />
                          {codename}
                        </span>
                      ))
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

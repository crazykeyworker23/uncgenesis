import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ArrowLeft, Save, User, Shield, Phone, Mail, MapPin, Info } from 'lucide-react';
import { apiClient } from '../api/client';
import { Role } from '../features/roles/types';

export const UserForm: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const isEdit = !!id;
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const { register, handleSubmit, reset, setValue, watch, formState: { errors } } = useForm({
    defaultValues: {
      email: '',
      first_name: '',
      last_name: '',
      phone: '',
      location: '',
      bio: '',
      status: 'ACTIVE',
      assigned_roles: [] as string[],
      password: '',
    }
  });

  const selectedRoles = watch('assigned_roles') || [];

  // Fetch all available roles
  const { data: roles = [] } = useQuery<Role[]>({
    queryKey: ['roles'],
    queryFn: async () => {
      const res = await apiClient.get('/roles/');
      return res.data;
    },
  });

  // Fetch user data if in edit mode
  const { isLoading: isLoadingUser } = useQuery({
    queryKey: ['user', id],
    queryFn: async () => {
      const res = await apiClient.get(`/users/${id}/`);
      const user = res.data;
      reset({
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone || '',
        location: user.location || '',
        bio: user.bio || '',
        status: user.status,
        assigned_roles: user.roles,
        password: '',
      });
      return user;
    },
    enabled: isEdit,
  });

  // Mutation for Save (Create or Update)
  const saveMutation = useMutation({
    mutationFn: async (formData: any) => {
      const payload = {
        email: formData.email,
        first_name: formData.first_name,
        last_name: formData.last_name,
        phone: formData.phone || '',
        location: formData.location || '',
        bio: formData.bio || '',
        status: formData.status,
        assigned_roles: formData.assigned_roles,
      } as any;

      if (!isEdit && formData.password) {
        payload.password = formData.password;
      }

      if (isEdit) {
        return apiClient.put(`/users/${id}/`, payload);
      } else {
        return apiClient.post('/users/', payload);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      navigate('/usuarios');
    },
    onError: (err: any) => {
      const details = err.response?.data;
      if (typeof details === 'object') {
        const msg = Object.entries(details)
          .map(([key, val]) => `${key}: ${Array.isArray(val) ? val.join(', ') : val}`)
          .join(' | ');
        setErrorMsg(msg);
      } else {
        setErrorMsg('Error de red al guardar el usuario.');
      }
    }
  });

  const onSubmit = (data: any) => {
    setErrorMsg(null);
    saveMutation.mutate(data);
  };

  const handleRoleToggle = (roleName: string) => {
    const current = [...selectedRoles];
    const index = current.indexOf(roleName);
    if (index > -1) {
      current.splice(index, 1);
    } else {
      current.push(roleName);
    }
    setValue('assigned_roles', current);
  };

  if (isEdit && isLoadingUser) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-crema text-opacity-50">
        <div className="animate-spin w-8 h-8 border-4 border-dorado border-t-transparent rounded-full mb-3" />
        Cargando perfil de usuario...
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link
          to="/usuarios"
          id="user-form-back"
          className="p-2 text-gray-400 hover:text-white hover:bg-gray-800 rounded-xl transition-all"
        >
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-white">
            {isEdit ? 'Editar Cuenta de Usuario' : 'Registrar Nuevo Usuario'}
          </h1>
          <p className="text-sm text-crema text-opacity-50 mt-0.5">
            {isEdit ? 'Modifica los datos del perfil y sus roles' : 'Crea una cuenta administrativa o de líder'}
          </p>
        </div>
      </div>

      {/* Error Alert */}
      {errorMsg && (
        <div className="p-4 bg-red-950/30 border border-red-900/40 rounded-xl text-red-300 text-xs flex items-center gap-2">
          <Info className="w-4 h-4 text-red-400 shrink-0" />
          <span>{errorMsg}</span>
        </div>
      )}

      {/* Form */}
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* Info Section */}
        <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl space-y-4">
          <h3 className="text-sm font-bold text-dorado flex items-center gap-2 border-b border-white/5 pb-2">
            <User className="w-4 h-4" />
            Información del Perfil
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* First Name */}
            <div className="space-y-1.5">
              <label htmlFor="user-first-name" className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
                Nombres *
              </label>
              <input
                id="user-first-name"
                type="text"
                className={`w-full px-4 py-2.5 bg-deep-teal bg-opacity-40 border rounded-xl text-white placeholder-crema placeholder-opacity-35 text-xs focus:outline-none transition-all ${
                  errors.first_name ? 'border-red-500' : 'border-white border-opacity-10 focus:border-dorado'
                }`}
                {...register('first_name', { required: 'El nombre es obligatorio' })}
              />
            </div>

            {/* Last Name */}
            <div className="space-y-1.5">
              <label htmlFor="user-last-name" className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
                Apellidos *
              </label>
              <input
                id="user-last-name"
                type="text"
                className={`w-full px-4 py-2.5 bg-deep-teal bg-opacity-40 border rounded-xl text-white placeholder-crema placeholder-opacity-35 text-xs focus:outline-none transition-all ${
                  errors.last_name ? 'border-red-500' : 'border-white border-opacity-10 focus:border-dorado'
                }`}
                {...register('last_name', { required: 'El apellido es obligatorio' })}
              />
            </div>

            {/* Email */}
            <div className="space-y-1.5">
              <label htmlFor="user-email" className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
                <Mail className="inline w-3.5 h-3.5 mr-1 text-dorado" />
                Correo Electrónico *
              </label>
              <input
                id="user-email"
                type="email"
                disabled={isEdit}
                className={`w-full px-4 py-2.5 bg-deep-teal bg-opacity-40 border rounded-xl text-white placeholder-crema placeholder-opacity-35 text-xs focus:outline-none transition-all disabled:opacity-40 ${
                  errors.email ? 'border-red-500' : 'border-white border-opacity-10 focus:border-dorado'
                }`}
                {...register('email', { required: 'El correo es obligatorio' })}
              />
            </div>

            {/* Phone */}
            <div className="space-y-1.5">
              <label htmlFor="user-phone" className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
                <Phone className="inline w-3.5 h-3.5 mr-1 text-dorado" />
                Teléfono de Contacto
              </label>
              <input
                id="user-phone"
                type="text"
                placeholder="+51999999999"
                className="w-full px-4 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl text-white text-xs focus:outline-none focus:border-dorado"
                {...register('phone')}
              />
            </div>

            {/* Location */}
            <div className="space-y-1.5">
              <label htmlFor="user-location" className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
                <MapPin className="inline w-3.5 h-3.5 mr-1 text-dorado" />
                Ubicación / Ciudad
              </label>
              <input
                id="user-location"
                type="text"
                className="w-full px-4 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl text-white text-xs focus:outline-none focus:border-dorado"
                {...register('location')}
              />
            </div>

            {/* Status */}
            <div className="space-y-1.5">
              <label htmlFor="user-status" className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
                Estado de Cuenta
              </label>
              <select
                id="user-status"
                className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-4 py-2.5 text-xs text-crema focus:outline-none focus:border-dorado"
                {...register('status')}
              >
                <option value="ACTIVE" className="bg-gray-900 text-crema">Activo (ACTIVE)</option>
                <option value="INACTIVE" className="bg-gray-900 text-crema">Inactivo (INACTIVE)</option>
                <option value="BLOCKED" className="bg-gray-900 text-crema">Bloqueado (BLOCKED)</option>
              </select>
            </div>

            {/* Password (only on create) */}
            {!isEdit && (
              <div className="space-y-1.5 col-span-2">
                <label htmlFor="user-password" className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
                  Contraseña Inicial *
                </label>
                <input
                  id="user-password"
                  type="password"
                  placeholder="GenesisPassword123"
                  className={`w-full px-4 py-2.5 bg-deep-teal bg-opacity-40 border rounded-xl text-white placeholder-crema placeholder-opacity-35 text-xs focus:outline-none transition-all ${
                    errors.password ? 'border-red-500' : 'border-white border-opacity-10 focus:border-dorado'
                  }`}
                  {...register('password', { required: 'La contraseña es obligatoria para nuevos usuarios' })}
                />
              </div>
            )}

            {/* Bio */}
            <div className="space-y-1.5 col-span-2">
              <label htmlFor="user-bio" className="block text-xs font-semibold text-crema text-opacity-70 ml-1">
                Biografía / Notas
              </label>
              <textarea
                id="user-bio"
                rows={3}
                className="w-full px-4 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl text-white text-xs focus:outline-none focus:border-dorado resize-none"
                {...register('bio')}
              />
            </div>
          </div>
        </div>

        {/* Roles Section */}
        <div className="glass-panel p-6 bg-dark-teal bg-opacity-20 border border-white border-opacity-5 rounded-2xl space-y-4">
          <h3 className="text-sm font-bold text-dorado flex items-center gap-2 border-b border-white/5 pb-2">
            <Shield className="w-4 h-4" />
            Roles y Permisos Asignados
          </h3>

          <p className="text-xs text-crema text-opacity-50">
            Selecciona los roles del sistema que corresponden al usuario. Sus permisos se heredarán automáticamente.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {roles.map((role) => {
              const isChecked = selectedRoles.includes(role.name);
              return (
                <div
                  key={role.id}
                  onClick={() => handleRoleToggle(role.name)}
                  className={`p-4 rounded-xl border transition-all cursor-pointer flex items-start gap-3 select-none ${
                    isChecked
                      ? 'bg-teal-900/30 border-dorado text-white'
                      : 'bg-deep-teal/20 border-white/5 text-gray-400 hover:border-white/10'
                  }`}
                >
                  <input
                    type="checkbox"
                    checked={isChecked}
                    readOnly
                    className="mt-1 accent-dorado"
                  />
                  <div>
                    <p className="text-xs font-bold text-white">{role.name}</p>
                    <p className="text-[10px] text-crema/60 leading-normal mt-0.5">{role.description}</p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Form Actions */}
        <div className="flex items-center gap-3">
          <button
            id="user-form-submit"
            type="submit"
            disabled={saveMutation.isPending}
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-teal-600 hover:bg-teal-500 disabled:opacity-60 text-white rounded-xl text-xs font-bold transition-all shadow"
          >
            {saveMutation.isPending ? (
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : (
              <Save className="w-4 h-4" />
            )}
            Guardar Usuario
          </button>
          <button
            id="user-form-cancel"
            type="button"
            onClick={() => navigate('/usuarios')}
            className="px-4 py-2.5 text-crema text-opacity-50 hover:text-white text-xs font-semibold transition-colors"
          >
            Cancelar
          </button>
        </div>
      </form>
    </div>
  );
};

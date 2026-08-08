import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Save,
  ArrowLeft,
  Loader2,
  MapPin,
  Clock,
  User,
  FileText,
  Activity,
} from 'lucide-react';
import { apiClient } from '../api/client';
import {
  CellGroup,
  CellStatus,
  MeetingDay,
  MEETING_DAY_LABELS,
} from '../features/cells/types';

// ----------------------------
// Mini mobile preview component
// ----------------------------
interface MobilePreviewProps {
  name: string;
  leaderName: string;
  day: MeetingDay | '';
  time: string;
  address: string;
  description: string;
  status: CellStatus;
}

const MobilePreview: React.FC<MobilePreviewProps> = ({ name, leaderName, day, time, address, description, status }) => {
  const statusColor = status === 'ACTIVE' ? '#10b981' : '#6b7280';
  const dayLabel = day ? MEETING_DAY_LABELS[day] : '—';
  const timeDisplay = time ? time.slice(0, 5) : '—:—';

  return (
    <div className="w-[280px] bg-[#0f172a] rounded-[32px] border-[3px] border-gray-700 overflow-hidden shadow-2xl">
      {/* Notch */}
      <div className="h-6 bg-[#0f172a] flex justify-center items-center">
        <div className="w-20 h-3 bg-gray-800 rounded-full" />
      </div>

      {/* App header */}
      <div className="bg-gradient-to-r from-teal-900 to-teal-700 px-4 py-3">
        <p className="text-teal-300 text-[9px] uppercase tracking-widest font-semibold">Iglesia Génesis</p>
        <h2 className="text-white text-sm font-bold mt-0.5">Grupos de Conexión</h2>
      </div>

      {/* Card */}
      <div className="p-3">
        <div className="bg-gray-800 rounded-2xl overflow-hidden">
          {/* Color bar */}
          <div className="h-1 bg-gradient-to-r from-teal-500 to-cyan-400" />
          <div className="p-3 space-y-2">
            {/* Group name */}
            <div>
              <h3 className="text-white text-sm font-bold leading-tight">
                {name || 'Nombre del grupo'}
              </h3>
              <div className="flex items-center gap-1 mt-0.5">
                <div className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: statusColor }} />
                <p className="text-gray-400 text-[9px]">{status === 'ACTIVE' ? 'Activo' : 'Inactivo'}</p>
              </div>
            </div>

            {/* Leader */}
            <div className="flex items-center gap-2">
              <div className="w-6 h-6 rounded-full bg-teal-700 flex items-center justify-center flex-shrink-0">
                <span className="text-[9px] text-white font-bold">{leaderName ? leaderName[0].toUpperCase() : '?'}</span>
              </div>
              <div>
                <p className="text-[9px] text-gray-500 uppercase tracking-wide">Líder</p>
                <p className="text-white text-[10px] font-medium leading-tight">{leaderName || 'Sin líder asignado'}</p>
              </div>
            </div>

            {/* Meeting info */}
            <div className="flex gap-2">
              <div className="flex-1 bg-gray-900 rounded-lg p-2">
                <p className="text-[8px] text-gray-500 uppercase tracking-wide">Día</p>
                <p className="text-white text-[10px] font-semibold mt-0.5">{dayLabel}</p>
              </div>
              <div className="flex-1 bg-gray-900 rounded-lg p-2">
                <p className="text-[8px] text-gray-500 uppercase tracking-wide">Hora</p>
                <p className="text-white text-[10px] font-semibold mt-0.5">{timeDisplay}</p>
              </div>
            </div>

            {/* Address */}
            <div className="flex items-start gap-1.5 bg-gray-900 rounded-lg p-2">
              <MapPin className="w-3 h-3 text-teal-400 flex-shrink-0 mt-0.5" />
              <p className="text-gray-300 text-[9px] leading-relaxed">
                {address || 'Dirección no especificada'}
              </p>
            </div>

            {/* Description */}
            {description && (
              <p className="text-gray-500 text-[9px] leading-relaxed line-clamp-3">{description}</p>
            )}

            {/* CTA */}
            <button className="w-full py-2 bg-gradient-to-r from-teal-600 to-teal-500 rounded-lg text-white text-[10px] font-semibold">
              Unirme a este grupo
            </button>
          </div>
        </div>
      </div>

      {/* Bottom bar */}
      <div className="h-4 flex justify-center items-end pb-1">
        <div className="w-20 h-1 bg-gray-700 rounded-full" />
      </div>
    </div>
  );
};

// ----------------------------
// Main CellForm component
// ----------------------------
interface FormData {
  name: string;
  leader_id: string;
  coordinator_id: string;
  meeting_day: MeetingDay | '';
  meeting_time: string;
  address: string;
  latitude: string;
  longitude: string;
  description: string;
  status: CellStatus;
}

const EMPTY_FORM: FormData = {
  name: '',
  leader_id: '',
  coordinator_id: '',
  meeting_day: '',
  meeting_time: '',
  address: '',
  latitude: '',
  longitude: '',
  description: '',
  status: 'ACTIVE',
};

export const CellForm: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const isEdit = Boolean(id);

  const [form, setForm] = useState<FormData>(EMPTY_FORM);
  const [errors, setErrors] = useState<Partial<Record<keyof FormData, string>>>({});
  const [leaderName, setLeaderName] = useState('');

  // Fetch existing cell for edit
  const { data: existingCell, isLoading: loadingCell } = useQuery<CellGroup>({
    queryKey: ['cell', id],
    queryFn: async () => {
      const res = await apiClient.get(`/cells/${id}/`);
      return res.data;
    },
    enabled: isEdit,
  });

  // Fetch staff users for leader selector
  const { data: usersData } = useQuery({
    queryKey: ['users-list'],
    queryFn: async () => {
      const res = await apiClient.get('/users/', { params: { page_size: 200 } });
      return res.data;
    },
  });

  const users = usersData?.results ?? [];

  useEffect(() => {
    if (existingCell) {
      setForm({
        name: existingCell.name,
        leader_id: existingCell.leader?.id?.toString() ?? '',
        coordinator_id: existingCell.coordinator?.id?.toString() ?? '',
        meeting_day: existingCell.meeting_day,
        meeting_time: existingCell.meeting_time?.slice(0, 5) ?? '',
        address: existingCell.address,
        latitude: existingCell.latitude ?? '',
        longitude: existingCell.longitude ?? '',
        description: existingCell.description,
        status: existingCell.status,
      });
      if (existingCell.leader) {
        setLeaderName(`${existingCell.leader.first_name} ${existingCell.leader.last_name}`.trim());
      }
    }
  }, [existingCell]);

  const mutation = useMutation({
    mutationFn: (payload: object) =>
      isEdit
        ? apiClient.patch(`/cells/${id}/`, payload)
        : apiClient.post('/cells/', payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cells'] });
      navigate('/celulas');
    },
  });

  const handleChange = (field: keyof FormData, value: string) => {
    setForm((prev) => ({ ...prev, [field]: value }));
    if (errors[field]) setErrors((prev) => ({ ...prev, [field]: undefined }));

    // Track leader name for preview
    if (field === 'leader_id') {
      const selected = users.find((u: { id: number }) => u.id.toString() === value);
      if (selected) {
        setLeaderName(`${selected.first_name} ${selected.last_name}`.trim() || selected.email);
      } else {
        setLeaderName('');
      }
    }
  };

  const validate = (): boolean => {
    const newErrors: Partial<Record<keyof FormData, string>> = {};
    if (!form.name.trim()) newErrors.name = 'El nombre es obligatorio';
    if (!form.meeting_day) newErrors.meeting_day = 'Selecciona un día';
    if (!form.meeting_time) newErrors.meeting_time = 'Indica la hora de reunión';
    if (!form.address.trim()) newErrors.address = 'La dirección es obligatoria';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    const payload: Record<string, unknown> = {
      name: form.name.trim(),
      meeting_day: form.meeting_day,
      meeting_time: form.meeting_time + ':00',
      address: form.address.trim(),
      description: form.description.trim(),
      status: form.status,
      leader_id: form.leader_id ? parseInt(form.leader_id) : null,
      coordinator_id: form.coordinator_id ? parseInt(form.coordinator_id) : null,
      latitude: form.latitude ? form.latitude : null,
      longitude: form.longitude ? form.longitude : null,
    };

    mutation.mutate(payload);
  };

  if (isEdit && loadingCell) {
    return (
      <div className="flex items-center justify-center h-64 text-gray-400">
        <Loader2 className="animate-spin w-6 h-6 mr-2" />
        Cargando grupo…
      </div>
    );
  }

  return (
    <div className="flex gap-8 items-start">
      {/* ---- FORM ---- */}
      <div className="flex-1 space-y-6">
        {/* Header */}
        <div className="flex items-center gap-3">
          <button
            id="cell-form-back"
            onClick={() => navigate('/celulas')}
            className="p-2 text-gray-400 hover:text-white hover:bg-gray-800 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h1 className="text-2xl font-bold text-white">
              {isEdit ? 'Editar Grupo de Célula' : 'Nueva Célula'}
            </h1>
            <p className="text-sm text-gray-400 mt-0.5">
              {isEdit ? `Modificando "${existingCell?.name}"` : 'Registra un nuevo grupo de conexión'}
            </p>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Group Name */}
          <div>
            <label htmlFor="cell-name" className="block text-sm font-medium text-gray-300 mb-1.5">
              <FileText className="inline w-4 h-4 mr-1 text-teal-400" />
              Nombre del grupo <span className="text-red-400">*</span>
            </label>
            <input
              id="cell-name"
              type="text"
              value={form.name}
              onChange={(e) => handleChange('name', e.target.value)}
              placeholder="Ej. Células del Norte, Casa de Fe…"
              className={`w-full px-4 py-2.5 bg-gray-800 border rounded-lg text-white placeholder-gray-500 text-sm focus:outline-none transition-colors ${
                errors.name ? 'border-red-500 focus:border-red-400' : 'border-gray-700 focus:border-teal-500'
              }`}
            />
            {errors.name && <p className="text-red-400 text-xs mt-1">{errors.name}</p>}
          </div>

          {/* Leader */}
          <div>
            <label htmlFor="cell-leader" className="block text-sm font-medium text-gray-300 mb-1.5">
              <User className="inline w-4 h-4 mr-1 text-teal-400" />
              Líder del grupo
            </label>
            <select
              id="cell-leader"
              value={form.leader_id}
              onChange={(e) => handleChange('leader_id', e.target.value)}
              className="w-full px-4 py-2.5 bg-gray-800 border border-gray-700 text-white rounded-lg text-sm focus:outline-none focus:border-teal-500 transition-colors"
            >
              <option value="">Sin líder asignado</option>
              {users.map((u: { id: number; first_name: string; last_name: string; email: string }) => (
                <option key={u.id} value={u.id}>
                  {u.first_name} {u.last_name} ({u.email})
                </option>
              ))}
            </select>
          </div>

          {/* Coordinador: nivel intermedio entre el pastorado y el líder.
              Supervisa varias células y ve el desempeño de cada una. */}
          <div>
            <label htmlFor="cell-coordinator" className="block text-sm font-medium text-gray-300 mb-1.5">
              <User className="inline w-4 h-4 mr-1 text-teal-400" />
              Coordinador
            </label>
            <select
              id="cell-coordinator"
              value={form.coordinator_id}
              onChange={(e) => handleChange('coordinator_id', e.target.value)}
              className="w-full px-4 py-2.5 bg-gray-800 border border-gray-700 text-white rounded-lg text-sm focus:outline-none focus:border-teal-500 transition-colors"
            >
              <option value="">Sin coordinador asignado</option>
              {users.map((u: { id: number; first_name: string; last_name: string; email: string }) => (
                <option key={u.id} value={u.id}>
                  {u.first_name} {u.last_name} ({u.email})
                </option>
              ))}
            </select>
            <p className="text-xs text-gray-500 mt-1.5">
              Podrá supervisar esta célula: sus miembros, reuniones y seguimiento.
            </p>
          </div>

          {/* Meeting Day & Time */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label htmlFor="cell-day" className="block text-sm font-medium text-gray-300 mb-1.5">
                Día de reunión <span className="text-red-400">*</span>
              </label>
              <select
                id="cell-day"
                value={form.meeting_day}
                onChange={(e) => handleChange('meeting_day', e.target.value)}
                className={`w-full px-4 py-2.5 bg-gray-800 border rounded-lg text-white text-sm focus:outline-none transition-colors ${
                  errors.meeting_day ? 'border-red-500' : 'border-gray-700 focus:border-teal-500'
                }`}
              >
                <option value="">Seleccionar…</option>
                {(Object.keys(MEETING_DAY_LABELS) as MeetingDay[]).map((day) => (
                  <option key={day} value={day}>{MEETING_DAY_LABELS[day]}</option>
                ))}
              </select>
              {errors.meeting_day && <p className="text-red-400 text-xs mt-1">{errors.meeting_day}</p>}
            </div>
            <div>
              <label htmlFor="cell-time" className="block text-sm font-medium text-gray-300 mb-1.5">
                <Clock className="inline w-4 h-4 mr-1 text-teal-400" />
                Hora <span className="text-red-400">*</span>
              </label>
              <input
                id="cell-time"
                type="time"
                value={form.meeting_time}
                onChange={(e) => handleChange('meeting_time', e.target.value)}
                className={`w-full px-4 py-2.5 bg-gray-800 border rounded-lg text-white text-sm focus:outline-none transition-colors ${
                  errors.meeting_time ? 'border-red-500' : 'border-gray-700 focus:border-teal-500'
                }`}
              />
              {errors.meeting_time && <p className="text-red-400 text-xs mt-1">{errors.meeting_time}</p>}
            </div>
          </div>

          {/* Address */}
          <div>
            <label htmlFor="cell-address" className="block text-sm font-medium text-gray-300 mb-1.5">
              <MapPin className="inline w-4 h-4 mr-1 text-teal-400" />
              Dirección <span className="text-red-400">*</span>
            </label>
            <input
              id="cell-address"
              type="text"
              value={form.address}
              onChange={(e) => handleChange('address', e.target.value)}
              placeholder="Av. Lima 123, Lima, Perú"
              className={`w-full px-4 py-2.5 bg-gray-800 border rounded-lg text-white placeholder-gray-500 text-sm focus:outline-none transition-colors ${
                errors.address ? 'border-red-500' : 'border-gray-700 focus:border-teal-500'
              }`}
            />
            {errors.address && <p className="text-red-400 text-xs mt-1">{errors.address}</p>}
          </div>

          {/* Coordinates (optional) */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label htmlFor="cell-lat" className="block text-sm font-medium text-gray-300 mb-1.5">
                <Activity className="inline w-4 h-4 mr-1 text-teal-400" />
                Latitud <span className="text-gray-500">(opcional)</span>
              </label>
              <input
                id="cell-lat"
                type="number"
                step="0.0000001"
                value={form.latitude}
                onChange={(e) => handleChange('latitude', e.target.value)}
                placeholder="-12.0464"
                className="w-full px-4 py-2.5 bg-gray-800 border border-gray-700 text-white placeholder-gray-500 rounded-lg text-sm focus:outline-none focus:border-teal-500 transition-colors"
              />
            </div>
            <div>
              <label htmlFor="cell-lng" className="block text-sm font-medium text-gray-300 mb-1.5">
                Longitud <span className="text-gray-500">(opcional)</span>
              </label>
              <input
                id="cell-lng"
                type="number"
                step="0.0000001"
                value={form.longitude}
                onChange={(e) => handleChange('longitude', e.target.value)}
                placeholder="-77.0428"
                className="w-full px-4 py-2.5 bg-gray-800 border border-gray-700 text-white placeholder-gray-500 rounded-lg text-sm focus:outline-none focus:border-teal-500 transition-colors"
              />
            </div>
          </div>

          {/* Description */}
          <div>
            <label htmlFor="cell-description" className="block text-sm font-medium text-gray-300 mb-1.5">
              Descripción
            </label>
            <textarea
              id="cell-description"
              rows={3}
              value={form.description}
              onChange={(e) => handleChange('description', e.target.value)}
              placeholder="Breve descripción del grupo de célula…"
              className="w-full px-4 py-2.5 bg-gray-800 border border-gray-700 text-white placeholder-gray-500 rounded-lg text-sm focus:outline-none focus:border-teal-500 transition-colors resize-none"
            />
          </div>

          {/* Status */}
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Estado</label>
            <div className="flex gap-3">
              {(['ACTIVE', 'INACTIVE'] as CellStatus[]).map((s) => (
                <label
                  key={s}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg border cursor-pointer transition-colors ${
                    form.status === s
                      ? 'border-teal-500 bg-teal-500/10 text-teal-300'
                      : 'border-gray-700 text-gray-400 hover:border-gray-600'
                  }`}
                >
                  <input
                    type="radio"
                    name="cell-status"
                    id={`cell-status-${s}`}
                    value={s}
                    checked={form.status === s}
                    onChange={() => handleChange('status', s)}
                    className="sr-only"
                  />
                  <span className="text-sm font-medium">{s === 'ACTIVE' ? 'Activo' : 'Inactivo'}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Error banner */}
          {mutation.isError && (
            <div className="p-3 bg-red-900/30 border border-red-700/50 rounded-lg text-red-300 text-sm">
              Error al guardar. Por favor, revisa los campos e intenta nuevamente.
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-3 pt-2">
            <button
              id="cell-form-submit"
              type="submit"
              disabled={mutation.isPending}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-teal-600 hover:bg-teal-500 disabled:opacity-60 disabled:cursor-not-allowed text-white rounded-lg text-sm font-medium transition-colors"
            >
              {mutation.isPending ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Save className="w-4 h-4" />
              )}
              {isEdit ? 'Guardar cambios' : 'Crear célula'}
            </button>
            <button
              id="cell-form-cancel"
              type="button"
              onClick={() => navigate('/celulas')}
              className="px-4 py-2.5 text-gray-400 hover:text-white text-sm transition-colors"
            >
              Cancelar
            </button>
          </div>
        </form>
      </div>

      {/* ---- MOBILE PREVIEW ---- */}
      <div className="hidden xl:flex flex-col items-center gap-4 sticky top-6">
        <p className="text-xs text-gray-500 uppercase tracking-widest font-semibold">Vista Previa Móvil</p>
        <MobilePreview
          name={form.name}
          leaderName={leaderName}
          day={form.meeting_day}
          time={form.meeting_time}
          address={form.address}
          description={form.description}
          status={form.status}
        />
        <p className="text-xs text-gray-600 text-center max-w-[200px]">
          Así aparecerá la célula en la app móvil de Génesis
        </p>
      </div>
    </div>
  );
};

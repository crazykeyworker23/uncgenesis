import React, { useEffect, useMemo, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Users,
  Clock,
  MapPin,
  Send,
  Bell,
  AlertCircle,
  CheckCircle2,
  Mail,
  Phone,
  CalendarDays,
  HeartHandshake,
  BarChart3,
  Plus,
  UserPlus,
  UserMinus,
  TrendingUp,
  FileText,
  Image as ImageIcon,
  X,
} from 'lucide-react';
import { apiClient } from '../api/client';
import { usePermissions } from '../store/authStore';
import { CellGroup, MEETING_DAY_LABELS } from '../features/cells/types';
import {
  ATTENDANCE_ORDER,
  ATTENDANCE_STATUS,
  AttendanceStatus,
  CellMeeting,
  CellStatistics,
  FOLLOW_UP_TYPES,
  FollowUp,
  FollowUpType,
  MembersResponse,
  CellReport,
  REPORT_STATUS,
  formatDate,
} from '../features/cells/management';

type Tab = 'members' | 'meetings' | 'followups' | 'reports' | 'stats';

/**
 * Vista de gestión de célula.
 *
 * Sirve a los tres niveles que tienen células a cargo: el líder ve la suya, el
 * coordinador elige entre las que supervisa y el pastorado entre todas. Las
 * acciones de escritura se ocultan cuando el alcance no las permite; el
 * servidor las vuelve a comprobar en cada petición.
 */
export const MyCell: React.FC = () => {
  const queryClient = useQueryClient();
  const { canManageCell, coordinatesCells, churchWide } = usePermissions();

  const [selectedCellId, setSelectedCellId] = useState<number | null>(null);
  const [tab, setTab] = useState<Tab>('members');
  const [feedback, setFeedback] = useState<{ type: 'ok' | 'error'; text: string } | null>(null);

  const { data: cellsResponse, isLoading: loadingCells } = useQuery<{
    scope: Record<string, unknown>;
    results: CellGroup[];
  }>({
    queryKey: ['my-cells'],
    queryFn: async () => (await apiClient.get('/cells/my-cells/')).data,
  });

  const cells = cellsResponse?.results ?? [];

  useEffect(() => {
    if (!selectedCellId && cells.length > 0) setSelectedCellId(cells[0].id);
  }, [cells, selectedCellId]);

  const selectedCell = cells.find((c) => c.id === selectedCellId);
  const canManage = canManageCell(selectedCellId);

  const { data: members } = useQuery<MembersResponse>({
    queryKey: ['cell-members', selectedCellId],
    queryFn: async () => (await apiClient.get(`/cells/${selectedCellId}/members/`)).data,
    enabled: Boolean(selectedCellId),
  });

  const { data: stats } = useQuery<CellStatistics>({
    queryKey: ['cell-stats', selectedCellId],
    queryFn: async () => (await apiClient.get(`/cells/${selectedCellId}/statistics/`)).data,
    enabled: Boolean(selectedCellId),
  });

  const notify = (type: 'ok' | 'error', text: string) => setFeedback({ type, text });

  const readError = (err: any, fallback: string) => {
    const data = err.response?.data;
    return (
      data?.error ||
      data?.detail ||
      (data && typeof data === 'object' ? Object.values(data).flat().join(' ') : fallback)
    );
  };

  const scopeTitle = churchWide
    ? 'Células de la iglesia'
    : coordinatesCells
      ? 'Células que coordino'
      : 'Mi Célula';

  if (loadingCells) {
    return <div className="p-8 text-center text-crema text-opacity-50 text-sm">Cargando…</div>;
  }

  if (cells.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-24 px-6 text-center">
        <div className="p-4 mb-5 rounded-full bg-dorado bg-opacity-10 border border-dorado border-opacity-20">
          <Users size={32} className="text-dorado" />
        </div>
        <h2 className="text-lg font-bold text-crema mb-2">Todavía no tienes células a cargo</h2>
        <p className="text-xs text-crema text-opacity-55 max-w-sm leading-relaxed">
          Cuando el equipo pastoral te asigne una célula, aquí verás a las personas
          a tu cargo, sus reuniones y su seguimiento.
        </p>
      </div>
    );
  }

  const tabs: Array<{ key: Tab; label: string; icon: typeof Users }> = [
    { key: 'members', label: 'Miembros', icon: Users },
    { key: 'meetings', label: 'Reuniones', icon: CalendarDays },
    { key: 'followups', label: 'Seguimiento', icon: HeartHandshake },
    { key: 'reports', label: 'Informes', icon: FileText },
    { key: 'stats', label: 'Estadísticas', icon: BarChart3 },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-extrabold text-crema">{scopeTitle}</h1>
        <p className="text-xs text-crema text-opacity-50 mt-1">
          Personas a cargo, reuniones, asistencia y seguimiento.
        </p>
      </div>

      {cells.length > 1 && (
        <div className="flex flex-wrap gap-2">
          {cells.map((cell) => (
            <button
              key={cell.id}
              onClick={() => {
                setSelectedCellId(cell.id);
                setFeedback(null);
              }}
              className={`px-4 py-2 rounded-xl text-xs font-semibold transition-all ${
                cell.id === selectedCellId
                  ? 'bg-dorado text-deep-teal'
                  : 'bg-white bg-opacity-5 text-crema text-opacity-70 hover:bg-opacity-10'
              }`}
            >
              {cell.name}
            </button>
          ))}
        </div>
      )}

      {selectedCell && (
        <div className="glass-panel p-5 grid grid-cols-1 sm:grid-cols-4 gap-4">
          <InfoTile icon={<Users size={16} />} label="Miembros" value={`${stats?.members_total ?? members?.count ?? 0}`} />
          <InfoTile
            icon={<Clock size={16} />}
            label="Reunión"
            value={`${MEETING_DAY_LABELS[selectedCell.meeting_day] ?? selectedCell.meeting_day} · ${String(selectedCell.meeting_time).slice(0, 5)}`}
          />
          <InfoTile icon={<CalendarDays size={16} />} label="Reuniones" value={`${stats?.meetings_total ?? 0}`} />
          <InfoTile icon={<MapPin size={16} />} label="Lugar" value={selectedCell.address} />
        </div>
      )}

      {feedback && (
        <div
          className={`flex items-start gap-2 p-3.5 rounded-xl text-xs border ${
            feedback.type === 'ok'
              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
              : 'bg-error-red bg-opacity-10 text-error-red border-error-red border-opacity-20'
          }`}
        >
          {feedback.type === 'ok' ? (
            <CheckCircle2 size={15} className="shrink-0 mt-px" />
          ) : (
            <AlertCircle size={15} className="shrink-0 mt-px" />
          )}
          <span>{feedback.text}</span>
        </div>
      )}

      {/* Pestañas */}
      <div className="flex flex-wrap gap-1 border-b border-white border-opacity-5">
        {tabs.map(({ key, label, icon: Icon }) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={`flex items-center gap-2 px-4 py-2.5 text-xs font-semibold border-b-2 -mb-px transition-all ${
              tab === key
                ? 'border-dorado text-dorado'
                : 'border-transparent text-crema text-opacity-50 hover:text-opacity-80'
            }`}
          >
            <Icon size={14} />
            {label}
          </button>
        ))}
      </div>

      {selectedCellId && tab === 'members' && (
        <MembersTab
          cellId={selectedCellId}
          members={members}
          canManage={canManage}
          onDone={(text) => {
            notify('ok', text);
            queryClient.invalidateQueries({ queryKey: ['cell-members', selectedCellId] });
            queryClient.invalidateQueries({ queryKey: ['cell-stats', selectedCellId] });
          }}
          onError={(err) => notify('error', readError(err, 'No pudimos completar la acción.'))}
        />
      )}

      {selectedCellId && tab === 'meetings' && (
        <MeetingsTab
          cellId={selectedCellId}
          members={members}
          canManage={canManage}
          onDone={(text) => {
            notify('ok', text);
            queryClient.invalidateQueries({ queryKey: ['cell-meetings', selectedCellId] });
            queryClient.invalidateQueries({ queryKey: ['cell-stats', selectedCellId] });
          }}
          onError={(err) => notify('error', readError(err, 'No pudimos guardar la reunión.'))}
        />
      )}

      {selectedCellId && tab === 'followups' && (
        <FollowUpsTab
          cellId={selectedCellId}
          members={members}
          canManage={canManage}
          onDone={(text) => {
            notify('ok', text);
            queryClient.invalidateQueries({ queryKey: ['cell-followups', selectedCellId] });
            queryClient.invalidateQueries({ queryKey: ['cell-stats', selectedCellId] });
          }}
          onError={(err) => notify('error', readError(err, 'No pudimos guardar el seguimiento.'))}
        />
      )}

      {selectedCellId && tab === 'reports' && (
        <ReportsTab
          cellId={selectedCellId}
          canManage={canManage}
          onDone={(text) => {
            notify('ok', text);
            queryClient.invalidateQueries({ queryKey: ['cell-reports', selectedCellId] });
          }}
          onError={(err) => notify('error', readError(err, 'No pudimos guardar el informe.'))}
        />
      )}

      {selectedCellId && tab === 'stats' && (
        <StatsTab
          cellId={selectedCellId}
          stats={stats}
          canManage={canManage}
          onDone={(text) => notify('ok', text)}
          onError={(err) => notify('error', readError(err, 'No pudimos enviar el recordatorio.'))}
        />
      )}
    </div>
  );
};

// ── Miembros ────────────────────────────────────────────────────────────────

interface TabProps {
  cellId: number;
  members?: MembersResponse;
  canManage: boolean;
  onDone: (text: string) => void;
  onError: (err: any) => void;
}

const MembersTab: React.FC<TabProps> = ({ cellId, members, canManage, onDone, onError }) => {
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ first_name: '', last_name: '', phone: '', email: '' });

  const register = useMutation({
    mutationFn: async () => apiClient.post(`/cells/${cellId}/register-member/`, form),
    onSuccess: (res) => {
      onDone(res.data.detail ?? 'Integrante registrado.');
      setForm({ first_name: '', last_name: '', phone: '', email: '' });
      setShowForm(false);
    },
    onError,
  });

  const remove = useMutation({
    mutationFn: async (memberId: number) =>
      apiClient.post(`/cells/${cellId}/remove-member/`, { member_id: memberId }),
    onSuccess: (res) => onDone(res.data.detail ?? 'Integrante retirado.'),
    onError,
  });

  return (
    <div className="space-y-4">
      {canManage && (
        <div className="flex justify-end">
          <button
            onClick={() => setShowForm((v) => !v)}
            className="flex items-center gap-2 btn-primary text-xs font-bold"
          >
            <UserPlus size={14} />
            {showForm ? 'Cancelar' : 'Registrar integrante'}
          </button>
        </div>
      )}

      {showForm && canManage && (
        <div className="glass-panel p-5 space-y-3">
          <h3 className="text-sm font-bold text-crema">Nuevo integrante o visitante</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <Field label="Nombre *" value={form.first_name} onChange={(v) => setForm({ ...form, first_name: v })} />
            <Field label="Apellido" value={form.last_name} onChange={(v) => setForm({ ...form, last_name: v })} />
            <Field label="Teléfono" value={form.phone} onChange={(v) => setForm({ ...form, phone: v })} />
            <Field label="Correo (opcional)" value={form.email} onChange={(v) => setForm({ ...form, email: v })} />
          </div>
          <p className="text-[10px] text-crema text-opacity-40">
            Si es un visitante sin correo, deja el campo vacío: queda registrado igualmente en la célula.
          </p>
          <button
            onClick={() => register.mutate()}
            disabled={register.isPending || !form.first_name.trim()}
            className="btn-primary text-xs font-bold disabled:opacity-40"
          >
            {register.isPending ? 'Guardando…' : 'Guardar integrante'}
          </button>
        </div>
      )}

      <div className="glass-panel p-5">
        {!members || members.count === 0 ? (
          <p className="text-xs text-crema text-opacity-45 py-8 text-center">
            Aún no hay personas asignadas a esta célula.
          </p>
        ) : (
          <ul className="divide-y divide-white divide-opacity-5">
            {members.results.map((member) => (
              <li key={member.id} className="py-3 flex items-center gap-3">
                <div className="w-9 h-9 rounded-full bg-dorado bg-opacity-15 flex items-center justify-center text-dorado text-xs font-bold shrink-0">
                  {(member.full_name || member.email).charAt(0).toUpperCase()}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-xs font-semibold text-crema truncate">{member.full_name || member.email}</p>
                  <div className="flex flex-wrap gap-x-4 mt-0.5">
                    <span className="text-[10px] text-crema text-opacity-45 flex items-center gap-1 truncate">
                      <Mail size={10} /> {member.email}
                    </span>
                    {member.phone && (
                      <span className="text-[10px] text-crema text-opacity-45 flex items-center gap-1">
                        <Phone size={10} /> {member.phone}
                      </span>
                    )}
                  </div>
                </div>
                <span
                  className={`text-[10px] px-2 py-0.5 rounded-full border shrink-0 ${
                    member.status === 'ACTIVE'
                      ? 'bg-emerald-500/15 text-emerald-400 border-emerald-500/25'
                      : 'bg-gray-500/15 text-gray-400 border-gray-500/25'
                  }`}
                >
                  {member.status === 'ACTIVE' ? 'Activo' : 'Inactivo'}
                </span>
                {canManage && (
                  <button
                    title="Retirar de la célula"
                    onClick={() => {
                      const name = member.full_name || member.email;
                      if (
                        window.confirm(
                          `¿Retirar a ${name} de la célula?\n\nDeja de pertenecer al grupo, pero conserva su cuenta y su historial de asistencia.`
                        )
                      ) {
                        remove.mutate(member.id);
                      }
                    }}
                    className="p-1.5 rounded-lg text-crema text-opacity-40 hover:text-error-red hover:bg-error-red hover:bg-opacity-10 transition-all shrink-0"
                  >
                    <UserMinus size={14} />
                  </button>
                )}
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
};

// ── Reuniones y asistencia ──────────────────────────────────────────────────

const MeetingsTab: React.FC<TabProps> = ({ cellId, members, canManage, onDone, onError }) => {
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ date: '', time: '', topic: '', notes: '', guests_count: '0' });
  const [openMeeting, setOpenMeeting] = useState<number | null>(null);
  const [marks, setMarks] = useState<Record<number, AttendanceStatus>>({});

  const { data: meetings } = useQuery<{ results: CellMeeting[] }>({
    queryKey: ['cell-meetings', cellId],
    queryFn: async () =>
      (await apiClient.get('/cell-meetings/', { params: { cell: cellId } })).data,
  });

  const createMeeting = useMutation({
    mutationFn: async () =>
      apiClient.post('/cell-meetings/', {
        cell: cellId,
        date: form.date,
        time: form.time || null,
        topic: form.topic,
        notes: form.notes,
        guests_count: Number(form.guests_count) || 0,
      }),
    onSuccess: () => {
      onDone('Reunión registrada.');
      setForm({ date: '', time: '', topic: '', notes: '', guests_count: '0' });
      setShowForm(false);
    },
    onError,
  });

  const saveAttendance = useMutation({
    mutationFn: async (meetingId: number) =>
      apiClient.post(`/cell-meetings/${meetingId}/attendance/`, {
        attendances: Object.entries(marks).map(([memberId, status]) => ({
          member_id: Number(memberId),
          status,
        })),
      }),
    onSuccess: (res) => {
      onDone(`Asistencia guardada: ${res.data.attendees_count} asistente(s).`);
      setOpenMeeting(null);
      setMarks({});
    },
    onError,
  });

  const openAttendance = (meeting: CellMeeting) => {
    const existing: Record<number, AttendanceStatus> = {};
    meeting.attendances.forEach((a) => {
      existing[a.member.id] = a.status;
    });
    (members?.results ?? []).forEach((m) => {
      if (!(m.id in existing)) existing[m.id] = 'PRESENT';
    });
    setMarks(existing);
    setOpenMeeting(meeting.id);
  };

  return (
    <div className="space-y-4">
      {canManage && (
        <div className="flex justify-end">
          <button
            onClick={() => setShowForm((v) => !v)}
            className="flex items-center gap-2 btn-primary text-xs font-bold"
          >
            <Plus size={14} />
            {showForm ? 'Cancelar' : 'Registrar reunión'}
          </button>
        </div>
      )}

      {showForm && canManage && (
        <div className="glass-panel p-5 space-y-3">
          <h3 className="text-sm font-bold text-crema">Nueva reunión</h3>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <Field label="Fecha *" type="date" value={form.date} onChange={(v) => setForm({ ...form, date: v })} />
            <Field label="Hora" type="time" value={form.time} onChange={(v) => setForm({ ...form, time: v })} />
            <Field
              label="Visitantes"
              type="number"
              value={form.guests_count}
              onChange={(v) => setForm({ ...form, guests_count: v })}
            />
          </div>
          <Field label="Tema tratado" value={form.topic} onChange={(v) => setForm({ ...form, topic: v })} />
          <Field
            label="Observaciones"
            value={form.notes}
            onChange={(v) => setForm({ ...form, notes: v })}
            multiline
          />
          <button
            onClick={() => createMeeting.mutate()}
            disabled={createMeeting.isPending || !form.date}
            className="btn-primary text-xs font-bold disabled:opacity-40"
          >
            {createMeeting.isPending ? 'Guardando…' : 'Guardar reunión'}
          </button>
        </div>
      )}

      {!meetings?.results?.length ? (
        <div className="glass-panel p-8 text-center text-xs text-crema text-opacity-45">
          Todavía no hay reuniones registradas en esta célula.
        </div>
      ) : (
        <div className="space-y-3">
          {meetings.results.map((meeting) => (
            <div key={meeting.id} className="glass-panel p-5">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="text-sm font-bold text-crema">{meeting.topic || 'Reunión de célula'}</p>
                  <p className="text-[11px] text-crema text-opacity-50 mt-0.5">
                    {formatDate(meeting.date)}
                    {meeting.time ? ` · ${meeting.time.slice(0, 5)}` : ''}
                  </p>
                  {meeting.notes && (
                    <p className="text-[11px] text-crema text-opacity-60 mt-2 leading-relaxed">{meeting.notes}</p>
                  )}
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <span className="text-[10px] px-2.5 py-1 rounded-full bg-dorado bg-opacity-15 text-dorado font-bold">
                    {meeting.attendees_count} asistentes
                  </span>
                  {canManage && (
                    <button
                      onClick={() => (openMeeting === meeting.id ? setOpenMeeting(null) : openAttendance(meeting))}
                      className="text-[10px] px-3 py-1.5 rounded-lg bg-white bg-opacity-5 hover:bg-opacity-10 text-crema font-semibold"
                    >
                      {openMeeting === meeting.id ? 'Cerrar' : 'Marcar asistencia'}
                    </button>
                  )}
                </div>
              </div>

              {/* Resumen de lo ya registrado */}
              {meeting.attendances.length > 0 && openMeeting !== meeting.id && (
                <div className="flex flex-wrap gap-1.5 mt-3 pt-3 border-t border-white border-opacity-5">
                  {meeting.attendances.map((a) => (
                    <span
                      key={a.id}
                      className={`text-[10px] px-2 py-0.5 rounded-full border ${ATTENDANCE_STATUS[a.status].classes}`}
                      title={`${a.member.full_name}: ${a.status_display}`}
                    >
                      {a.member.full_name?.split(' ')[0] || a.member.email} · {ATTENDANCE_STATUS[a.status].short}
                    </span>
                  ))}
                </div>
              )}

              {/* Marcado de asistencia */}
              {openMeeting === meeting.id && canManage && (
                <div className="mt-4 pt-4 border-t border-white border-opacity-5 space-y-2">
                  {(members?.results ?? []).length === 0 ? (
                    <p className="text-xs text-crema text-opacity-45">
                      Registra integrantes en la célula para poder marcar asistencia.
                    </p>
                  ) : (
                    <>
                      {(members?.results ?? []).map((member) => (
                        <div key={member.id} className="flex flex-wrap items-center gap-2 justify-between">
                          <span className="text-xs text-crema truncate flex-1 min-w-[8rem]">
                            {member.full_name || member.email}
                          </span>
                          <div className="flex gap-1">
                            {ATTENDANCE_ORDER.map((statusKey) => {
                              const active = marks[member.id] === statusKey;
                              return (
                                <button
                                  key={statusKey}
                                  onClick={() => setMarks({ ...marks, [member.id]: statusKey })}
                                  className={`text-[10px] px-2.5 py-1 rounded-lg border font-semibold transition-all ${
                                    active
                                      ? ATTENDANCE_STATUS[statusKey].classes
                                      : 'bg-white bg-opacity-5 text-crema text-opacity-45 border-transparent hover:bg-opacity-10'
                                  }`}
                                >
                                  {ATTENDANCE_STATUS[statusKey].label}
                                </button>
                              );
                            })}
                          </div>
                        </div>
                      ))}
                      <button
                        onClick={() => saveAttendance.mutate(meeting.id)}
                        disabled={saveAttendance.isPending}
                        className="btn-primary text-xs font-bold mt-3 disabled:opacity-40"
                      >
                        {saveAttendance.isPending ? 'Guardando…' : 'Guardar asistencia'}
                      </button>
                    </>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

// ── Seguimiento ─────────────────────────────────────────────────────────────

const FollowUpsTab: React.FC<TabProps> = ({ cellId, members, canManage, onDone, onError }) => {
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    member_id: '',
    type: 'CALL' as FollowUpType,
    date: '',
    summary: '',
    needs_attention: false,
  });

  const { data: followUps } = useQuery<{ results: FollowUp[] }>({
    queryKey: ['cell-followups', cellId],
    queryFn: async () =>
      (await apiClient.get('/cell-follow-ups/', { params: { cell: cellId } })).data,
  });

  const create = useMutation({
    mutationFn: async () =>
      apiClient.post('/cell-follow-ups/', {
        cell: cellId,
        member_id: Number(form.member_id),
        type: form.type,
        date: form.date,
        summary: form.summary,
        needs_attention: form.needs_attention,
      }),
    onSuccess: () => {
      onDone('Seguimiento registrado.');
      setForm({ member_id: '', type: 'CALL', date: '', summary: '', needs_attention: false });
      setShowForm(false);
    },
    onError,
  });

  return (
    <div className="space-y-4">
      {canManage && (
        <div className="flex justify-end">
          <button
            onClick={() => setShowForm((v) => !v)}
            className="flex items-center gap-2 btn-primary text-xs font-bold"
          >
            <Plus size={14} />
            {showForm ? 'Cancelar' : 'Registrar seguimiento'}
          </button>
        </div>
      )}

      {showForm && canManage && (
        <div className="glass-panel p-5 space-y-3">
          <h3 className="text-sm font-bold text-crema">Contacto o visita realizada</h3>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="space-y-1.5">
              <label className="block text-[10px] font-semibold text-crema text-opacity-65 ml-1">Persona *</label>
              <select
                value={form.member_id}
                onChange={(e) => setForm({ ...form, member_id: e.target.value })}
                className="w-full px-3.5 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl text-white text-xs focus:outline-none focus:border-dorado"
              >
                <option value="" className="bg-gray-900">Selecciona…</option>
                {(members?.results ?? []).map((m) => (
                  <option key={m.id} value={m.id} className="bg-gray-900">
                    {m.full_name || m.email}
                  </option>
                ))}
              </select>
            </div>
            <div className="space-y-1.5">
              <label className="block text-[10px] font-semibold text-crema text-opacity-65 ml-1">Tipo</label>
              <select
                value={form.type}
                onChange={(e) => setForm({ ...form, type: e.target.value as FollowUpType })}
                className="w-full px-3.5 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl text-white text-xs focus:outline-none focus:border-dorado"
              >
                {Object.entries(FOLLOW_UP_TYPES).map(([key, label]) => (
                  <option key={key} value={key} className="bg-gray-900">{label}</option>
                ))}
              </select>
            </div>
            <Field label="Fecha *" type="date" value={form.date} onChange={(v) => setForm({ ...form, date: v })} />
          </div>
          <Field
            label="Resumen *"
            value={form.summary}
            onChange={(v) => setForm({ ...form, summary: v })}
            multiline
          />
          <label className="flex items-center gap-2 text-[11px] text-crema text-opacity-70 cursor-pointer">
            <input
              type="checkbox"
              checked={form.needs_attention}
              onChange={(e) => setForm({ ...form, needs_attention: e.target.checked })}
              className="accent-dorado w-3.5 h-3.5"
            />
            Requiere seguimiento cercano
          </label>
          <button
            onClick={() => create.mutate()}
            disabled={create.isPending || !form.member_id || !form.date || !form.summary.trim()}
            className="btn-primary text-xs font-bold disabled:opacity-40"
          >
            {create.isPending ? 'Guardando…' : 'Guardar seguimiento'}
          </button>
        </div>
      )}

      {!followUps?.results?.length ? (
        <div className="glass-panel p-8 text-center text-xs text-crema text-opacity-45">
          Todavía no hay seguimientos registrados.
        </div>
      ) : (
        <div className="space-y-3">
          {followUps.results.map((item) => (
            <div key={item.id} className="glass-panel p-4">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="text-xs font-bold text-crema">{item.member.full_name || item.member.email}</p>
                  <p className="text-[10px] text-dorado mt-0.5">
                    {item.type_display} · {formatDate(item.date)}
                  </p>
                  <p className="text-[11px] text-crema text-opacity-65 mt-2 leading-relaxed">{item.summary}</p>
                </div>
                {item.needs_attention && (
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/40 shrink-0">
                    Atención
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

// ── Informes de actividad ───────────────────────────────────────────────────

interface ReportsTabProps {
  cellId: number;
  canManage: boolean;
  onDone: (text: string) => void;
  onError: (err: any) => void;
}

/**
 * Informes que el líder envía sobre cómo le fue con su célula.
 *
 * Quien lidera redacta y envía; quien supervisa lee y responde. Un informe
 * enviado queda cerrado, para que lo que se revisa sea lo que se entregó.
 */
const ReportsTab: React.FC<ReportsTabProps> = ({ cellId, canManage, onDone, onError }) => {
  const { can } = usePermissions();
  const canWrite = canManage && can('CELL_REPORTS_CREATE');
  const canReview = can('CELL_REPORTS_REVIEW');

  const [showForm, setShowForm] = useState(false);
  const [answering, setAnswering] = useState<number | null>(null);
  const [answer, setAnswer] = useState('');
  const [photo, setPhoto] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [zoom, setZoom] = useState<string | null>(null);
  const [form, setForm] = useState({
    period_start: '',
    period_end: '',
    summary: '',
    highlights: '',
    challenges: '',
    prayer_needs: '',
    photo_caption: '',
  });

  const EMPTY = {
    period_start: '', period_end: '', summary: '',
    highlights: '', challenges: '', prayer_needs: '', photo_caption: '',
  };

  const { data: reports } = useQuery<{ results: CellReport[] }>({
    queryKey: ['cell-reports', cellId],
    queryFn: async () => (await apiClient.get('/cell-reports/', { params: { cell: cellId } })).data,
  });

  const pickPhoto = (file: File | null) => {
    setPhoto(file);
    if (photoPreview) URL.revokeObjectURL(photoPreview);
    setPhotoPreview(file ? URL.createObjectURL(file) : null);
  };

  const create = useMutation({
    mutationFn: async () => {
      // Con imagen la petición va como formulario; sin ella, como JSON.
      if (!photo) {
        return apiClient.post('/cell-reports/', { cell: cellId, ...form });
      }
      const data = new FormData();
      data.append('cell', String(cellId));
      Object.entries(form).forEach(([key, value]) => data.append(key, value));
      data.append('photo', photo);
      return apiClient.post('/cell-reports/', data, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    },
    onSuccess: () => {
      onDone('Informe guardado como borrador. Revísalo y envíalo cuando esté listo.');
      setForm(EMPTY);
      pickPhoto(null);
      setShowForm(false);
    },
    onError,
  });

  const send = useMutation({
    mutationFn: async (id: number) => apiClient.post(`/cell-reports/${id}/send/`),
    onSuccess: () => onDone('Informe enviado a tu supervisión.'),
    onError,
  });

  const review = useMutation({
    mutationFn: async (id: number) =>
      apiClient.post(`/cell-reports/${id}/review/`, { review_notes: answer.trim() }),
    onSuccess: () => {
      onDone('Informe revisado.');
      setAnswering(null);
      setAnswer('');
    },
    onError,
  });

  return (
    <div className="space-y-4">
      {canWrite && (
        <div className="flex justify-end">
          <button
            onClick={() => setShowForm((v) => !v)}
            className="flex items-center gap-2 btn-primary text-xs font-bold"
          >
            <Plus size={14} />
            {showForm ? 'Cancelar' : 'Nuevo informe'}
          </button>
        </div>
      )}

      {showForm && canWrite && (
        <div className="glass-panel p-5 space-y-3">
          <h3 className="text-sm font-bold text-crema">¿Cómo le fue a tu célula?</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <Field label="Desde *" type="date" value={form.period_start} onChange={(v) => setForm({ ...form, period_start: v })} />
            <Field label="Hasta *" type="date" value={form.period_end} onChange={(v) => setForm({ ...form, period_end: v })} />
          </div>
          <Field label="Resumen del periodo *" value={form.summary} onChange={(v) => setForm({ ...form, summary: v })} multiline />
          <Field label="Lo más destacado" value={form.highlights} onChange={(v) => setForm({ ...form, highlights: v })} multiline />
          <Field label="Dificultades" value={form.challenges} onChange={(v) => setForm({ ...form, challenges: v })} multiline />
          <Field label="Motivos de oración" value={form.prayer_needs} onChange={(v) => setForm({ ...form, prayer_needs: v })} multiline />

          {/* Foto de la actividad: al coordinador le dice más que el texto */}
          <div className="space-y-2">
            <label className="block text-[10px] font-semibold text-crema text-opacity-65 ml-1">
              Foto de la actividad (opcional)
            </label>

            {photoPreview ? (
              <div className="relative inline-block">
                <img
                  src={photoPreview}
                  alt="Vista previa"
                  className="max-h-48 rounded-xl border border-white border-opacity-10"
                />
                <button
                  onClick={() => pickPhoto(null)}
                  title="Quitar la foto"
                  className="absolute -top-2 -right-2 p-1.5 rounded-full bg-error-red text-white shadow-lg"
                >
                  <X size={12} />
                </button>
              </div>
            ) : (
              <label className="flex flex-col items-center justify-center gap-2 px-4 py-6 border border-dashed border-white border-opacity-15 rounded-xl cursor-pointer hover:border-dorado hover:border-opacity-50 transition-all">
                <ImageIcon size={22} className="text-crema text-opacity-35" />
                <span className="text-[11px] text-crema text-opacity-50">
                  Toca para elegir una imagen de la reunión
                </span>
                <input
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={(e) => pickPhoto(e.target.files?.[0] ?? null)}
                />
              </label>
            )}

            {photo && (
              <Field
                label="Pie de foto"
                value={form.photo_caption}
                onChange={(v) => setForm({ ...form, photo_caption: v })}
              />
            )}
          </div>

          <p className="text-[10px] text-crema text-opacity-40">
            Las cifras del periodo (reuniones, asistencia media e integrantes nuevos) se calculan
            solas al enviar el informe.
          </p>
          <button
            onClick={() => create.mutate()}
            disabled={create.isPending || !form.period_start || !form.period_end || !form.summary.trim()}
            className="btn-primary text-xs font-bold disabled:opacity-40"
          >
            {create.isPending ? 'Guardando…' : 'Guardar borrador'}
          </button>
        </div>
      )}

      {!reports?.results?.length ? (
        <div className="glass-panel p-10 text-center">
          <FileText size={32} className="text-dorado mx-auto mb-3 opacity-60" />
          <p className="text-sm font-bold text-crema mb-1.5">Todavía no hay informes</p>
          <p className="text-xs text-crema text-opacity-50 max-w-md mx-auto leading-relaxed">
            {canWrite
              ? 'Usa "Nuevo informe" para contar cómo le fue a tu célula en el periodo. Se guarda como borrador y lo envías cuando esté listo; las cifras de reuniones y asistencia se calculan solas.'
              : canReview
                ? 'Cuando el líder envíe su informe del periodo, aparecerá aquí para que lo leas y respondas.'
                : 'Tu rol no redacta ni revisa informes de esta célula.'}
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {reports.results.map((report) => (
            <div key={report.id} className="glass-panel p-5 space-y-3">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <p className="text-sm font-bold text-crema">
                    {formatDate(report.period_start)} — {formatDate(report.period_end)}
                  </p>
                  {report.submitted_by && (
                    <p className="text-[10px] text-crema text-opacity-45 mt-0.5">
                      Por {report.submitted_by.full_name || report.submitted_by.email}
                    </p>
                  )}
                </div>
                <span className={`text-[10px] px-2.5 py-1 rounded-full border ${REPORT_STATUS[report.status].classes}`}>
                  {REPORT_STATUS[report.status].label}
                </span>
              </div>

              {/* El informe ya no lleva cifras adjuntas: no las leía nadie y,
                  desde que se informa de un solo día, salían casi siempre en
                  cero. Los indicadores vivos están en la pestaña de
                  estadísticas de la célula. */}
              <div className="space-y-2 text-[11px] leading-relaxed">
                <Block title="Resumen" text={report.summary} />
                <Block title="Lo destacado" text={report.highlights} />
                <Block title="Dificultades" text={report.challenges} />
                <Block title="Motivos de oración" text={report.prayer_needs} />
              </div>

              {/* La foto de la actividad, tal como la ve quien revisa */}
              {report.photo_url && (
                <div className="space-y-1.5">
                  <button
                    onClick={() => setZoom(report.photo_url)}
                    className="block w-full rounded-xl overflow-hidden border border-white border-opacity-10 hover:border-dorado hover:border-opacity-40 transition-all"
                    title="Ampliar"
                  >
                    <img
                      src={report.photo_url}
                      alt={report.photo_caption || 'Foto de la actividad'}
                      className="w-full max-h-72 object-cover"
                      loading="lazy"
                    />
                  </button>
                  {report.photo_caption && (
                    <p className="text-[10px] text-crema text-opacity-45 italic text-center">
                      {report.photo_caption}
                    </p>
                  )}
                </div>
              )}

              {report.review_notes && (
                <div className="p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20">
                  <p className="text-[10px] font-bold text-emerald-400 mb-1">
                    Respuesta de {report.reviewed_by?.full_name || 'la supervisión'}
                  </p>
                  <p className="text-[11px] text-crema text-opacity-80">{report.review_notes}</p>
                </div>
              )}

              <div className="flex flex-wrap gap-2 pt-1">
                {report.status === 'DRAFT' && canWrite && (
                  <button
                    onClick={() => send.mutate(report.id)}
                    disabled={send.isPending}
                    className="flex items-center gap-2 btn-primary text-xs font-bold disabled:opacity-40"
                  >
                    <Send size={13} />
                    Enviar informe
                  </button>
                )}

                {report.status === 'SENT' && canReview && (
                  <button
                    onClick={() => setAnswering(answering === report.id ? null : report.id)}
                    className="text-[11px] px-3 py-2 rounded-lg bg-white bg-opacity-5 hover:bg-opacity-10 text-crema font-semibold"
                  >
                    {answering === report.id ? 'Cancelar' : 'Responder informe'}
                  </button>
                )}
              </div>

              {answering === report.id && canReview && (
                <div className="space-y-2 pt-1">
                  <textarea
                    rows={3}
                    value={answer}
                    onChange={(e) => setAnswer(e.target.value)}
                    placeholder="Tu respuesta al líder…"
                    className="w-full px-3.5 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl text-white placeholder-crema placeholder-opacity-30 text-xs focus:outline-none focus:border-dorado resize-none"
                  />
                  <button
                    onClick={() => review.mutate(report.id)}
                    disabled={review.isPending}
                    className="btn-primary text-xs font-bold disabled:opacity-40"
                  >
                    {review.isPending ? 'Guardando…' : 'Marcar como revisado'}
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Visor ampliado: las fotos de una reunión suelen tener detalle que se
          pierde en miniatura. */}
      {zoom && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-80 p-6"
          onClick={() => setZoom(null)}
        >
          <button
            onClick={() => setZoom(null)}
            className="absolute top-5 right-5 p-2 rounded-full bg-white bg-opacity-10 text-white hover:bg-opacity-20"
            title="Cerrar"
          >
            <X size={18} />
          </button>
          <img
            src={zoom}
            alt="Foto de la actividad"
            className="max-h-full max-w-full rounded-xl object-contain"
            onClick={(e) => e.stopPropagation()}
          />
        </div>
      )}
    </div>
  );
};

function Block({ title, text }: { title: string; text: string }) {
  if (!text) return null;
  return (
    <div>
      <p className="text-[10px] font-bold text-dorado uppercase tracking-wide">{title}</p>
      <p className="text-crema text-opacity-75 mt-0.5 whitespace-pre-line">{text}</p>
    </div>
  );
}

// ── Estadísticas y comunicados ──────────────────────────────────────────────

interface StatsTabProps {
  cellId: number;
  stats?: CellStatistics;
  canManage: boolean;
  onDone: (text: string) => void;
  onError: (err: any) => void;
}

const StatsTab: React.FC<StatsTabProps> = ({ cellId, stats, canManage, onDone, onError }) => {
  const [reminder, setReminder] = useState('');

  const send = useMutation({
    mutationFn: async () => apiClient.post(`/cells/${cellId}/send-reminder/`, { body: reminder.trim() }),
    onSuccess: (res) => {
      onDone(res.data.detail ?? 'Recordatorio enviado.');
      setReminder('');
    },
    onError,
  });

  const maxAttendees = useMemo(
    () => Math.max(1, ...(stats?.attendance_trend ?? []).map((p) => p.attendees)),
    [stats]
  );

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div className="lg:col-span-2 space-y-4">
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <StatTile label="Activos" value={stats?.members_active ?? 0} tone="text-emerald-400" />
          <StatTile label="Inactivos" value={stats?.members_inactive ?? 0} tone="text-gray-400" />
          <StatTile label="Asistencia media" value={stats?.average_attendance ?? 0} tone="text-dorado" />
          <StatTile label="Requieren atención" value={stats?.needs_attention ?? 0} tone="text-amber-400" />
        </div>

        <div className="glass-panel p-5">
          <h3 className="text-sm font-bold text-crema mb-4 flex items-center gap-2">
            <TrendingUp size={15} className="text-dorado" />
            Evolución de asistencia
          </h3>
          {!stats?.attendance_trend?.length ? (
            <p className="text-xs text-crema text-opacity-45 py-6 text-center">
              Registra reuniones para ver la evolución.
            </p>
          ) : (
            <div className="flex items-end gap-2 h-40">
              {stats.attendance_trend.map((point) => (
                <div key={point.date} className="flex-1 flex flex-col items-center gap-1.5 min-w-0">
                  <span className="text-[10px] text-dorado font-bold">{point.attendees}</span>
                  <div
                    className="w-full bg-dorado bg-opacity-70 rounded-t"
                    style={{ height: `${(point.attendees / maxAttendees) * 100}%`, minHeight: '3px' }}
                    title={`${point.topic || 'Reunión'} · ${point.attendees} asistentes`}
                  />
                  <span className="text-[9px] text-crema text-opacity-40 truncate w-full text-center">
                    {point.date.slice(5)}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="glass-panel p-5">
          <h3 className="text-sm font-bold text-crema mb-3">Asistencia por estado</h3>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {ATTENDANCE_ORDER.map((key) => (
              <div key={key} className={`p-3 rounded-xl border ${ATTENDANCE_STATUS[key].classes}`}>
                <p className="text-[10px] opacity-80">{ATTENDANCE_STATUS[key].label}</p>
                <p className="text-lg font-extrabold mt-0.5">{stats?.attendance_by_status?.[key] ?? 0}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {canManage && (
        <div className="glass-panel p-5 h-fit">
          <h3 className="text-sm font-bold text-crema mb-1 flex items-center gap-2">
            <Bell size={15} className="text-dorado" />
            Enviar comunicado
          </h3>
          <p className="text-[10px] text-crema text-opacity-45 mb-4 leading-relaxed">
            Llega como notificación únicamente a los miembros de esta célula.
          </p>
          <textarea
            rows={4}
            value={reminder}
            onChange={(e) => setReminder(e.target.value)}
            placeholder="Recuerden nuestra reunión de mañana a las 19:30."
            className="w-full px-3.5 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl text-white placeholder-crema placeholder-opacity-30 text-xs focus:outline-none focus:border-dorado resize-none"
          />
          <button
            onClick={() => send.mutate()}
            disabled={send.isPending || !reminder.trim()}
            className="flex items-center justify-center gap-2 w-full btn-primary text-xs font-bold mt-3 disabled:opacity-40"
          >
            <Send size={14} />
            {send.isPending ? 'Enviando…' : 'Enviar comunicado'}
          </button>
        </div>
      )}
    </div>
  );
};

// ── Auxiliares ──────────────────────────────────────────────────────────────

function InfoTile({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-center gap-3">
      <div className="p-2 rounded-lg bg-dorado bg-opacity-10 shrink-0 text-dorado">{icon}</div>
      <div className="min-w-0">
        <p className="text-[10px] text-crema text-opacity-45 uppercase tracking-wide">{label}</p>
        <p className="text-xs font-semibold text-crema truncate">{value}</p>
      </div>
    </div>
  );
}

function StatTile({ label, value, tone }: { label: string; value: number | string; tone: string }) {
  return (
    <div className="glass-panel p-4">
      <p className="text-[10px] text-crema text-opacity-45 uppercase tracking-wide">{label}</p>
      <p className={`text-2xl font-extrabold mt-1 ${tone}`}>{value}</p>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  type = 'text',
  multiline = false,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
  multiline?: boolean;
}) {
  const className =
    'w-full px-3.5 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl text-white placeholder-crema placeholder-opacity-30 text-xs focus:outline-none focus:border-dorado transition-all';

  return (
    <div className="space-y-1.5">
      <label className="block text-[10px] font-semibold text-crema text-opacity-65 ml-1">{label}</label>
      {multiline ? (
        <textarea rows={3} value={value} onChange={(e) => onChange(e.target.value)} className={`${className} resize-none`} />
      ) : (
        <input type={type} value={value} onChange={(e) => onChange(e.target.value)} className={className} />
      )}
    </div>
  );
}

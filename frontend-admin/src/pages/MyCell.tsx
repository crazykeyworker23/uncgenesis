import React, { useEffect, useState } from 'react';
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
} from 'lucide-react';
import { apiClient } from '../api/client';
import { CellGroup, MEETING_DAY_LABELS } from '../features/cells/types';

interface CellMember {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone: string;
  location: string;
  status: string;
  avatar: string | null;
}

interface MembersResponse {
  cell: { id: number; name: string; slug: string };
  count: number;
  results: CellMember[];
}

/**
 * Vista propia del líder de célula.
 *
 * Reúne lo que su rol necesita hacer: ver quiénes están a su cargo y enviarles
 * un recordatorio de la reunión. Sólo alcanza a la célula que lidera.
 */
export const MyCell: React.FC = () => {
  const queryClient = useQueryClient();
  const [selectedCellId, setSelectedCellId] = useState<number | null>(null);
  const [reminderBody, setReminderBody] = useState('');
  const [reminderTitle, setReminderTitle] = useState('');
  const [feedback, setFeedback] = useState<{ type: 'ok' | 'error'; text: string } | null>(null);

  const { data: cells, isLoading: loadingCells } = useQuery<CellGroup[]>({
    queryKey: ['my-cells'],
    queryFn: async () => (await apiClient.get('/cells/my-cells/')).data,
  });

  // Selecciona la primera célula en cuanto llegan los datos.
  useEffect(() => {
    if (!selectedCellId && cells && cells.length > 0) {
      setSelectedCellId(cells[0].id);
    }
  }, [cells, selectedCellId]);

  const { data: members, isLoading: loadingMembers } = useQuery<MembersResponse>({
    queryKey: ['cell-members', selectedCellId],
    queryFn: async () => (await apiClient.get(`/cells/${selectedCellId}/members/`)).data,
    enabled: Boolean(selectedCellId),
  });

  const sendReminder = useMutation({
    mutationFn: async () => {
      const payload: Record<string, string> = { body: reminderBody.trim() };
      if (reminderTitle.trim()) payload.title = reminderTitle.trim();
      return apiClient.post(`/cells/${selectedCellId}/send-reminder/`, payload);
    },
    onSuccess: (res) => {
      setFeedback({ type: 'ok', text: res.data.detail ?? 'Recordatorio enviado.' });
      setReminderBody('');
      setReminderTitle('');
      queryClient.invalidateQueries({ queryKey: ['cell-members', selectedCellId] });
    },
    onError: (err: any) => {
      const data = err.response?.data;
      const text =
        data?.error ||
        data?.detail ||
        (typeof data === 'object' && data
          ? Object.values(data).flat().join(' ')
          : 'No pudimos enviar el recordatorio.');
      setFeedback({ type: 'error', text });
    },
  });

  const selectedCell = cells?.find((c) => c.id === selectedCellId);

  if (loadingCells) {
    return <div className="p-8 text-center text-crema text-opacity-50 text-sm">Cargando tu célula…</div>;
  }

  if (!cells || cells.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-24 px-6 text-center">
        <div className="p-4 mb-5 rounded-full bg-dorado bg-opacity-10 border border-dorado border-opacity-20">
          <Users size={32} className="text-dorado" />
        </div>
        <h2 className="text-lg font-bold text-crema mb-2">Todavía no lideras ninguna célula</h2>
        <p className="text-xs text-crema text-opacity-55 max-w-sm leading-relaxed">
          Cuando el equipo pastoral te asigne una célula, aquí verás a las personas
          a tu cargo y podrás enviarles recordatorios.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Encabezado */}
      <div>
        <h1 className="text-2xl font-extrabold text-crema">Mi Célula</h1>
        <p className="text-xs text-crema text-opacity-50 mt-1">
          Las personas a tu cargo y los recordatorios que les envías.
        </p>
      </div>

      {/* Selector cuando lidera más de una */}
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

      {/* Datos de la célula */}
      {selectedCell && (
        <div className="glass-panel p-5 grid grid-cols-1 sm:grid-cols-3 gap-4">
          <InfoTile
            icon={<Users size={16} className="text-dorado" />}
            label="Personas a tu cargo"
            value={`${members?.count ?? 0}`}
          />
          <InfoTile
            icon={<Clock size={16} className="text-dorado" />}
            label="Reunión"
            value={`${MEETING_DAY_LABELS[selectedCell.meeting_day] ?? selectedCell.meeting_day} · ${String(
              selectedCell.meeting_time
            ).slice(0, 5)}`}
          />
          <InfoTile
            icon={<MapPin size={16} className="text-dorado" />}
            label="Lugar"
            value={selectedCell.address}
          />
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Miembros */}
        <div className="lg:col-span-2 glass-panel p-5">
          <h2 className="text-sm font-bold text-crema mb-4 flex items-center gap-2">
            <Users size={16} className="text-dorado" />
            Miembros de la célula
          </h2>

          {loadingMembers ? (
            <p className="text-xs text-crema text-opacity-45 py-6 text-center">Cargando miembros…</p>
          ) : !members || members.count === 0 ? (
            <p className="text-xs text-crema text-opacity-45 py-8 text-center leading-relaxed">
              Aún no hay personas asignadas a esta célula.
              <br />
              El equipo pastoral las asigna al resolver las solicitudes de visita.
            </p>
          ) : (
            <ul className="divide-y divide-white divide-opacity-5">
              {members.results.map((member) => (
                <li key={member.id} className="py-3 flex items-center gap-3">
                  <div className="w-9 h-9 rounded-full bg-dorado bg-opacity-15 flex items-center justify-center text-dorado text-xs font-bold shrink-0">
                    {(member.full_name || member.email).charAt(0).toUpperCase()}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-xs font-semibold text-crema truncate">
                      {member.full_name || member.email}
                    </p>
                    <div className="flex flex-wrap gap-x-4 gap-y-0.5 mt-0.5">
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
                    {member.status === 'ACTIVE' ? 'Activo' : member.status}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </div>

        {/* Recordatorio */}
        <div className="glass-panel p-5 h-fit">
          <h2 className="text-sm font-bold text-crema mb-1 flex items-center gap-2">
            <Bell size={16} className="text-dorado" />
            Enviar recordatorio
          </h2>
          <p className="text-[10px] text-crema text-opacity-45 mb-4 leading-relaxed">
            Llega como notificación únicamente a los miembros de esta célula.
          </p>

          {feedback && (
            <div
              className={`flex items-start gap-2 p-3 mb-4 rounded-xl text-[11px] border ${
                feedback.type === 'ok'
                  ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                  : 'bg-error-red bg-opacity-10 text-error-red border-error-red border-opacity-20'
              }`}
            >
              {feedback.type === 'ok' ? (
                <CheckCircle2 size={14} className="shrink-0 mt-px" />
              ) : (
                <AlertCircle size={14} className="shrink-0 mt-px" />
              )}
              <span>{feedback.text}</span>
            </div>
          )}

          <div className="space-y-3">
            <div className="space-y-1.5">
              <label htmlFor="reminder-title" className="block text-[10px] font-semibold text-crema text-opacity-65 ml-1">
                Título (opcional)
              </label>
              <input
                id="reminder-title"
                type="text"
                value={reminderTitle}
                onChange={(e) => setReminderTitle(e.target.value)}
                placeholder={selectedCell ? `Recordatorio de ${selectedCell.name}` : 'Recordatorio'}
                className="w-full px-3.5 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl text-white placeholder-crema placeholder-opacity-30 text-xs focus:outline-none focus:border-dorado transition-all"
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="reminder-body" className="block text-[10px] font-semibold text-crema text-opacity-65 ml-1">
                Mensaje *
              </label>
              <textarea
                id="reminder-body"
                rows={4}
                value={reminderBody}
                onChange={(e) => setReminderBody(e.target.value)}
                placeholder="Recuerden nuestra reunión de mañana a las 19:30 en la dirección de siempre."
                className="w-full px-3.5 py-2.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl text-white placeholder-crema placeholder-opacity-30 text-xs focus:outline-none focus:border-dorado transition-all resize-none"
              />
            </div>

            <button
              onClick={() => {
                setFeedback(null);
                sendReminder.mutate();
              }}
              disabled={sendReminder.isPending || !reminderBody.trim() || !members?.count}
              className="flex items-center justify-center gap-2 w-full btn-primary text-xs font-bold disabled:opacity-40 disabled:cursor-not-allowed"
            >
              {sendReminder.isPending ? (
                <div className="w-4 h-4 border-2 border-deep-teal border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <Send size={14} />
                  Enviar a {members?.count ?? 0} miembro{members?.count === 1 ? '' : 's'}
                </>
              )}
            </button>

            {!members?.count && (
              <p className="text-[10px] text-crema text-opacity-40 text-center leading-relaxed">
                Necesitas al menos un miembro asignado para enviar recordatorios.
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

function InfoTile({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-center gap-3">
      <div className="p-2 rounded-lg bg-dorado bg-opacity-10 shrink-0">{icon}</div>
      <div className="min-w-0">
        <p className="text-[10px] text-crema text-opacity-45 uppercase tracking-wide">{label}</p>
        <p className="text-xs font-semibold text-crema truncate">{value}</p>
      </div>
    </div>
  );
}

import React, { useEffect, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { ArrowLeft, CalendarDays, Save, Send, CheckCircle2, AlertCircle, Loader2 } from 'lucide-react';
import { apiClient } from '../api/client';
import { usePermissions } from '../store/authStore';
import { Can } from '../components/auth/Can';

/**
 * Plan de lecturas de la semana.
 *
 * La iglesia reparte cada semana una imagen con siete pasajes, uno por día.
 * Cargarlos aquí eran siete formularios largos —título, pasaje, el texto
 * bíblico completo y una reflexión cada uno—, así que en la práctica no se
 * cargaban. Esta pantalla pide lo justo: el pasaje y unas líneas.
 *
 * Se guarda como borrador. Los avisos de las 7:00 no salen hasta publicar, de
 * modo que un error de dedo no manda siete notificaciones equivocadas.
 */

interface PlanDay {
  date: string;
  weekday: string;
  id: number | null;
  bible_passage: string;
  content: string;
  status: string | null;
}

interface WeeklyPlan {
  start_date: string;
  end_date: string;
  days: PlanDay[];
  detail?: string;
}

/** El lunes de la semana que contiene esa fecha. */
function mondayOf(date: Date): string {
  const copy = new Date(date);
  const day = copy.getDay(); // 0 domingo … 6 sábado
  const diff = day === 0 ? -6 : 1 - day;
  copy.setDate(copy.getDate() + diff);
  return copy.toISOString().slice(0, 10);
}

export const DevotionalWeeklyPlan: React.FC = () => {
  const queryClient = useQueryClient();
  const { can } = usePermissions();

  const [startDate, setStartDate] = useState(() => mondayOf(new Date()));
  const [days, setDays] = useState<PlanDay[]>([]);
  const [feedback, setFeedback] = useState<{ type: 'ok' | 'error'; text: string } | null>(null);

  const { data, isLoading } = useQuery<WeeklyPlan>({
    queryKey: ['devotional-weekly-plan', startDate],
    queryFn: async () =>
      (await apiClient.get('/devotionals/weekly-plan/', { params: { start_date: startDate } })).data,
  });

  // Al cambiar de semana se recarga lo que ya hubiera cargado, para poder
  // corregirlo en lugar de escribirlo de nuevo.
  useEffect(() => {
    if (data?.days) setDays(data.days);
  }, [data]);

  const published = days.some((d) => d.status && d.status !== 'DRAFT');
  const complete = days.length === 7 && days.every((d) => d.bible_passage.trim() && d.content.trim());

  const readError = (err: any, fallback: string) =>
    err.response?.data?.error || err.response?.data?.detail || fallback;

  const save = useMutation({
    mutationFn: async () =>
      apiClient.post('/devotionals/weekly-plan/', {
        start_date: startDate,
        days: days.map((d) => ({ bible_passage: d.bible_passage, content: d.content })),
      }),
    onSuccess: () => {
      setFeedback({ type: 'ok', text: 'Plan guardado como borrador. Revísalo y publícalo cuando esté listo.' });
      queryClient.invalidateQueries({ queryKey: ['devotional-weekly-plan'] });
    },
    onError: (err) => setFeedback({ type: 'error', text: readError(err, 'No pudimos guardar el plan.') }),
  });

  const publish = useMutation({
    mutationFn: async () =>
      apiClient.post('/devotionals/weekly-plan/publish/', { start_date: startDate }),
    onSuccess: (res) => {
      setFeedback({ type: 'ok', text: res.data.detail ?? 'Plan publicado.' });
      queryClient.invalidateQueries({ queryKey: ['devotional-weekly-plan'] });
    },
    onError: (err) => setFeedback({ type: 'error', text: readError(err, 'No pudimos publicar el plan.') }),
  });

  const update = (index: number, field: 'bible_passage' | 'content', value: string) => {
    setDays((current) =>
      current.map((day, i) => (i === index ? { ...day, [field]: value } : day)),
    );
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <Link
            to="/devocionales"
            className="inline-flex items-center gap-1.5 text-[11px] text-crema text-opacity-50 hover:text-dorado mb-2"
          >
            <ArrowLeft size={13} /> Devocionales
          </Link>
          <h1 className="text-2xl font-extrabold text-crema leading-none">Plan semanal</h1>
          <p className="text-xs text-crema text-opacity-50 mt-1.5">
            Los siete pasajes de la semana. Cada día avisará a su gente a las 7:00 de la mañana.
          </p>
        </div>

        <div className="flex items-center gap-2 self-start sm:self-center">
          <CalendarDays size={16} className="text-dorado" />
          <input
            type="date"
            value={startDate}
            onChange={(e) => {
              // Siempre el lunes: el plan cubre la semana entera.
              setStartDate(mondayOf(new Date(`${e.target.value}T12:00:00`)));
              setFeedback(null);
            }}
            className="bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-3 py-2 text-xs text-crema"
          />
        </div>
      </div>

      {data && (
        <p className="text-xs text-crema text-opacity-45">
          Semana del {data.start_date} al {data.end_date}
        </p>
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

      {published && (
        <div className="flex items-start gap-2 p-3.5 rounded-xl text-xs border bg-dorado bg-opacity-10 text-dorado border-dorado border-opacity-20">
          <AlertCircle size={15} className="shrink-0 mt-px" />
          <span>
            Esta semana ya tiene días publicados. Para cambiarlos, entra a cada devocional desde
            el listado: así no se sobrescribe lo que la gente ya recibió.
          </span>
        </div>
      )}

      {isLoading ? (
        <div className="flex items-center justify-center p-12 text-crema/40 text-xs">
          <Loader2 className="animate-spin mr-2" size={16} /> Cargando la semana…
        </div>
      ) : (
        <div className="space-y-3">
          {days.map((day, index) => (
            <div key={day.date} className="glass-panel p-4 bg-dark-teal bg-opacity-20">
              <div className="grid grid-cols-1 md:grid-cols-[110px_1fr] gap-3 items-start">
                <div className="pt-2">
                  <p className="text-xs font-bold text-dorado uppercase tracking-wide">
                    {day.weekday}
                  </p>
                  <p className="text-[10px] text-crema text-opacity-40 mt-0.5">{day.date}</p>
                </div>

                <div className="space-y-2">
                  <input
                    value={day.bible_passage}
                    onChange={(e) => update(index, 'bible_passage', e.target.value)}
                    placeholder="Pasaje a leer. Ej. Hebreos 13"
                    disabled={published}
                    className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-3 py-2 text-sm text-crema placeholder:text-crema/30 disabled:opacity-50"
                  />
                  <textarea
                    value={day.content}
                    onChange={(e) => update(index, 'content', e.target.value)}
                    placeholder="Unas líneas sobre la lectura"
                    rows={2}
                    disabled={published}
                    className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-3 py-2 text-xs text-crema placeholder:text-crema/30 disabled:opacity-50"
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {!published && (
        <div className="flex flex-col sm:flex-row items-center justify-end gap-3">
          {!complete && (
            <p className="text-[11px] text-crema text-opacity-40 mr-auto">
              Completa el pasaje y las líneas de los siete días para poder guardar.
            </p>
          )}

          <button
            onClick={() => save.mutate()}
            disabled={!complete || save.isPending}
            className="flex items-center justify-center gap-2 btn-secondary text-xs font-bold disabled:opacity-40"
          >
            {save.isPending ? <Loader2 className="animate-spin" size={15} /> : <Save size={15} />}
            Guardar borrador
          </button>

          <Can permission="DEVOTIONALS_PUBLISH">
            <button
              onClick={() => publish.mutate()}
              disabled={!days.some((d) => d.id) || publish.isPending}
              className="flex items-center justify-center gap-2 btn-primary text-xs font-bold disabled:opacity-40"
              title={
                days.some((d) => d.id)
                  ? 'Publica los siete días y programa sus avisos'
                  : 'Guarda el plan antes de publicarlo'
              }
            >
              {publish.isPending ? <Loader2 className="animate-spin" size={15} /> : <Send size={15} />}
              Publicar la semana
            </button>
          </Can>
        </div>
      )}

      {!can('DEVOTIONALS_PUBLISH') && !published && (
        <p className="text-[11px] text-crema text-opacity-40 text-right">
          Tu rol puede dejarlo cargado; publicarlo le corresponde a quien tiene ese permiso.
        </p>
      )}
    </div>
  );
};

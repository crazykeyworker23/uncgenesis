import React, { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  ArrowLeft,
  CalendarDays,
  CheckCircle2,
  AlertCircle,
  Loader2,
  BookOpen,
  Users,
  ImageOff,
} from 'lucide-react';
import { apiClient } from '../api/client';
import { usePermissions } from '../store/authStore';
import { CellGroup } from '../features/cells/types';
import {
  CellReport,
  REPORT_STATUS,
  reportImages,
  formatDate,
} from '../features/cells/management';

/**
 * Los devocionales que entrega cada líder, semana a semana.
 *
 * La iglesia publica un plan de lecturas y cada célula lo sigue; el líder
 * manda desde el teléfono el día leído y su captura. Aquí se ve quién
 * entregó y quién no, que es la pregunta que se hace quien publica el plan.
 *
 * Lo que se ve depende del alcance de cada quien: el pastorado ve a todos sus
 * líderes, el coordinador sólo los de las células que supervisa y el líder los
 * suyos. No hay que filtrar nada en pantalla: el servidor ya recorta la lista
 * a lo que corresponde.
 */

/** El lunes de la semana que contiene esa fecha. */
function mondayOf(date: Date): string {
  const copy = new Date(date);
  const day = copy.getDay(); // 0 domingo … 6 sábado
  copy.setDate(copy.getDate() + (day === 0 ? -6 : 1 - day));
  return copy.toISOString().slice(0, 10);
}

function addDays(iso: string, days: number): string {
  const date = new Date(`${iso}T12:00:00`);
  date.setDate(date.getDate() + days);
  return date.toISOString().slice(0, 10);
}

const WEEKDAYS = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

/** Qué día de la semana cae esa fecha, para ordenarlos de lunes a domingo. */
function weekdayLabel(iso: string): string {
  const day = new Date(`${iso}T12:00:00`).getDay();
  return WEEKDAYS[day === 0 ? 6 : day - 1];
}

/** Lo entregado por una persona en la semana. */
interface LeaderRow {
  key: string;
  name: string;
  cells: string;
  reports: CellReport[];
}

export const DevotionalLeaderReports: React.FC = () => {
  const queryClient = useQueryClient();
  const { can } = usePermissions();

  const [monday, setMonday] = useState(() => mondayOf(new Date()));
  const [soloEntregados, setSoloEntregados] = useState(true);
  const [answering, setAnswering] = useState<number | null>(null);
  const [answer, setAnswer] = useState('');
  const [zoom, setZoom] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ type: 'ok' | 'error'; text: string } | null>(null);

  const sunday = addDays(monday, 6);

  const { data, isLoading } = useQuery<{ results: CellReport[]; count: number }>({
    queryKey: ['devotional-reports', monday],
    queryFn: async () =>
      (
        await apiClient.get('/cell-reports/', {
          params: {
            kind: 'DEVOTIONAL',
            period_start__gte: monday,
            period_start__lte: sunday,
            // La semana entera de todas las células cabe de sobra; de a diez
            // habría que ir pasando páginas para leer una sola semana.
            page_size: 100,
          },
        })
      ).data,
  });

  // Las células que la persona alcanza, para poder decir quién no entregó.
  // Sin esto sólo se vería a los cumplidores, que es justo lo que no hace
  // falta revisar.
  const { data: cellsResponse } = useQuery<{ results: CellGroup[] }>({
    queryKey: ['my-cells'],
    queryFn: async () => (await apiClient.get('/cells/my-cells/')).data,
  });

  const reports = useMemo(() => {
    const todos = data?.results ?? [];
    // Un borrador todavía no se ha entregado: contarlo como cumplido daría
    // por buena una semana que el líder aún no cerró.
    return soloEntregados ? todos.filter((r) => r.status !== 'DRAFT') : todos;
  }, [data, soloEntregados]);

  const porLider = useMemo<LeaderRow[]>(() => {
    const filas = new Map<string, LeaderRow>();

    for (const report of reports) {
      const persona = report.submitted_by;
      const key = persona ? `u${persona.id}` : `c${report.cell}`;
      const fila = filas.get(key) ?? {
        key,
        name: persona?.full_name || persona?.email || 'Sin identificar',
        cells: report.cell_name,
        reports: [],
      };
      if (!fila.cells.includes(report.cell_name)) fila.cells += `, ${report.cell_name}`;
      fila.reports.push(report);
      filas.set(key, fila);
    }

    for (const fila of filas.values()) {
      fila.reports.sort((a, b) => a.period_start.localeCompare(b.period_start));
    }

    return [...filas.values()].sort((a, b) => b.reports.length - a.reports.length);
  }, [reports]);

  const sinEntregar = useMemo(() => {
    const cells = cellsResponse?.results ?? [];
    const conEntrega = new Set(reports.map((r) => r.cell));
    return cells.filter((cell) => !conEntrega.has(cell.id));
  }, [cellsResponse, reports]);

  const review = useMutation({
    mutationFn: async (id: number) =>
      apiClient.post(`/cell-reports/${id}/review/`, { review_notes: answer.trim() }),
    onSuccess: () => {
      setFeedback({ type: 'ok', text: 'Respuesta enviada al líder.' });
      setAnswering(null);
      setAnswer('');
      queryClient.invalidateQueries({ queryKey: ['devotional-reports'] });
    },
    onError: (err: any) =>
      setFeedback({
        type: 'error',
        text: err.response?.data?.error || 'No pudimos guardar la respuesta.',
      }),
  });

  const canReview = can('CELL_REPORTS_REVIEW');

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
          <h1 className="text-2xl font-extrabold text-crema leading-none">
            Devocionales de los líderes
          </h1>
          <p className="text-xs text-crema text-opacity-50 mt-1.5">
            Lo que cada líder reportó de la semana, con su captura. Sólo aparecen las células
            que te corresponden.
          </p>
        </div>

        <div className="flex items-center gap-2 self-start sm:self-center">
          <CalendarDays size={16} className="text-dorado" />
          <input
            type="date"
            value={monday}
            onChange={(e) => {
              // Siempre el lunes: se revisa la semana completa.
              setMonday(mondayOf(new Date(`${e.target.value}T12:00:00`)));
              setFeedback(null);
            }}
            className="bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-3 py-2 text-xs text-crema"
          />
        </div>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3">
        <p className="text-xs text-crema text-opacity-45">
          Semana del {formatDate(monday)} al {formatDate(sunday)}
        </p>
        <label className="flex items-center gap-2 text-[11px] text-crema text-opacity-60 cursor-pointer">
          <input
            type="checkbox"
            checked={soloEntregados}
            onChange={(e) => setSoloEntregados(e.target.checked)}
            className="accent-dorado"
          />
          Sólo los ya entregados
        </label>
      </div>

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

      {isLoading ? (
        <div className="glass-panel p-10 flex items-center justify-center text-xs text-crema text-opacity-50">
          <Loader2 className="animate-spin mr-2" size={16} /> Cargando la semana…
        </div>
      ) : porLider.length === 0 ? (
        <div className="glass-panel p-10 text-center">
          <BookOpen size={32} className="text-dorado mx-auto mb-3 opacity-60" />
          <p className="text-sm font-bold text-crema mb-1.5">
            Nadie ha reportado el devocional de esta semana
          </p>
          <p className="text-xs text-crema text-opacity-50 max-w-md mx-auto leading-relaxed">
            Los líderes lo envían desde la app, en Informes → Reporte del devocional. Aquí
            aparecerá el día leído y la captura de cada uno.
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {porLider.map((fila) => (
            <div key={fila.key} className="glass-panel p-5 space-y-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="text-sm font-bold text-crema">{fila.name}</p>
                  <p className="text-[10px] text-crema text-opacity-45 mt-0.5 flex items-center gap-1.5">
                    <Users size={11} /> {fila.cells}
                  </p>
                </div>
                <span className="text-[10px] px-2.5 py-1 rounded-full border bg-dorado/15 text-dorado border-dorado/40">
                  {fila.reports.length} de 7 días
                </span>
              </div>

              <div className="space-y-3">
                {fila.reports.map((report) => {
                  const imagenes = reportImages(report);
                  return (
                    <div
                      key={report.id}
                      className="p-3.5 rounded-xl bg-white bg-opacity-[0.03] border border-white border-opacity-5 space-y-2.5"
                    >
                      <div className="flex flex-wrap items-start justify-between gap-2">
                        <p className="text-[11px] font-bold text-dorado">
                          {weekdayLabel(report.period_start)} · {formatDate(report.period_start)}
                        </p>
                        <span
                          className={`text-[10px] px-2 py-0.5 rounded-full border ${REPORT_STATUS[report.status].classes}`}
                        >
                          {REPORT_STATUS[report.status].label}
                        </span>
                      </div>

                      <p className="text-[11px] text-crema text-opacity-80 leading-relaxed">
                        {report.summary}
                      </p>

                      {imagenes.length > 0 ? (
                        <div className="flex flex-wrap gap-2">
                          {imagenes.map((url, index) => (
                            <button
                              key={url}
                              onClick={() => setZoom(url)}
                              title="Ampliar"
                              className="rounded-lg overflow-hidden border border-white border-opacity-10 hover:border-dorado hover:border-opacity-40 transition-all"
                            >
                              <img
                                src={url}
                                alt={`Captura ${index + 1} de ${fila.name}`}
                                className="h-24 w-24 object-cover"
                                loading="lazy"
                              />
                            </button>
                          ))}
                        </div>
                      ) : (
                        <p className="flex items-center gap-1.5 text-[10px] text-crema text-opacity-35">
                          <ImageOff size={11} /> Sin captura adjunta
                        </p>
                      )}

                      {report.review_notes && (
                        <div className="p-2.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20">
                          <p className="text-[10px] font-bold text-emerald-400 mb-0.5">
                            Respuesta de {report.reviewed_by?.full_name || 'la supervisión'}
                          </p>
                          <p className="text-[11px] text-crema text-opacity-80">
                            {report.review_notes}
                          </p>
                        </div>
                      )}

                      {canReview && report.status === 'SENT' && (
                        <div className="space-y-2">
                          <button
                            onClick={() => {
                              setAnswering(answering === report.id ? null : report.id);
                              setAnswer('');
                            }}
                            className="text-[11px] px-3 py-1.5 rounded-lg bg-white bg-opacity-5 hover:bg-opacity-10 text-crema font-semibold"
                          >
                            {answering === report.id ? 'Cancelar' : 'Responder'}
                          </button>

                          {answering === report.id && (
                            <div className="space-y-2">
                              <textarea
                                rows={3}
                                value={answer}
                                onChange={(e) => setAnswer(e.target.value)}
                                placeholder="Unas líneas para el líder…"
                                className="w-full bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl px-3 py-2 text-xs text-crema"
                              />
                              <button
                                onClick={() => review.mutate(report.id)}
                                disabled={review.isPending || !answer.trim()}
                                className="btn-primary text-xs font-bold disabled:opacity-40"
                              >
                                {review.isPending ? 'Enviando…' : 'Enviar respuesta'}
                              </button>
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}

      {sinEntregar.length > 0 && (
        <div className="glass-panel p-5">
          <p className="text-[10px] font-bold text-crema text-opacity-65 mb-3">
            SIN REPORTAR ESTA SEMANA ({sinEntregar.length})
          </p>
          <div className="flex flex-wrap gap-2">
            {sinEntregar.map((cell) => (
              <span
                key={cell.id}
                className="text-[11px] px-3 py-1.5 rounded-lg bg-white bg-opacity-5 text-crema text-opacity-70"
              >
                {cell.name}
                {cell.leader && (
                  <span className="text-crema text-opacity-40"> · {cell.leader.full_name}</span>
                )}
              </span>
            ))}
          </div>
        </div>
      )}

      {zoom && (
        <div
          className="fixed inset-0 z-50 bg-black bg-opacity-80 flex items-center justify-center p-6"
          onClick={() => setZoom(null)}
        >
          <img src={zoom} alt="Captura del devocional" className="max-h-full max-w-full rounded-xl" />
        </div>
      )}
    </div>
  );
};

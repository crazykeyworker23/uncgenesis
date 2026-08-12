import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/leader_models.dart';
import '../providers/leader_providers.dart';
import '../widgets/leader_widgets.dart';

/// Inicio de quien lidera o coordina una célula.
///
/// Sustituye al inicio de miembro porque su primera pregunta al abrir la
/// aplicación no es qué se predicó el domingo, sino qué le falta hacer con su
/// gente. Responde a eso: las cifras de su célula, lo que quedó pendiente y
/// las dos acciones que más repite.
///
/// La gestión completa vive en la pestaña «Mi Célula»; aquí sólo está lo que
/// reclama atención hoy. Y lo de la iglesia sigue a mano al final, porque el
/// líder tambien es miembro.
class LeaderDashboardPage extends ConsumerWidget {
  const LeaderDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final myCells = ref.watch(myCellsProvider);
    final cell = ref.watch(activeCellProvider);

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.dorado,
          backgroundColor: AppColors.cardColor,
          onRefresh: () async {
            ref.invalidate(myCellsProvider);
            if (cell != null) {
              ref.invalidate(cellStatisticsProvider(cell.id));
              await ref.read(cellMeetingsProvider(cell.id).notifier).refresh();
              await ref.read(cellReportsProvider(cell.id).notifier).refresh();
            }
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _Greeting(name: user?.firstName ?? user?.fullName ?? ''),
              const SizedBox(height: 22),

              if (myCells.isLoading && cell == null)
                const LeaderLoading()
              else if (myCells.hasError && cell == null)
                LeaderErrorState(
                  message: ApiError.message(
                    myCells.error,
                    fallback: 'No pudimos cargar tu célula.',
                  ),
                  onRetry: () => ref.invalidate(myCellsProvider),
                )
              else if (cell == null)
                const LeaderEmptyState(
                  icon: Icons.groups_outlined,
                  title: 'Todavía no tienes una célula a tu cargo',
                  message: 'Cuando el pastorado te asigne una, aparecerá aquí.',
                )
              else ...[
                _CellSummary(cell: cell),
                const SizedBox(height: 16),
                _PendingWork(cellId: cell.id),
                const SizedBox(height: 16),
                _QuickActions(cellId: cell.id),
                const SizedBox(height: 12),
                _OpenFullSection(cellName: cell.name),
              ],

              const SizedBox(height: 30),
              const _ChurchShortcuts(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;

  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.trim().isEmpty ? greeting : '$greeting, ${name.trim()}',
          style: AppTextStyles.displayMedium.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 4),
        Text(
          'Esto es lo que pasa con tu célula.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.crema.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

/// Identidad de la célula y sus cifras.
class _CellSummary extends ConsumerWidget {
  final LeaderCell cell;

  const _CellSummary({required this.cell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(cellStatisticsProvider(cell.id));
    final schedule = [
      if (cell.dayLabel.isNotEmpty) cell.dayLabel,
      if (cell.meetingTime.isNotEmpty) DateFormatter.clockTime(cell.meetingTime),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dorado.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: AppColors.dorado, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cell.name,
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.doradoClaro),
                    ),
                    if (schedule.isNotEmpty)
                      Text(
                        schedule,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.crema.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          stats.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(color: AppColors.dorado)),
            ),
            error: (_, __) => Text(
              'No pudimos calcular las cifras ahora mismo.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
            data: (data) => Row(
              children: [
                _Figure(label: 'Activos', value: '${data.membersActive}'),
                _Figure(label: 'Reuniones', value: '${data.meetingsTotal}'),
                _Figure(label: 'Media', value: _trim(data.averageAttendance)),
                _Figure(
                  label: 'Atención',
                  value: '${data.needsAttention}',
                  tone: data.needsAttention > 0 ? AppColors.warning : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _trim(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final Color? tone;

  const _Figure({required this.label, required this.value, this.tone});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: tone ?? AppColors.dorado,
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.crema.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que quedó a medias.
///
/// Se calcula con lo que ya se pidió al servidor para el resto de la pantalla,
/// y sólo aparece cuando hay algo que decir: un bloque vacío que anuncia que
/// no pasa nada ocupa sitio y no ayuda.
class _PendingWork extends ConsumerWidget {
  final int cellId;

  const _PendingWork({required this.cellId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetings = ref.watch(cellMeetingsProvider(cellId));
    final reports = ref.watch(cellReportsProvider(cellId));
    final stats = ref.watch(cellStatisticsProvider(cellId)).valueOrNull;

    final pendingRollCall = _latestWithoutAttendance(meetings.items);
    final draft = _firstDraft(reports.items);
    final needsAttention = stats?.needsAttention ?? 0;

    final items = <Widget>[
      if (pendingRollCall != null)
        _PendingRow(
          icon: Icons.how_to_reg_outlined,
          tone: AppColors.warning,
          text: 'La reunión del ${DateFormatter.shortDate(pendingRollCall.date)} '
              'está sin lista pasada.',
          action: 'PASAR LISTA',
          onTap: () => context.push('/leader/meetings/${pendingRollCall.id}/attendance'),
        ),
      if (draft != null)
        _PendingRow(
          icon: Icons.description_outlined,
          tone: AppColors.doradoClaro,
          text: 'Tienes un informe en borrador sin enviar.',
          action: 'VER',
          onTap: () => context.push('/leader/reports'),
        ),
      if (needsAttention > 0)
        _PendingRow(
          icon: Icons.favorite_border,
          tone: AppColors.warning,
          text: needsAttention == 1
              ? 'Una persona de tu célula necesita atención cercana.'
              : '$needsAttention personas de tu célula necesitan atención cercana.',
          action: 'VER',
          onTap: () => context.push('/leader/follow-ups'),
        ),
    ];

    if (items.isEmpty) {
      // Nada pendiente tambien es una noticia, pero se dice en una linea.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 19),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                'Tu célula está al día. No hay nada pendiente.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.crema.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LeaderSectionLabel('Pendiente'),
        for (var i = 0; i < items.length; i++) ...[
          items[i],
          if (i != items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// La reunión más reciente en la que todavía no se pasó lista.
  ///
  /// La lista llega ordenada de más nueva a más antigua, así que la primera
  /// que aparezca sin asistencia es la que toca.
  static CellMeeting? _latestWithoutAttendance(List<CellMeeting> meetings) {
    for (final meeting in meetings) {
      if (!meeting.hasAttendance) return meeting;
    }
    return null;
  }

  static CellReport? _firstDraft(List<CellReport> reports) {
    for (final report in reports) {
      if (report.isDraft) return report;
    }
    return null;
  }
}

class _PendingRow extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final String text;
  final String action;
  final VoidCallback onTap;

  const _PendingRow({
    required this.icon,
    required this.tone,
    required this.text,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: tone, width: 3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: tone, size: 19),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.crema.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                action,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.dorado,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Las dos cosas que un líder repite cada semana.
class _QuickActions extends ConsumerWidget {
  final int cellId;

  const _QuickActions({required this.cellId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canManageActiveCellProvider)) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.how_to_reg_outlined,
            label: 'Pasar lista',
            onTap: () => context.push('/leader/meetings'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.campaign_outlined,
            label: 'Enviar aviso',
            onTap: () => context.push('/leader/announce'),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dorado,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.deepTeal, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenFullSection extends StatelessWidget {
  final String cellName;

  const _OpenFullSection({required this.cellName});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go('/leader'),
      child: Text(
        'Ver todo lo de $cellName  →',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.dorado,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Lo de la iglesia que no tiene pestaña propia para el líder.
///
/// Al cambiar «Conectar» por «Mi Célula» en la barra, estos accesos se
/// quedarían sin puerta: aquí la tienen, y el líder sigue siendo miembro.
class _ChurchShortcuts extends StatelessWidget {
  const _ChurchShortcuts();

  @override
  Widget build(BuildContext context) {
    const shortcuts = [
      (Icons.menu_book_outlined, 'Devocionales', '/devotionals'),
      (Icons.church_outlined, 'Servicios', '/services'),
      (Icons.people_outline, 'Células', '/cells'),
      (Icons.volunteer_activism_outlined, 'Oración', '/connect/prayer'),
      (Icons.chat_bubble_outline, 'Contacto', '/connect/visitor'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LeaderSectionLabel('De la iglesia'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            for (final (icon, label, route) in shortcuts)
              _ChurchTile(icon: icon, label: label, route: route),
          ],
        ),
      ],
    );
  }
}

class _ChurchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _ChurchTile({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardColor.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.dorado, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

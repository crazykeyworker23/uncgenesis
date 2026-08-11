import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/api_error.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/leader_providers.dart';
import '../widgets/leader_widgets.dart';

/// Punto de entrada de la gestión de célula desde el teléfono.
///
/// Reúne lo que el líder hacía sólo desde el panel web: quién compone su
/// célula, qué reuniones se hicieron y con cuánta asistencia, a quién se dio
/// seguimiento, qué se informó a la supervisión y qué avisos se enviaron.
class LeaderHomePage extends ConsumerWidget {
  const LeaderHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final myCells = ref.watch(myCellsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Célula')),
      body: !auth.isAuthenticated
          ? const _NeedsSession()
          : myCells.when(
              loading: () => const LeaderLoading(),
              error: (error, _) => LeaderErrorState(
                message: ApiError.message(
                  error,
                  fallback: 'No pudimos cargar tu célula.',
                ),
                onRetry: () => ref.invalidate(myCellsProvider),
              ),
              data: (data) => data.cells.isEmpty
                  ? const LeaderEmptyState(
                      icon: Icons.groups_outlined,
                      title: 'Todavía no tienes una célula a tu cargo',
                      message:
                          'Cuando el pastorado te asigne una, aparecerá aquí con sus miembros, '
                          'sus reuniones y sus informes.',
                    )
                  : const _CellDashboard(),
            ),
    );
  }
}

class _CellDashboard extends ConsumerWidget {
  const _CellDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cell = ref.watch(activeCellProvider);
    if (cell == null) return const LeaderLoading();

    final user = ref.watch(authProvider).user;
    final canManage = ref.watch(canManageActiveCellProvider);
    final stats = ref.watch(cellStatisticsProvider(cell.id));
    final members = ref.watch(cellMembersProvider(cell.id));

    return RefreshIndicator(
      color: AppColors.dorado,
      backgroundColor: AppColors.cardColor,
      onRefresh: () async {
        ref.invalidate(myCellsProvider);
        ref.invalidate(cellStatisticsProvider(cell.id));
        ref.invalidate(cellMembersProvider(cell.id));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const LeaderCellHeader(),
          const SizedBox(height: 20),

          const LeaderSectionLabel('Cómo va tu célula'),
          stats.when(
            loading: () => const SizedBox(
              height: 90,
              child: Center(child: CircularProgressIndicator(color: AppColors.dorado)),
            ),
            error: (error, _) => Text(
              ApiError.message(error, fallback: 'No pudimos calcular los indicadores.'),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
            data: (data) => GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.86,
              children: [
                LeaderStatTile(label: 'Activos', value: '${data.membersActive}'),
                LeaderStatTile(label: 'Reuniones', value: '${data.meetingsTotal}'),
                LeaderStatTile(
                  label: 'Asistencia\nmedia',
                  value: _trim(data.averageAttendance),
                ),
                LeaderStatTile(
                  label: 'Requieren\natención',
                  value: '${data.needsAttention}',
                  tone: data.needsAttention > 0 ? AppColors.warning : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const LeaderSectionLabel('Gestión'),
          LeaderSectionTile(
            icon: Icons.people_alt_outlined,
            title: 'Miembros',
            subtitle: canManage
                ? 'Consulta, da de alta y retira integrantes'
                : 'Quiénes componen la célula',
            badge: members.valueOrNull == null ? null : '${members.value!.length}',
            onTap: () => context.push('/leader/members'),
          ),
          const SizedBox(height: 10),
          LeaderSectionTile(
            icon: Icons.event_available_outlined,
            title: 'Reuniones y asistencia',
            subtitle: canManage
                ? 'Registra la reunión y pasa lista'
                : 'Historial de reuniones de la célula',
            badge: stats.valueOrNull == null ? null : '${stats.value!.meetingsTotal}',
            onTap: () => context.push('/leader/meetings'),
          ),
          const SizedBox(height: 10),
          LeaderSectionTile(
            icon: Icons.volunteer_activism_outlined,
            title: 'Seguimientos',
            subtitle: 'Llamadas, visitas y quién necesita atención',
            onTap: () => context.push('/leader/follow-ups'),
          ),
          const SizedBox(height: 10),
          LeaderSectionTile(
            icon: Icons.description_outlined,
            title: 'Informes de actividad',
            subtitle: canManage
                ? 'Cuenta cómo te fue y envíalo a tu supervisión'
                : 'Informes recibidos de esta célula',
            onTap: () => context.push('/leader/reports'),
          ),

          if (canManage) ...[
            const SizedBox(height: 24),
            const LeaderSectionLabel('Comunicación'),
            LeaderSectionTile(
              icon: Icons.campaign_outlined,
              title: 'Enviar un aviso',
              subtitle: 'Llega al teléfono de tu célula, aunque tengan la app cerrada',
              onTap: () => context.push('/leader/announce'),
            ),
          ],

          if (!canManage) ...[
            const SizedBox(height: 20),
            _ReadOnlyNotice(scopeLabel: user?.scope.label),
          ],
        ],
      ),
    );
  }

  /// `4.0` se lee peor que `4`; las medias enteras se muestran sin decimal.
  static String _trim(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }
}

/// Aviso para quien supervisa la célula sin poder escribir en ella.
class _ReadOnlyNotice extends StatelessWidget {
  final String? scopeLabel;

  const _ReadOnlyNotice({this.scopeLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.visibility_outlined, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Estás viendo esta célula en modo consulta. Registrar reuniones, asistencia o '
              'avisos le corresponde a quien la lidera.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La sección exige sesión iniciada: al líder se le entregan sus credenciales.
class _NeedsSession extends StatelessWidget {
  const _NeedsSession();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 58, color: AppColors.dorado),
            const SizedBox(height: 16),
            Text(
              'Inicia sesión para gestionar tu célula',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.doradoClaro),
            ),
            const SizedBox(height: 8),
            Text(
              'Usa las credenciales que te entregó la iglesia.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.crema.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => context.push('/auth/login'),
              child: const Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

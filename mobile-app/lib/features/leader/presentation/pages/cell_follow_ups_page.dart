import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/leader_models.dart';
import '../providers/leader_providers.dart';
import '../widgets/leader_widgets.dart';

/// Seguimiento pastoral: llamadas, visitas y quién necesita atención cercana.
class CellFollowUpsPage extends ConsumerWidget {
  const CellFollowUpsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cell = ref.watch(activeCellProvider);
    if (cell == null) {
      return const LeaderMissingCellScaffold(title: 'Seguimientos');
    }

    final user = ref.watch(authProvider).user;
    final canManage = ref.watch(canManageActiveCellProvider);
    final canCreate = canManage && (user?.can('FOLLOWUPS_CREATE') ?? false);
    final state = ref.watch(cellFollowUpsProvider(cell.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimientos'),
        bottom: leaderCellSubtitle(cell.name),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.dorado,
              foregroundColor: AppColors.deepTeal,
              onPressed: () => _openSheet(context, ref, cell.id, cell.name),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('ANOTAR', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: Builder(
        builder: (context) {
          if (state.isLoadingFirstPage) return const LeaderLoading();

          if (state.errorMessage != null && state.items.isEmpty) {
            return LeaderErrorState(
              message: state.errorMessage!,
              onRetry: () => ref.read(cellFollowUpsProvider(cell.id).notifier).refresh(),
            );
          }

          if (state.isEmpty) {
            return LeaderEmptyState(
              icon: Icons.volunteer_activism_outlined,
              title: 'Todavía no hay seguimientos anotados',
              message: canCreate
                  ? 'Deja constancia de las llamadas y visitas que haces: así no se pierde de '
                      'vista a nadie.'
                  : 'Aquí aparecerán los contactos que registre quien lidera la célula.',
            );
          }

          return RefreshIndicator(
            color: AppColors.dorado,
            backgroundColor: AppColors.cardColor,
            onRefresh: () => ref.read(cellFollowUpsProvider(cell.id).notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.dorado))
                        : TextButton(
                            onPressed: () =>
                                ref.read(cellFollowUpsProvider(cell.id).notifier).loadMore(),
                            child: const Text('VER MÁS',
                                style: TextStyle(color: AppColors.dorado)),
                          ),
                  );
                }

                final followUp = state.items[index];
                return _FollowUpCard(
                  followUp: followUp,
                  onDelete: canCreate
                      ? () => _confirmDelete(context, ref, cell.id, followUp)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    int cellId,
    String cellName,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowUpFormSheet(cellId: cellId, cellName: cellName),
    );

    if (saved != true || !context.mounted) return;
    await ref.read(cellFollowUpsProvider(cellId).notifier).refresh();
    ref.invalidate(cellStatisticsProvider(cellId));
    if (context.mounted) showLeaderMessage(context, 'Seguimiento anotado.');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int cellId,
    MemberFollowUp followUp,
  ) async {
    final confirmed = await confirmLeaderAction(
      context,
      title: 'Borrar el seguimiento',
      message: 'Se borrará lo anotado sobre ${followUp.member.fullName}. No se puede deshacer.',
      confirmLabel: 'BORRAR',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(leaderRepositoryProvider).deleteFollowUp(followUp.id);
      await ref.read(cellFollowUpsProvider(cellId).notifier).refresh();
      ref.invalidate(cellStatisticsProvider(cellId));
      if (context.mounted) showLeaderMessage(context, 'Seguimiento borrado.');
    } catch (error) {
      if (context.mounted) {
        showLeaderMessage(
          context,
          ApiError.message(error, fallback: 'No pudimos borrar el seguimiento.'),
          isError: true,
        );
      }
    }
  }
}

class _FollowUpCard extends StatelessWidget {
  final MemberFollowUp followUp;
  final VoidCallback? onDelete;

  const _FollowUpCard({required this.followUp, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LeaderAvatar(initials: followUp.member.initials, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          followUp.member.fullName,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (followUp.needsAttention) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.priority_high_rounded,
                            size: 15, color: AppColors.warning),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${followUp.typeDisplay} · ${DateFormatter.shortDate(followUp.date)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.doradoClaro,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    followUp.summary,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.crema.withValues(alpha: 0.75),
                    ),
                  ),
                  if (followUp.needsAttention) ...[
                    const SizedBox(height: 7),
                    Text(
                      'Marcado como que necesita atención cercana',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning),
                    ),
                  ],
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 19),
                color: AppColors.error.withValues(alpha: 0.75),
                tooltip: 'Borrar',
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

/// Anotación de un contacto con un integrante de la célula.
class _FollowUpFormSheet extends ConsumerStatefulWidget {
  final int cellId;
  final String cellName;

  const _FollowUpFormSheet({required this.cellId, required this.cellName});

  @override
  ConsumerState<_FollowUpFormSheet> createState() => _FollowUpFormSheetState();
}

class _FollowUpFormSheetState extends ConsumerState<_FollowUpFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _summary = TextEditingController();
  int? _memberId;
  String _type = FollowUpType.call;
  DateTime _date = DateTime.now();
  bool _needsAttention = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(cellMembersProvider(widget.cellId));

    return LeaderFormSheet(
      title: 'Nuevo seguimiento',
      subtitle: widget.cellName,
      child: members.when(
        loading: () => const LeaderLoading(),
        error: (error, _) => Text(
          ApiError.message(error, fallback: 'No pudimos cargar a los integrantes.'),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Text(
              'Primero registra a los integrantes de tu célula: el seguimiento se anota '
              'sobre una persona concreta.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.crema.withValues(alpha: 0.7),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _memberId,
                  isExpanded: true,
                  dropdownColor: AppColors.cardColor,
                  decoration: const InputDecoration(
                    labelText: 'Persona *',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.dorado),
                  ),
                  style: AppTextStyles.bodyMedium,
                  items: [
                    for (final member in list)
                      DropdownMenuItem(value: member.id, child: Text(member.fullName)),
                  ],
                  onChanged: (value) => setState(() => _memberId = value),
                  validator: (value) => value == null ? 'Elige a quién se dio seguimiento' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  isExpanded: true,
                  dropdownColor: AppColors.cardColor,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de contacto',
                    prefixIcon: Icon(Icons.forum_outlined, color: AppColors.dorado),
                  ),
                  style: AppTextStyles.bodyMedium,
                  items: [
                    for (final type in FollowUpType.all)
                      DropdownMenuItem(value: type, child: Text(FollowUpType.label(type))),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? FollowUpType.call),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha del contacto',
                      prefixIcon:
                          Icon(Icons.calendar_today_outlined, color: AppColors.dorado, size: 19),
                    ),
                    child: Text(
                      DateFormatter.shortDate(_isoDate(_date)),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _summary,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Qué se conversó *',
                    hintText: 'Cómo está, qué necesita, en qué quedaron...',
                    alignLabelWithHint: true,
                  ),
                  style: AppTextStyles.bodyMedium,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Escribe un resumen del contacto'
                      : null,
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  value: _needsAttention,
                  onChanged: (value) => setState(() => _needsAttention = value),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.dorado,
                  title: Text(
                    'Necesita atención cercana',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Aparecerá en el resumen de la célula y en el de tu supervisión.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.crema.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: 18),
                LeaderPrimaryButton(
                  label: 'ANOTAR SEGUIMIENTO',
                  icon: Icons.check_rounded,
                  isBusy: _isSaving,
                  onPressed: _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      helpText: 'Fecha del contacto',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(leaderRepositoryProvider).createFollowUp(
            cellId: widget.cellId,
            memberId: _memberId!,
            type: _type,
            date: _isoDate(_date),
            summary: _summary.text,
            needsAttention: _needsAttention,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = ApiError.message(error, fallback: 'No pudimos guardar el seguimiento.');
      });
    }
  }

  static String _isoDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

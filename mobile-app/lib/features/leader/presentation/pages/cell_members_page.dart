import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/api_error.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/leader_models.dart';
import '../providers/leader_providers.dart';
import '../widgets/leader_widgets.dart';

/// Quiénes componen la célula, con el alta y la baja de integrantes.
class CellMembersPage extends ConsumerWidget {
  const CellMembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cell = ref.watch(activeCellProvider);
    if (cell == null) {
      return const LeaderMissingCellScaffold(title: 'Miembros');
    }

    final user = ref.watch(authProvider).user;
    final canManage = ref.watch(canManageActiveCellProvider);
    final canRegister = canManage && (user?.can('MEMBERS_REGISTER') ?? false);
    final canRemove = canManage && (user?.can('MEMBERS_REMOVE') ?? false);
    final members = ref.watch(cellMembersProvider(cell.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Miembros'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              cell.name,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: canRegister
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.dorado,
              foregroundColor: AppColors.deepTeal,
              onPressed: () => _openRegisterSheet(context, ref, cell.id, cell.name),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('AÑADIR', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: members.when(
        loading: () => const LeaderLoading(),
        error: (error, _) => LeaderErrorState(
          message: ApiError.message(error, fallback: 'No pudimos cargar los miembros.'),
          onRetry: () => ref.invalidate(cellMembersProvider(cell.id)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return LeaderEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Tu célula todavía no tiene integrantes',
              message: canRegister
                  ? 'Usa el botón «Añadir» para registrar a la primera persona o a un visitante.'
                  : 'Cuando se asignen personas a esta célula, aparecerán aquí.',
            );
          }

          return RefreshIndicator(
            color: AppColors.dorado,
            backgroundColor: AppColors.cardColor,
            onRefresh: () async => ref.invalidate(cellMembersProvider(cell.id)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: list.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      list.length == 1 ? '1 persona' : '${list.length} personas',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.doradoClaro,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final member = list[index - 1];
                return _MemberCard(
                  member: member,
                  onRemove: canRemove
                      ? () => _confirmRemoval(context, ref, cell.id, cell.name, member)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openRegisterSheet(
    BuildContext context,
    WidgetRef ref,
    int cellId,
    String cellName,
  ) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegisterMemberSheet(cellId: cellId, cellName: cellName),
    );

    if (message == null || !context.mounted) return;
    ref.invalidate(cellMembersProvider(cellId));
    ref.invalidate(cellStatisticsProvider(cellId));
    showLeaderMessage(context, message);
  }

  Future<void> _confirmRemoval(
    BuildContext context,
    WidgetRef ref,
    int cellId,
    String cellName,
    CellMember member,
  ) async {
    final confirmed = await confirmLeaderAction(
      context,
      title: 'Retirar de la célula',
      message:
          '${member.fullName} dejará de pertenecer a $cellName. Conserva su cuenta y su '
          'historial de asistencia; no se elimina del sistema.',
      confirmLabel: 'RETIRAR',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      final detail = await ref.read(leaderRepositoryProvider).removeMember(cellId, member.id);
      ref.invalidate(cellMembersProvider(cellId));
      ref.invalidate(cellStatisticsProvider(cellId));
      if (context.mounted) showLeaderMessage(context, detail);
    } catch (error) {
      if (context.mounted) {
        showLeaderMessage(
          context,
          ApiError.message(error, fallback: 'No pudimos retirar a esta persona.'),
          isError: true,
        );
      }
    }
  }
}

class _MemberCard extends StatelessWidget {
  final CellMember member;
  final VoidCallback? onRemove;

  const _MemberCard({required this.member, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final contact = [
      if (member.phone != null && member.phone!.isNotEmpty) member.phone!,
      if (member.hasRealEmail) member.email,
    ].join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            LeaderAvatar(initials: member.initials),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.fullName,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!member.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.crema.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Inactivo',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.crema.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (contact.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      contact,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRemove != null)
              IconButton(
                tooltip: 'Retirar de la célula',
                icon: const Icon(Icons.person_remove_outlined, size: 20),
                color: AppColors.error.withValues(alpha: 0.8),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

/// Alta de un integrante o de un visitante.
///
/// El correo es opcional a propósito: mucha gente llega a la célula sin uno, y
/// exigirlo dejaría fuera del registro justo a quien se quiere seguir.
class _RegisterMemberSheet extends ConsumerStatefulWidget {
  final int cellId;
  final String cellName;

  const _RegisterMemberSheet({required this.cellId, required this.cellName});

  @override
  ConsumerState<_RegisterMemberSheet> createState() => _RegisterMemberSheetState();
}

class _RegisterMemberSheetState extends ConsumerState<_RegisterMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LeaderFormSheet(
      title: 'Nuevo integrante',
      subtitle: 'Quedará registrado en ${widget.cellName}',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.dorado),
              ),
              style: AppTextStyles.bodyMedium,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Escribe al menos el nombre' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Apellidos',
                prefixIcon: Icon(Icons.badge_outlined, color: AppColors.dorado),
              ),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono / WhatsApp',
                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.dorado),
              ),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo (opcional)',
                helperText: 'Sin correo también queda registrado, como visitante.',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.dorado),
              ),
              style: AppTextStyles.bodyMedium,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                return text.contains('@') ? null : 'Ese correo no parece válido';
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Dónde vive',
                prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.dorado),
              ),
              style: AppTextStyles.bodyMedium,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 22),
            LeaderPrimaryButton(
              label: 'REGISTRAR',
              icon: Icons.check_rounded,
              isBusy: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final detail = await ref.read(leaderRepositoryProvider).registerMember(
            widget.cellId,
            firstName: _firstName.text,
            lastName: _lastName.text,
            email: _email.text,
            phone: _phone.text,
            location: _location.text,
          );
      if (mounted) Navigator.pop(context, detail);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = ApiError.message(error, fallback: 'No pudimos registrar a esta persona.');
      });
    }
  }
}

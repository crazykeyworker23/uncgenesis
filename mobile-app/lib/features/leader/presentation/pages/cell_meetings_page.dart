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

/// Reuniones de la célula: registrarlas y pasar lista.
class CellMeetingsPage extends ConsumerWidget {
  const CellMeetingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cell = ref.watch(activeCellProvider);
    if (cell == null) {
      return const LeaderMissingCellScaffold(title: 'Reuniones');
    }

    final user = ref.watch(authProvider).user;
    final canManage = ref.watch(canManageActiveCellProvider);
    final canCreate = canManage && (user?.can('MEETINGS_CREATE') ?? false);
    final canEdit = canManage && (user?.can('MEETINGS_EDIT') ?? false);
    final canDelete = canManage && (user?.can('MEETINGS_DELETE') ?? false);
    final state = ref.watch(cellMeetingsProvider(cell.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reuniones'),
        bottom: leaderCellSubtitle(cell.name),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.dorado,
              foregroundColor: AppColors.deepTeal,
              onPressed: () => _openMeetingSheet(context, ref, cell.id, cell.name),
              icon: const Icon(Icons.add),
              label: const Text('REGISTRAR', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: Builder(
        builder: (context) {
          if (state.isLoadingFirstPage) return const LeaderLoading();

          if (state.errorMessage != null && state.items.isEmpty) {
            return LeaderErrorState(
              message: state.errorMessage!,
              onRetry: () => ref.read(cellMeetingsProvider(cell.id).notifier).refresh(),
            );
          }

          if (state.isEmpty) {
            return LeaderEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Todavía no hay reuniones registradas',
              message: canCreate
                  ? 'Registra la reunión de esta semana y pasa lista a tu célula.'
                  : 'Cuando se registren reuniones, aparecerán aquí con su asistencia.',
            );
          }

          return RefreshIndicator(
            color: AppColors.dorado,
            backgroundColor: AppColors.cardColor,
            onRefresh: () => ref.read(cellMeetingsProvider(cell.id).notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return _LoadMoreButton(
                    isLoading: state.isLoading,
                    onPressed: () => ref.read(cellMeetingsProvider(cell.id).notifier).loadMore(),
                  );
                }

                final meeting = state.items[index];
                return _MeetingCard(
                  meeting: meeting,
                  canTakeAttendance: canManage && (user?.can('ATTENDANCE_EDIT') ?? false),
                  onOpen: () => context.push('/leader/meetings/${meeting.id}/attendance'),
                  onEdit: canEdit
                      ? () => _openMeetingSheet(context, ref, cell.id, cell.name,
                          meeting: meeting)
                      : null,
                  onDelete: canDelete
                      ? () => _confirmDelete(context, ref, cell.id, meeting)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openMeetingSheet(
    BuildContext context,
    WidgetRef ref,
    int cellId,
    String cellName, {
    CellMeeting? meeting,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MeetingFormSheet(cellId: cellId, cellName: cellName, meeting: meeting),
    );

    if (saved != true || !context.mounted) return;
    await ref.read(cellMeetingsProvider(cellId).notifier).refresh();
    ref.invalidate(cellStatisticsProvider(cellId));
    if (context.mounted) {
      showLeaderMessage(
        context,
        meeting == null ? 'Reunión registrada.' : 'Reunión actualizada.',
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int cellId,
    CellMeeting meeting,
  ) async {
    final confirmed = await confirmLeaderAction(
      context,
      title: 'Borrar la reunión',
      message:
          'Se borrará la reunión del ${DateFormatter.shortDate(meeting.date)} y la asistencia '
          'que hayas registrado en ella. Esto no se puede deshacer.',
      confirmLabel: 'BORRAR',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(leaderRepositoryProvider).deleteMeeting(meeting.id);
      await ref.read(cellMeetingsProvider(cellId).notifier).refresh();
      ref.invalidate(cellStatisticsProvider(cellId));
      if (context.mounted) showLeaderMessage(context, 'Reunión borrada.');
    } catch (error) {
      if (context.mounted) {
        showLeaderMessage(
          context,
          ApiError.message(error, fallback: 'No pudimos borrar la reunión.'),
          isError: true,
        );
      }
    }
  }
}

class _MeetingCard extends StatelessWidget {
  final CellMeeting meeting;
  final bool canTakeAttendance;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MeetingCard({
    required this.meeting,
    required this.canTakeAttendance,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormatter.clockTime(meeting.time);
    final hasMenu = onEdit != null || onDelete != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormatter.longDate(meeting.date, fallback: 'Sin fecha'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.doradoClaro,
                          ),
                        ),
                        if (meeting.topic.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(meeting.topic, style: AppTextStyles.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (time.isNotEmpty)
                    Text(
                      time,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.5),
                      ),
                    ),
                  if (hasMenu)
                    SizedBox(
                      height: 28,
                      width: 32,
                      child: PopupMenuButton<String>(
                        color: AppColors.cardColor,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert, size: 18, color: AppColors.crema),
                        onSelected: (value) {
                          if (value == 'edit') onEdit?.call();
                          if (value == 'delete') onDelete?.call();
                        },
                        itemBuilder: (context) => [
                          if (onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar', style: TextStyle(color: AppColors.crema)),
                            ),
                          if (onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Borrar', style: TextStyle(color: AppColors.error)),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Icon(Icons.how_to_reg_outlined, size: 15, color: AppColors.dorado),
                  const SizedBox(width: 6),
                  Text(
                    meeting.hasAttendance
                        ? '${meeting.attendeesCount} asistente(s)'
                        : 'Sin lista pasada',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: meeting.hasAttendance
                          ? AppColors.crema.withValues(alpha: 0.7)
                          : AppColors.warning,
                    ),
                  ),
                  if (meeting.guestsCount > 0) ...[
                    const SizedBox(width: 10),
                    Text(
                      '${meeting.guestsCount} visitante(s)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    canTakeAttendance ? 'Pasar lista' : 'Ver asistencia',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.dorado,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 17, color: AppColors.dorado),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoadMoreButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.dorado))
          : TextButton(
              onPressed: onPressed,
              child: const Text('VER MÁS', style: TextStyle(color: AppColors.dorado)),
            ),
    );
  }
}

/// Alta y edición de una reunión.
class _MeetingFormSheet extends ConsumerStatefulWidget {
  final int cellId;
  final String cellName;
  final CellMeeting? meeting;

  const _MeetingFormSheet({required this.cellId, required this.cellName, this.meeting});

  @override
  ConsumerState<_MeetingFormSheet> createState() => _MeetingFormSheetState();
}

class _MeetingFormSheetState extends ConsumerState<_MeetingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _topic;
  late final TextEditingController _notes;
  late final TextEditingController _guests;
  late DateTime _date;
  TimeOfDay? _time;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final meeting = widget.meeting;
    _topic = TextEditingController(text: meeting?.topic ?? '');
    _notes = TextEditingController(text: meeting?.notes ?? '');
    _guests = TextEditingController(text: '${meeting?.guestsCount ?? 0}');
    _date = DateFormatter.parse(meeting?.date) ?? DateTime.now();
    _time = _parseTime(meeting?.time);
  }

  @override
  void dispose() {
    _topic.dispose();
    _notes.dispose();
    _guests.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.meeting != null;

    return LeaderFormSheet(
      title: isEditing ? 'Editar reunión' : 'Nueva reunión',
      subtitle: widget.cellName,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha',
                    value: DateFormatter.shortDate(_isoDate(_date)),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    icon: Icons.schedule_outlined,
                    label: 'Hora',
                    value: _time == null
                        ? 'Sin definir'
                        : '${_two(_time!.hour)}:${_two(_time!.minute)}',
                    onTap: _pickTime,
                    onClear: _time == null ? null : () => setState(() => _time = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _topic,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tema tratado',
                hintText: 'Ej. La oración que persevera',
                prefixIcon: Icon(Icons.menu_book_outlined, color: AppColors.dorado),
              ),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _guests,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Visitantes',
                helperText: 'Gente que asistió sin estar registrada en la célula.',
                prefixIcon: Icon(Icons.emoji_people_outlined, color: AppColors.dorado),
              ),
              style: AppTextStyles.bodyMedium,
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return null;
                final parsed = int.tryParse(text);
                if (parsed == null || parsed < 0) return 'Escribe un número válido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                alignLabelWithHint: true,
              ),
              style: AppTextStyles.bodyMedium,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: 22),
            LeaderPrimaryButton(
              label: isEditing ? 'GUARDAR CAMBIOS' : 'REGISTRAR REUNIÓN',
              icon: Icons.check_rounded,
              isBusy: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: 'Fecha de la reunión',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 19, minute: 0),
      helpText: 'Hora de la reunión',
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final repository = ref.read(leaderRepositoryProvider);
    final time = _time == null ? null : '${_two(_time!.hour)}:${_two(_time!.minute)}:00';
    final guests = int.tryParse(_guests.text.trim()) ?? 0;

    try {
      if (widget.meeting == null) {
        await repository.createMeeting(
          cellId: widget.cellId,
          date: _isoDate(_date),
          time: time,
          topic: _topic.text,
          notes: _notes.text,
          guestsCount: guests,
        );
      } else {
        await repository.updateMeeting(
          widget.meeting!.id,
          date: _isoDate(_date),
          time: time,
          topic: _topic.text,
          notes: _notes.text,
          guestsCount: guests,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        // El servidor rechaza dos reuniones de la misma célula el mismo día y
        // lo explica con un mensaje concreto; conviene mostrarlo tal cual.
        _error = ApiError.message(error, fallback: 'No pudimos guardar la reunión.');
      });
    }
  }

  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _isoDate(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.dorado, size: 19),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  color: AppColors.crema,
                  onPressed: onClear,
                ),
        ),
        child: Text(value, style: AppTextStyles.bodyMedium),
      ),
    );
  }
}

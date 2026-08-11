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

/// Pase de lista de una reunión.
///
/// Se marca a cada persona con uno de los cuatro estados del sistema y se
/// guarda todo de una vez: hacerlo persona a persona sería una petición por
/// cabeza y con mala cobertura se quedaría a medias.
class CellAttendancePage extends ConsumerStatefulWidget {
  final int meetingId;

  const CellAttendancePage({super.key, required this.meetingId});

  @override
  ConsumerState<CellAttendancePage> createState() => _CellAttendancePageState();
}

class _CellAttendancePageState extends ConsumerState<CellAttendancePage> {
  /// Lo marcado en pantalla, que puede diferir de lo guardado hasta pulsar.
  final Map<int, String> _marks = {};

  /// Evita pisar lo que el líder ya tocó cada vez que el provider reconstruye.
  bool _seeded = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final cell = ref.watch(activeCellProvider);
    if (cell == null) {
      return const LeaderMissingCellScaffold(title: 'Asistencia');
    }

    final user = ref.watch(authProvider).user;
    final canEdit = ref.watch(canManageActiveCellProvider) &&
        (user?.can('ATTENDANCE_EDIT') ?? false);

    final meeting = ref.watch(cellMeetingProvider(widget.meetingId));
    final members = ref.watch(cellMembersProvider(cell.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        bottom: leaderCellSubtitle(
          meeting.valueOrNull == null
              ? cell.name
              : DateFormatter.longDate(meeting.value!.date, fallback: cell.name),
        ),
      ),
      body: meeting.when(
        loading: () => const LeaderLoading(),
        error: (error, _) => LeaderErrorState(
          message: ApiError.message(error, fallback: 'No pudimos cargar la reunión.'),
          onRetry: () => ref.invalidate(cellMeetingProvider(widget.meetingId)),
        ),
        data: (data) => members.when(
          loading: () => const LeaderLoading(),
          error: (error, _) => LeaderErrorState(
            message: ApiError.message(error, fallback: 'No pudimos cargar los miembros.'),
            onRetry: () => ref.invalidate(cellMembersProvider(cell.id)),
          ),
          data: (list) {
            _seedMarks(data, list);
            if (list.isEmpty) {
              return const LeaderEmptyState(
                icon: Icons.person_off_outlined,
                title: 'No hay a quién pasar lista',
                message: 'Registra primero a los integrantes de tu célula.',
              );
            }
            return _AttendanceList(
              meeting: data,
              members: list,
              marks: _marks,
              canEdit: canEdit,
              isSaving: _isSaving,
              onMark: (memberId, status) => setState(() => _marks[memberId] = status),
              onMarkAll: () => setState(() {
                for (final member in list) {
                  _marks[member.id] = AttendanceStatus.present;
                }
              }),
              onSave: () => _save(cell.id, list),
            );
          },
        ),
      ),
    );
  }

  /// Parte de lo que ya estaba guardado, para poder corregir sin volver a
  /// marcar a toda la célula desde cero.
  void _seedMarks(CellMeeting meeting, List<CellMember> members) {
    if (_seeded) return;
    _seeded = true;
    for (final member in members) {
      final saved = meeting.statusFor(member.id);
      if (saved != null) _marks[member.id] = saved;
    }
  }

  Future<void> _save(int cellId, List<CellMember> members) async {
    final drafts = <AttendanceDraft>[
      for (final member in members)
        if (_marks[member.id] != null)
          AttendanceDraft(memberId: member.id, status: _marks[member.id]!),
    ];

    if (drafts.isEmpty) {
      showLeaderMessage(context, 'Marca al menos a una persona antes de guardar.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final attendees =
          await ref.read(leaderRepositoryProvider).saveAttendance(widget.meetingId, drafts);

      ref.invalidate(cellMeetingProvider(widget.meetingId));
      ref.invalidate(cellStatisticsProvider(cellId));
      await ref.read(cellMeetingsProvider(cellId).notifier).refresh();

      if (!mounted) return;
      setState(() => _isSaving = false);
      showLeaderMessage(context, 'Asistencia guardada: $attendees asistente(s).');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showLeaderMessage(
        context,
        ApiError.message(error, fallback: 'No pudimos guardar la asistencia.'),
        isError: true,
      );
    }
  }
}

class _AttendanceList extends StatelessWidget {
  final CellMeeting meeting;
  final List<CellMember> members;
  final Map<int, String> marks;
  final bool canEdit;
  final bool isSaving;
  final void Function(int memberId, String status) onMark;
  final VoidCallback onMarkAll;
  final VoidCallback onSave;

  const _AttendanceList({
    required this.meeting,
    required this.members,
    required this.marks,
    required this.canEdit,
    required this.isSaving,
    required this.onMark,
    required this.onMarkAll,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final marked = members.where((m) => marks[m.id] != null).length;
    final present = members
        .where((m) => marks[m.id] == AttendanceStatus.present || marks[m.id] == AttendanceStatus.late)
        .length;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.darkTeal,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.topic.isEmpty ? 'Reunión de célula' : meeting.topic,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$present de ${members.length} presentes · $marked marcado(s)'
                      '${meeting.guestsCount > 0 ? ' · ${meeting.guestsCount} visitante(s)' : ''}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                TextButton(
                  onPressed: onMarkAll,
                  child: Text(
                    'TODOS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.dorado,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final member = members[index];
              return _AttendanceRow(
                member: member,
                status: marks[member.id],
                canEdit: canEdit,
                onMark: (status) => onMark(member.id, status),
              );
            },
          ),
        ),
        if (canEdit)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: LeaderPrimaryButton(
                label: 'GUARDAR ASISTENCIA',
                icon: Icons.save_outlined,
                isBusy: isSaving,
                onPressed: onSave,
              ),
            ),
          ),
      ],
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final CellMember member;
  final String? status;
  final bool canEdit;
  final ValueChanged<String> onMark;

  const _AttendanceRow({
    required this.member,
    required this.status,
    required this.canEdit,
    required this.onMark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LeaderAvatar(initials: member.initials, size: 34),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    member.fullName,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!canEdit)
                  Text(
                    AttendanceStatus.label(status),
                    style: AppTextStyles.bodySmall.copyWith(color: _toneFor(status)),
                  ),
              ],
            ),
            if (canEdit) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final option in AttendanceStatus.all) ...[
                    Expanded(
                      child: _StatusChip(
                        label: AttendanceStatus.shortLabels[option] ?? option,
                        selected: status == option,
                        tone: _toneFor(option),
                        onTap: () => onMark(option),
                      ),
                    ),
                    if (option != AttendanceStatus.all.last) const SizedBox(width: 6),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _toneFor(String? status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.excused:
        return AppColors.doradoClaro;
      case AttendanceStatus.absent:
        return AppColors.error;
      default:
        return AppColors.crema;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color tone;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? tone.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? tone : AppColors.crema.withValues(alpha: 0.15),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? tone : AppColors.crema.withValues(alpha: 0.6),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

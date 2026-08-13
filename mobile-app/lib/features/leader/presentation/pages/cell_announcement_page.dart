import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/api_error.dart';
import '../../data/models/leader_models.dart';
import '../providers/leader_providers.dart';
import '../widgets/leader_widgets.dart';

/// Aviso que el líder envía desde su célula.
///
/// Elige a cuál de sus tres interlocutores va: su gente, quien le supervisa o
/// el pastorado. Sale como notificación al teléfono —llega también con la app
/// cerrada— y queda registrado en el listado de quien lo recibe.
///
/// Difundir a la iglesia entera no está entre las opciones: eso exige permisos
/// de comunicaciones, y el servidor vuelve a comprobar el destino elegido.
class CellAnnouncementPage extends ConsumerStatefulWidget {
  const CellAnnouncementPage({super.key});

  @override
  ConsumerState<CellAnnouncementPage> createState() => _CellAnnouncementPageState();
}

class _CellAnnouncementPageState extends ConsumerState<CellAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();

  String _recipient = ReminderRecipient.cell;
  bool _scheduled = false;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cell = ref.watch(activeCellProvider);
    if (cell == null) {
      return const LeaderMissingCellScaffold(title: 'Enviar aviso');
    }

    final members = ref.watch(cellMembersProvider(cell.id));
    final recipients = members.valueOrNull?.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar aviso'),
        bottom: leaderCellSubtitle(cell.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LeaderSectionLabel('Para quién'),
              for (final option in ReminderRecipient.all) ...[
                _RecipientOption(
                  label: ReminderRecipient.labels[option]!,
                  description: option == ReminderRecipient.cell && recipients != null
                      ? '$recipients persona(s) de ${cell.name}'
                      : ReminderRecipient.descriptions[option]!,
                  icon: _iconFor(option),
                  selected: _recipient == option,
                  onTap: () => setState(() => _recipient = option),
                ),
                if (option != ReminderRecipient.all.last) const SizedBox(height: 8),
              ],
              const SizedBox(height: 10),
              Text(
                'Llega al teléfono aunque tengan la app cerrada.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.crema.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 22),

              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: 'Título',
                  hintText: 'Recordatorio de ${cell.name}',
                  helperText: 'Si lo dejas vacío se pone uno según a quién va.',
                  prefixIcon: const Icon(Icons.title, color: AppColors.dorado),
                  counterText: '',
                ),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _body,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Mensaje *',
                  hintText: 'Ej. Nos reunimos el jueves a las 7 en casa de la hermana Rosa.',
                  alignLabelWithHint: true,
                ),
                style: AppTextStyles.bodyMedium,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Escribe el mensaje que quieres enviar'
                    : null,
              ),
              const SizedBox(height: 10),

              SwitchListTile(
                value: _scheduled,
                onChanged: (value) => setState(() => _scheduled = value),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.dorado,
                title: Text(
                  'Programar para más tarde',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _scheduled
                      ? 'Se enviará solo a la hora indicada.'
                      : 'Se envía ahora mismo, en cuanto pulses el botón.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.crema.withValues(alpha: 0.5),
                  ),
                ),
              ),

              if (_scheduled) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Día',
                            prefixIcon: Icon(Icons.calendar_today_outlined,
                                color: AppColors.dorado, size: 19),
                          ),
                          child: Text(
                            '${_two(_date.day)}/${_two(_date.month)}/${_date.year}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Hora',
                            prefixIcon: Icon(Icons.schedule_outlined,
                                color: AppColors.dorado, size: 19),
                          ),
                          child: Text(
                            '${_two(_time.hour)}:${_two(_time.minute)}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ],

              const SizedBox(height: 26),
              LeaderPrimaryButton(
                label: _scheduled ? 'PROGRAMAR AVISO' : 'ENVIAR AHORA',
                icon: _scheduled ? Icons.schedule_send_outlined : Icons.send_rounded,
                isBusy: _isSending,
                onPressed: () => _send(cell.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String recipient) {
    switch (recipient) {
      case ReminderRecipient.coordinator:
        return Icons.supervisor_account_outlined;
      case ReminderRecipient.pastors:
        return Icons.church_outlined;
      default:
        return Icons.groups_outlined;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: 'Día del aviso',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Hora del aviso',
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _send(int cellId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    DateTime? scheduledFor;
    if (_scheduled) {
      scheduledFor = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
      if (!scheduledFor.isAfter(DateTime.now())) {
        setState(() => _error = 'Elige una fecha y una hora que todavía no hayan pasado.');
        return;
      }
    }

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final detail = await ref.read(leaderRepositoryProvider).sendReminder(
            cellId,
            title: _title.text,
            body: _body.text,
            scheduledFor: scheduledFor,
            recipient: _recipient,
          );

      if (!mounted) return;
      // El mensaje lo redacta el servidor con el número real de destinatarios.
      showLeaderMessage(context, detail);
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = ApiError.message(error, fallback: 'No pudimos enviar el aviso.');
      });
    }
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// Uno de los destinos posibles del aviso.
class _RecipientOption extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RecipientOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? AppColors.dorado.withValues(alpha: 0.1) : AppColors.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.dorado : AppColors.crema.withValues(alpha: 0.1),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.dorado : AppColors.crema.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: selected ? AppColors.doradoClaro : AppColors.crema,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 19,
                color: selected ? AppColors.dorado : AppColors.crema.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

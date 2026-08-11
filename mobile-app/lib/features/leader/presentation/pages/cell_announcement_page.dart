import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/api_error.dart';
import '../providers/leader_providers.dart';
import '../widgets/leader_widgets.dart';

/// Aviso del líder a los miembros de su célula.
///
/// Sale como notificación al teléfono —llega también con la app cerrada— y
/// queda registrado en el listado de avisos de cada persona. El alcance está
/// acotado por el servidor: sólo llega a quien pertenece a esta célula.
class CellAnnouncementPage extends ConsumerStatefulWidget {
  const CellAnnouncementPage({super.key});

  @override
  ConsumerState<CellAnnouncementPage> createState() => _CellAnnouncementPageState();
}

class _CellAnnouncementPageState extends ConsumerState<CellAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();

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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.dorado.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dorado.withValues(alpha: 0.22)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_outlined, color: AppColors.dorado, size: 20),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        recipients == null
                            ? 'El aviso llegará al teléfono de tu célula.'
                            : 'Llegará a $recipients persona(s) de ${cell.name}, aunque tengan '
                                'la app cerrada.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.crema.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: 'Título',
                  hintText: 'Recordatorio de ${cell.name}',
                  helperText: 'Si lo dejas vacío se usa el nombre de tu célula.',
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

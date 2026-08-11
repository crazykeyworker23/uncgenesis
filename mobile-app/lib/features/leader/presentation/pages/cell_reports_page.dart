import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/leader_models.dart';
import '../providers/leader_providers.dart';
import '../widgets/leader_widgets.dart';

/// Informes de actividad que el líder entrega a su supervisión.
///
/// Un informe se guarda primero como borrador y se envía cuando está listo. Al
/// enviarlo, el servidor congela las cifras del periodo: si más adelante se
/// corrige una asistencia, lo entregado no cambia.
class CellReportsPage extends ConsumerWidget {
  const CellReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cell = ref.watch(activeCellProvider);
    if (cell == null) {
      return const LeaderMissingCellScaffold(title: 'Informes');
    }

    final user = ref.watch(authProvider).user;
    final canManage = ref.watch(canManageActiveCellProvider);
    final canWrite = canManage && (user?.can('CELL_REPORTS_CREATE') ?? false);
    final state = ref.watch(cellReportsProvider(cell.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes'),
        bottom: leaderCellSubtitle(cell.name),
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.dorado,
              foregroundColor: AppColors.deepTeal,
              onPressed: () => _openForm(context, ref, cell.id, cell.name),
              icon: const Icon(Icons.edit_note),
              label: const Text('REDACTAR', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: Builder(
        builder: (context) {
          if (state.isLoadingFirstPage) return const LeaderLoading();

          if (state.errorMessage != null && state.items.isEmpty) {
            return LeaderErrorState(
              message: state.errorMessage!,
              onRetry: () => ref.read(cellReportsProvider(cell.id).notifier).refresh(),
            );
          }

          if (state.isEmpty) {
            return LeaderEmptyState(
              icon: Icons.description_outlined,
              title: 'Todavía no has enviado ningún informe',
              message: canWrite
                  ? 'Cuenta cómo le fue a tu célula en el periodo y envíalo a tu supervisión.'
                  : 'Aquí aparecerán los informes que envíe quien lidera la célula.',
            );
          }

          return RefreshIndicator(
            color: AppColors.dorado,
            backgroundColor: AppColors.cardColor,
            onRefresh: () => ref.read(cellReportsProvider(cell.id).notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.dorado))
                        : TextButton(
                            onPressed: () =>
                                ref.read(cellReportsProvider(cell.id).notifier).loadMore(),
                            child:
                                const Text('VER MÁS', style: TextStyle(color: AppColors.dorado)),
                          ),
                  );
                }

                final report = state.items[index];
                return _ReportCard(
                  report: report,
                  onEdit: canWrite && report.isDraft
                      ? () => _openForm(context, ref, cell.id, cell.name, report: report)
                      : null,
                  onSend: canWrite && report.isDraft
                      ? () => _confirmSend(context, ref, cell.id, report)
                      : null,
                  onDelete: canWrite && report.isDraft
                      ? () => _confirmDelete(context, ref, cell.id, report)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    int cellId,
    String cellName, {
    CellReport? report,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportFormSheet(cellId: cellId, cellName: cellName, report: report),
    );

    if (saved != true || !context.mounted) return;
    await ref.read(cellReportsProvider(cellId).notifier).refresh();
    if (context.mounted) {
      showLeaderMessage(
        context,
        'Informe guardado como borrador. Revísalo y envíalo cuando esté listo.',
      );
    }
  }

  Future<void> _confirmSend(
    BuildContext context,
    WidgetRef ref,
    int cellId,
    CellReport report,
  ) async {
    final confirmed = await confirmLeaderAction(
      context,
      title: 'Enviar el informe',
      message:
          'Se entregará a tu supervisión y ya no podrás modificarlo. Las cifras del periodo '
          'quedan congeladas tal como están hoy.',
      confirmLabel: 'ENVIAR',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(leaderRepositoryProvider).sendReport(report.id);
      await ref.read(cellReportsProvider(cellId).notifier).refresh();
      if (context.mounted) showLeaderMessage(context, 'Informe enviado a tu supervisión.');
    } catch (error) {
      if (context.mounted) {
        showLeaderMessage(
          context,
          ApiError.message(error, fallback: 'No pudimos enviar el informe.'),
          isError: true,
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int cellId,
    CellReport report,
  ) async {
    final confirmed = await confirmLeaderAction(
      context,
      title: 'Borrar el borrador',
      message: 'Se perderá lo que llevas escrito de este informe.',
      confirmLabel: 'BORRAR',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(leaderRepositoryProvider).deleteReport(report.id);
      await ref.read(cellReportsProvider(cellId).notifier).refresh();
      if (context.mounted) showLeaderMessage(context, 'Borrador borrado.');
    } catch (error) {
      if (context.mounted) {
        showLeaderMessage(
          context,
          ApiError.message(error, fallback: 'No pudimos borrar el borrador.'),
          isError: true,
        );
      }
    }
  }
}

class _ReportCard extends StatelessWidget {
  final CellReport report;
  final VoidCallback? onEdit;
  final VoidCallback? onSend;
  final VoidCallback? onDelete;

  const _ReportCard({required this.report, this.onEdit, this.onSend, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${DateFormatter.shortDate(report.periodStart)} — '
                    '${DateFormatter.shortDate(report.periodEnd)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.doradoClaro,
                    ),
                  ),
                ),
                _StatusPill(status: report.status, label: report.statusDisplay),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.summary,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.78),
              ),
            ),

            if (!report.isDraft) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniFigure(label: 'Reuniones', value: '${report.meetingsHeld}'),
                  const SizedBox(width: 8),
                  _MiniFigure(
                    label: 'Asistencia',
                    value: report.averageAttendance == report.averageAttendance.roundToDouble()
                        ? '${report.averageAttendance.round()}'
                        : report.averageAttendance.toStringAsFixed(1),
                  ),
                  const SizedBox(width: 8),
                  _MiniFigure(label: 'Nuevos', value: '${report.newMembers}'),
                ],
              ),
            ],

            if (report.photoUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  report.photoUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              if (report.photoCaption.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  report.photoCaption,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.crema.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ],

            if (report.hasReply) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.dorado.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESPUESTA DE TU SUPERVISIÓN',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.doradoClaro,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(report.reviewNotes, style: AppTextStyles.bodySmall),
                    if (report.reviewedBy != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '— ${report.reviewedBy!.fullName}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.crema.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            if (onEdit != null || onSend != null || onDelete != null) ...[
              const Divider(color: AppColors.darkTeal, height: 26),
              Row(
                children: [
                  if (onDelete != null)
                    TextButton(
                      onPressed: onDelete,
                      child: const Text('BORRAR', style: TextStyle(color: AppColors.error)),
                    ),
                  const Spacer(),
                  if (onEdit != null)
                    TextButton(
                      onPressed: onEdit,
                      child: const Text('EDITAR', style: TextStyle(color: AppColors.crema)),
                    ),
                  if (onSend != null) ...[
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: onSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dorado,
                        foregroundColor: AppColors.deepTeal,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: const Text('ENVIAR',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final String label;

  const _StatusPill({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      CellReportStatus.reviewed => AppColors.success,
      CellReportStatus.sent => AppColors.dorado,
      _ => AppColors.crema,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: tone, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MiniFigure extends StatelessWidget {
  final String label;
  final String value;

  const _MiniFigure({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.deepTeal.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.dorado,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Redacción de un informe: qué pasó en el periodo y una foto de la célula.
class _ReportFormSheet extends ConsumerStatefulWidget {
  final int cellId;
  final String cellName;
  final CellReport? report;

  const _ReportFormSheet({required this.cellId, required this.cellName, this.report});

  @override
  ConsumerState<_ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends ConsumerState<_ReportFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _summary;
  late final TextEditingController _highlights;
  late final TextEditingController _challenges;
  late final TextEditingController _prayerNeeds;
  late final TextEditingController _photoCaption;

  late DateTime _periodStart;
  late DateTime _periodEnd;
  String? _photoPath;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final report = widget.report;
    _summary = TextEditingController(text: report?.summary ?? '');
    _highlights = TextEditingController(text: report?.highlights ?? '');
    _challenges = TextEditingController(text: report?.challenges ?? '');
    _prayerNeeds = TextEditingController(text: report?.prayerNeeds ?? '');
    _photoCaption = TextEditingController(text: report?.photoCaption ?? '');

    final now = DateTime.now();
    // Por omisión, el mes en curso: es el periodo que se informa casi siempre.
    _periodStart = DateFormatter.parse(report?.periodStart) ?? DateTime(now.year, now.month, 1);
    _periodEnd = DateFormatter.parse(report?.periodEnd) ?? now;
  }

  @override
  void dispose() {
    _summary.dispose();
    _highlights.dispose();
    _challenges.dispose();
    _prayerNeeds.dispose();
    _photoCaption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LeaderFormSheet(
      title: widget.report == null ? 'Nuevo informe' : 'Editar borrador',
      subtitle: widget.cellName,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Desde',
                    date: _periodStart,
                    onPick: (picked) => setState(() => _periodStart = picked),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Hasta',
                    date: _periodEnd,
                    onPick: (picked) => setState(() => _periodEnd = picked),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _summary,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Cómo le fue a la célula *',
                hintText: 'Un resumen de lo vivido en el periodo',
                alignLabelWithHint: true,
              ),
              style: AppTextStyles.bodyMedium,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Cuenta cómo les fue' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _highlights,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Lo más destacado',
                alignLabelWithHint: true,
              ),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _challenges,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Dificultades',
                alignLabelWithHint: true,
              ),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _prayerNeeds,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Motivos de oración',
                alignLabelWithHint: true,
              ),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 18),

            _PhotoPicker(
              localPath: _photoPath,
              existingUrl: widget.report?.photoUrl,
              onPick: _pickPhoto,
              onClear: _photoPath == null ? null : () => setState(() => _photoPath = null),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _photoCaption,
              decoration: const InputDecoration(
                labelText: 'Pie de foto',
                prefixIcon: Icon(Icons.short_text, color: AppColors.dorado),
              ),
              style: AppTextStyles.bodyMedium,
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: 20),
            LeaderPrimaryButton(
              label: 'GUARDAR BORRADOR',
              icon: Icons.save_outlined,
              isBusy: _isSaving,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            Text(
              'Se guarda como borrador: podrás revisarlo y enviarlo desde la lista.',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardColor,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.dorado),
              title: const Text('Galería', style: TextStyle(color: AppColors.crema)),
              onTap: () async {
                Navigator.pop(sheetContext);
                final picked =
                    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (picked != null && mounted) setState(() => _photoPath = picked.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.dorado),
              title: const Text('Cámara', style: TextStyle(color: AppColors.crema)),
              onTap: () async {
                Navigator.pop(sheetContext);
                final picked =
                    await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (picked != null && mounted) setState(() => _photoPath = picked.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_periodEnd.isBefore(_periodStart)) {
      setState(() => _error = 'La fecha final del periodo no puede ser anterior a la inicial.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(leaderRepositoryProvider).saveReport(
            cellId: widget.cellId,
            reportId: widget.report?.id,
            periodStart: _isoDate(_periodStart),
            periodEnd: _isoDate(_periodEnd),
            summary: _summary.text,
            highlights: _highlights.text,
            challenges: _challenges.text,
            prayerNeeds: _prayerNeeds.text,
            photoCaption: _photoCaption.text,
            photoPath: _photoPath,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = ApiError.message(error, fallback: 'No pudimos guardar el informe.');
      });
    }
  }

  static String _isoDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  const _DateField({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(DateTime.now().year - 2),
          lastDate: DateTime(DateTime.now().year + 1, 12, 31),
          helpText: label == 'Desde' ? 'Inicio del periodo' : 'Fin del periodo',
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.date_range_outlined, color: AppColors.dorado, size: 19),
        ),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}',
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}

/// Foto de la reunión: al coordinador le dice más que cualquier resumen.
class _PhotoPicker extends StatelessWidget {
  final String? localPath;
  final String? existingUrl;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _PhotoPicker({
    required this.localPath,
    required this.existingUrl,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview = localPath != null || existingUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPreview) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: localPath != null
                ? Image.file(File(localPath!), height: 160, fit: BoxFit.cover)
                : Image.network(
                    existingUrl!,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dorado,
                  side: BorderSide(color: AppColors.dorado.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onPick,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(hasPreview ? 'CAMBIAR FOTO' : 'ADJUNTAR FOTO'),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                color: AppColors.error,
                onPressed: onClear,
                tooltip: 'Quitar la foto',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

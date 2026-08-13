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
/// Se elige el día del que se informa y se cuenta con palabras cómo fue, con
/// una foto si se quiere. Primero queda como borrador y se envía cuando está
/// listo; una vez enviado ya no se toca, para que lo que se revisa sea lo que
/// se entregó.
///
/// No lleva cifras: las de la célula están en «Estadísticas», calculadas al
/// momento y siempre al día.
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
      message: 'Se entregará a tu supervisión y ya no podrás modificarlo.',
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
                    // Los informes nuevos son de un día. Los que ya se
                    // entregaron con un periodo siguen mostrándose como tal.
                    report.periodStart == report.periodEnd
                        ? DateFormatter.longDate(report.periodStart, fallback: 'Sin fecha')
                        : '${DateFormatter.shortDate(report.periodStart)} — '
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

  /// Día del que se informa.
  ///
  /// El servidor guarda un periodo con principio y fin, que es lo que pedía el
  /// formulario. Para el líder eso era un trámite de más: informa de un día
  /// concreto, el de la reunión. Se elige una fecha y se envía como principio
  /// y fin a la vez, así que ni el panel ni los informes ya entregados
  /// cambian.
  late DateTime _reportDate;
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

    // Al redactar uno nuevo se propone hoy, que es cuando se suele escribir.
    // Al corregir un borrador se recupera la fecha con la que se guardó.
    _reportDate = DateFormatter.parse(report?.periodEnd) ??
        DateFormatter.parse(report?.periodStart) ??
        DateTime.now();
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
            _DateField(
              label: 'Fecha del informe',
              date: _reportDate,
              onPick: (picked) => setState(() => _reportDate = picked),
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

    setState(() {
      _isSaving = true;
      _error = null;
    });

    // Un solo día: se manda como principio y fin del periodo, que es lo que
    // el servidor guarda. Ya no hay dos fechas que puedan quedar del revés,
    // así que tampoco hace falta comprobarlo.
    final fecha = _isoDate(_reportDate);

    try {
      await ref.read(leaderRepositoryProvider).saveReport(
            cellId: widget.cellId,
            reportId: widget.report?.id,
            periodStart: fecha,
            periodEnd: fecha,
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
          // No se informa del futuro: se cuenta lo que ya pasó.
          lastDate: DateTime.now(),
          helpText: label,
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              const Icon(Icons.calendar_today_outlined, color: AppColors.dorado, size: 19),
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

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
              onPressed: () => _chooseKind(context, ref, cell.id, cell.name),
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

  /// Pregunta qué se va a redactar antes de abrir el formulario.
  ///
  /// Son dos entregas distintas —cómo fue la reunión y la constancia del
  /// devocional—, y cada una pide cosas distintas, así que conviene decidirlo
  /// antes y no a mitad del formulario.
  Future<void> _chooseKind(BuildContext context, WidgetRef ref, int cellId, String cellName) async {
    final kind = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                '¿QUÉ VAS A INFORMAR?',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.doradoClaro,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined, color: AppColors.dorado),
              title: const Text(
                'Informe de la célula',
                style: TextStyle(color: AppColors.crema, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Cómo les fue en la reunión. Puedes adjuntar varias fotos.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.crema.withValues(alpha: 0.5),
                ),
              ),
              onTap: () => Navigator.pop(sheetContext, CellReportKind.activity),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined, color: AppColors.dorado),
              title: const Text(
                'Reporte del devocional',
                style: TextStyle(color: AppColors.crema, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'El día leído y la captura de la lectura.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.crema.withValues(alpha: 0.5),
                ),
              ),
              onTap: () => Navigator.pop(sheetContext, CellReportKind.devotional),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (kind == null || !context.mounted) return;
    await _openForm(context, ref, cellId, cellName, kind: kind);
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    int cellId,
    String cellName, {
    CellReport? report,
    String kind = CellReportKind.activity,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ReportFormSheet(cellId: cellId, cellName: cellName, report: report, kind: kind),
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
            if (report.isDevotional) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 14, color: AppColors.dorado),
                  const SizedBox(width: 5),
                  Text(
                    'DEVOCIONAL',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.dorado,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              report.summary,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.78),
              ),
            ),

            if (report.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ReportGallery(urls: report.imageUrls),
            ],
            if (report.photoCaption.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                report.photoCaption,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.crema.withValues(alpha: 0.45),
                ),
              ),
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

  /// Qué se está redactando. Al corregir un borrador manda el suyo.
  final String kind;

  const _ReportFormSheet({
    required this.cellId,
    required this.cellName,
    this.report,
    this.kind = CellReportKind.activity,
  });

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

  /// Día del que se informa.
  ///
  /// El servidor guarda un periodo con principio y fin, que es lo que pedía el
  /// formulario. Para el líder eso era un trámite de más: informa de un día
  /// concreto, el de la reunión. Se elige una fecha y se envía como principio
  /// y fin a la vez, así que ni el panel ni los informes ya entregados
  /// cambian.
  late DateTime _reportDate;

  /// Rutas de las imágenes elegidas en el teléfono, en el orden en que las
  /// eligió. Vacío significa «no toques lo ya adjuntado».
  final List<String> _photoPaths = [];

  late String _kind;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final report = widget.report;
    _kind = report?.kind ?? widget.kind;
    _summary = TextEditingController(text: report?.summary ?? '');
    _highlights = TextEditingController(text: report?.highlights ?? '');
    _challenges = TextEditingController(text: report?.challenges ?? '');
    _prayerNeeds = TextEditingController(text: report?.prayerNeeds ?? '');

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
    super.dispose();
  }

  bool get _isDevotional => _kind == CellReportKind.devotional;

  /// Imágenes ya guardadas en el servidor, que siguen ahí mientras no se elijan
  /// otras nuevas.
  List<String> get _existingUrls => widget.report?.imageUrls ?? const [];

  @override
  Widget build(BuildContext context) {
    final esNuevo = widget.report == null;
    final titulo = _isDevotional
        ? (esNuevo ? 'Reporte del devocional' : 'Editar el devocional')
        : (esNuevo ? 'Nuevo informe' : 'Editar borrador');

    return LeaderFormSheet(
      title: titulo,
      subtitle: widget.cellName,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DateField(
              label: _isDevotional ? 'Día que leyeron' : 'Fecha del informe',
              date: _reportDate,
              onPick: (picked) => setState(() => _reportDate = picked),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _summary,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _isDevotional ? 'Qué leyeron *' : 'Cómo le fue a la célula *',
                hintText: _isDevotional
                    ? 'El libro y el capítulo, y unas líneas de lo que compartieron'
                    : 'Un resumen de lo vivido en el periodo',
                alignLabelWithHint: true,
              ),
              style: AppTextStyles.bodyMedium,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? (_isDevotional ? 'Cuenta qué leyeron' : 'Cuenta cómo les fue')
                  : null,
            ),

            // El devocional se entrega corto: el día, unas líneas y la captura.
            // Los apartados del informe de actividad sobran ahí.
            if (!_isDevotional) ...[
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
            ],
            const SizedBox(height: 18),

            _PhotoPicker(
              localPaths: _photoPaths,
              existingUrls: _existingUrls,
              maxPhotos: _maxPhotos,
              isDevotional: _isDevotional,
              onPick: _pickPhotos,
              onRemove: (index) => setState(() => _photoPaths.removeAt(index)),
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
              _isDevotional
                  ? 'Se guarda como borrador: revísalo y envíalo desde la lista.'
                  : 'Se guarda como borrador: podrás revisarlo y enviarlo desde la lista.',
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

  /// Cuántas imágenes admite el informe. El mismo tope que guarda el servidor.
  static const int _maxPhotos = 5;

  Future<void> _pickPhotos() async {
    final quedan = _maxPhotos - _photoPaths.length;
    if (quedan <= 0) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardColor,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.dorado),
              title: const Text('Galería', style: TextStyle(color: AppColors.crema)),
              subtitle: Text(
                quedan == 1 ? 'Puedes añadir una más' : 'Puedes elegir varias, hasta $quedan',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.crema.withValues(alpha: 0.5),
                ),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                // `limit` hace que el propio selector del teléfono no deje
                // marcar de más, que es mejor que corregirlo después.
                final picked = await _picker.pickMultiImage(imageQuality: 70, limit: quedan);
                if (picked.isEmpty || !mounted) return;
                // Hay plataformas que ignoran el tope. Si eligió de más, se
                // quedan las primeras y se avisa: mejor eso que perder la
                // selección entera.
                final sobran = picked.length > quedan;
                setState(() {
                  _photoPaths.addAll(picked.take(quedan).map((x) => x.path));
                  _error = sobran ? 'Sólo caben $_maxPhotos imágenes en un informe.' : null;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.dorado),
              title: const Text('Cámara', style: TextStyle(color: AppColors.crema)),
              onTap: () async {
                Navigator.pop(sheetContext);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (picked != null && mounted) {
                  setState(() => _photoPaths.add(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // El devocional se sostiene en la captura: sin ella no hay constancia de
    // la lectura. Se avisa aquí y no al enviar, que es cuando el servidor lo
    // rechazaría, para no hacerle rehacer el camino.
    if (_isDevotional && _photoPaths.isEmpty && _existingUrls.isEmpty) {
      setState(() => _error = 'Adjunta la captura de la lectura.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    // Un solo día: se manda como principio y fin del periodo, que es lo que
    // el servidor guarda. Ya no hay dos fechas que puedan quedar del revés,
    // así que tampoco hace falta comprobarlo.
    final fecha = _isoDate(_reportDate);

    try {
      await ref
          .read(leaderRepositoryProvider)
          .saveReport(
            cellId: widget.cellId,
            reportId: widget.report?.id,
            kind: _kind,
            periodStart: fecha,
            periodEnd: fecha,
            summary: _summary.text,
            highlights: _highlights.text,
            challenges: _challenges.text,
            prayerNeeds: _prayerNeeds.text,
            photoPaths: _photoPaths,
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
          prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.dorado, size: 19),
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

/// Las fotos de la reunión: al coordinador le dicen más que cualquier resumen.
///
/// Mientras no se elija ninguna nueva se siguen viendo las ya guardadas, y se
/// dice en claro que quedan como están: elegir otras las reemplaza todas, y
/// eso no debería descubrirse después de guardar.
class _PhotoPicker extends StatelessWidget {
  final List<String> localPaths;
  final List<String> existingUrls;
  final int maxPhotos;
  final bool isDevotional;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  const _PhotoPicker({
    required this.localPaths,
    required this.existingUrls,
    required this.maxPhotos,
    required this.isDevotional,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final eligiendo = localPaths.isNotEmpty;
    final mostrandoGuardadas = !eligiendo && existingUrls.isNotEmpty;
    final lleno = localPaths.length >= maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              isDevotional ? 'CAPTURA DE LA LECTURA *' : 'FOTOS DE LA REUNIÓN',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.doradoClaro,
                letterSpacing: 0.9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (eligiendo)
              Text(
                '${localPaths.length} de $maxPhotos',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.crema.withValues(alpha: 0.45),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (eligiendo) ...[
          _Thumbnails(
            count: localPaths.length,
            builder: (index) =>
                Image.file(File(localPaths[index]), height: 92, width: 92, fit: BoxFit.cover),
            onRemove: onRemove,
          ),
          const SizedBox(height: 10),
        ] else if (mostrandoGuardadas) ...[
          _Thumbnails(
            count: existingUrls.length,
            builder: (index) => Image.network(
              existingUrls[index],
              height: 92,
              width: 92,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 92,
                width: 92,
                child: Icon(Icons.broken_image_outlined, color: AppColors.crema),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ya adjuntadas. Si eliges otras, estas se reemplazan.',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.crema.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 10),
        ],

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.dorado,
            side: BorderSide(color: AppColors.dorado.withValues(alpha: lleno ? 0.2 : 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: lleno ? null : onPick,
          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
          label: Text(
            lleno
                ? 'YA SON $maxPhotos'
                : eligiendo
                ? 'AÑADIR OTRA'
                : isDevotional
                ? 'ADJUNTAR LA CAPTURA'
                : 'ADJUNTAR FOTOS',
          ),
        ),
      ],
    );
  }
}

/// Tira de miniaturas, con su aspa para quitar la que sobra.
class _Thumbnails extends StatelessWidget {
  final int count;
  final Widget Function(int index) builder;
  final ValueChanged<int>? onRemove;

  const _Thumbnails({required this.count, required this.builder, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => Stack(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: builder(index)),
            if (onRemove != null)
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onRemove!(index),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.deepTeal.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 15, color: AppColors.crema),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Las imágenes de un informe ya guardado, para verlas en grande al tocarlas.
class _ReportGallery extends StatelessWidget {
  final List<String> urls;

  const _ReportGallery({required this.urls});

  @override
  Widget build(BuildContext context) {
    // Una sola imagen se ve entera y ancha; varias, en tira.
    if (urls.length == 1) {
      return GestureDetector(
        onTap: () => _open(context, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            urls.first,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _open(context, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              urls[index],
              height: 110,
              width: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 110,
                width: 140,
                child: Icon(Icons.broken_image_outlined, color: AppColors.crema),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, int index) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.network(
                urls[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.crema),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      ),
    );
  }
}

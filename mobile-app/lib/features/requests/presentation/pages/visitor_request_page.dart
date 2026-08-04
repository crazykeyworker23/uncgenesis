import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/storage/local_requests_store.dart';
import '../../../../core/utils/api_error.dart';
import '../providers/requests_provider.dart';
import '../../data/models/requests_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cells/presentation/providers/cells_provider.dart';

class VisitorRequestPage extends ConsumerStatefulWidget {
  const VisitorRequestPage({super.key});

  @override
  ConsumerState<VisitorRequestPage> createState() => _VisitorRequestPageState();
}

class _VisitorRequestPageState extends ConsumerState<VisitorRequestPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _messageController;

  String _ageRange = 'PREFER_NOT_SAY';
  String _howFound = 'OTHER';
  String _preferredContact = 'WHATSAPP';
  int? _selectedCellId;
  String? _selectedCellName;

  final _ageRanges = [
    {'label': '15-25 años', 'value': 'YOUTH'},
    {'label': '26-35 años', 'value': 'YOUNG_ADULT'},
    {'label': '36-50 años', 'value': 'ADULT'},
    {'label': '51+ años', 'value': 'SENIOR'},
    {'label': 'Prefiero no decir', 'value': 'PREFER_NOT_SAY'},
  ];

  final _howFoundOptions = [
    {'label': 'Redes sociales', 'value': 'SOCIAL_MEDIA'},
    {'label': 'Amigo o familiar', 'value': 'FRIEND_FAMILY'},
    {'label': 'Página web', 'value': 'WEBSITE'},
    {'label': 'Pasé por la iglesia', 'value': 'STREET'},
    {'label': 'Evento', 'value': 'EVENT'},
    {'label': 'Otro', 'value': 'OTHER'},
  ];

  final _contactOptions = [
    {'label': 'Correo electrónico', 'value': 'EMAIL'},
    {'label': 'Llamada telefónica', 'value': 'PHONE'},
    {'label': 'WhatsApp', 'value': 'WHATSAPP'},
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _messageController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      authState.maybeWhen(
        authenticated: (user) {
          if (mounted) {
            setState(() {
              _fullNameController.text = user.fullName;
              _emailController.text = user.email;
              _phoneController.text = user.phone ?? '';
            });
          }
        },
        orElse: () {},
      );
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cellsState = ref.watch(cellsProvider);
    final statusAsync = ref.watch(cellStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiero ser visitado / Información'),
      ),
      body: statusAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.dorado),
        ),
        error: (_, __) => _buildFormContent(cellsState),
        data: (statusData) {
          final assignedCell = statusData['assigned_cell'];
          final pendingRequest = statusData['pending_request'];

          if (assignedCell != null) {
            return _buildAssignedCellCard(assignedCell);
          }

          if (pendingRequest != null) {
            return _buildPendingRequestCard(pendingRequest);
          }

          return _buildFormContent(cellsState);
        },
      ),
    );
  }

  Widget _buildAssignedCellCard(Map<String, dynamic> cell) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dorado.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.groups_rounded, size: 64, color: AppColors.dorado),
            const SizedBox(height: 16),
            Text(
              '¡Ya perteneces a una Célula!',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.dorado,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              cell['name'] ?? 'Tu Célula Asignada',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.crema),
            ),
            const SizedBox(height: 8),
            Text(
              'Reunión: ${cell['meeting_day'] ?? ''} • ${DateFormatter.clockTime(cell['meeting_time'])} HS\nDirección: ${cell['address'] ?? ''}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Actualmente formas parte activa de este grupo celular. Si deseas coordinar un cambio de grupo o distrito, por favor comunícate directamente con tu líder.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.doradoClaro),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestCard(Map<String, dynamic> req) {
    final cellInfo = req['cell_group'];
    final cellName = cellInfo != null ? cellInfo['name'] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dorado.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 64, color: AppColors.dorado),
            const SizedBox(height: 16),
            Text(
              'Solicitud en Revisión',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.dorado,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              cellName != null
                  ? 'Has solicitado unirte a la célula:\n"$cellName"'
                  : 'Tu solicitud de visita e integración está siendo procesada.',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.crema),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.darkTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'El equipo pastoral está revisando tu solicitud. Nos pondremos en contacto contigo muy pronto por el medio de contacto elegido.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.doradoClaro),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent(CellsState cellsState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.dorado.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.home, color: AppColors.dorado, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '¿Quieres que te visitemos?',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.dorado,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Déjanos tus datos de contacto y selecciona una célula de interés o cuéntanos cómo podemos ayudarte (visita pastoral, consejería, bautismos).',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.crema.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo *',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.dorado),
              ),
              style: AppTextStyles.bodyMedium,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Por favor ingresa tu nombre' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico *',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.dorado),
              ),
              style: AppTextStyles.bodyMedium,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Por favor ingresa tu correo' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono / Celular *',
                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.dorado),
              ),
              style: AppTextStyles.bodyMedium,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Por favor ingresa tu teléfono' : null,
            ),
            const SizedBox(height: 16),

            // Cell Selector Dropdown
            DropdownButtonFormField<int?>(
              initialValue: _selectedCellId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Célula de Interés (Opcional)',
                prefixIcon: Icon(Icons.groups_outlined, color: AppColors.dorado),
              ),
              dropdownColor: AppColors.cardColor,
              style: AppTextStyles.bodyMedium,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Ninguna en particular / General', style: TextStyle(color: AppColors.crema)),
                ),
                ...cellsState.cells.map((cell) {
                  return DropdownMenuItem<int?>(
                    value: cell.id,
                    child: Text(
                      cell.name,
                      style: const TextStyle(color: AppColors.crema),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCellId = value;
                  if (value != null) {
                    final cell = cellsState.cells.firstWhere((c) => c.id == value);
                    _selectedCellName = cell.name;
                  } else {
                    _selectedCellName = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _ageRange,
              decoration: const InputDecoration(
                labelText: 'Rango de Edad',
                prefixIcon: Icon(Icons.cake_outlined, color: AppColors.dorado),
              ),
              dropdownColor: AppColors.cardColor,
              style: AppTextStyles.bodyMedium,
              items: _ageRanges.map((opt) {
                return DropdownMenuItem(
                  value: opt['value'],
                  child: Text(opt['label']!, style: const TextStyle(color: AppColors.crema)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _ageRange = value!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _howFound,
              decoration: const InputDecoration(
                labelText: '¿Cómo nos conociste?',
                prefixIcon: Icon(Icons.explore_outlined, color: AppColors.dorado),
              ),
              dropdownColor: AppColors.cardColor,
              style: AppTextStyles.bodyMedium,
              items: _howFoundOptions.map((opt) {
                return DropdownMenuItem(
                  value: opt['value'],
                  child: Text(opt['label']!, style: const TextStyle(color: AppColors.crema)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _howFound = value!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _preferredContact,
              decoration: const InputDecoration(
                labelText: 'Medio de Contacto Preferido',
                prefixIcon: Icon(Icons.contact_phone_outlined, color: AppColors.dorado),
              ),
              dropdownColor: AppColors.cardColor,
              style: AppTextStyles.bodyMedium,
              items: _contactOptions.map((opt) {
                return DropdownMenuItem(
                  value: opt['value'],
                  child: Text(opt['label']!, style: const TextStyle(color: AppColors.crema)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _preferredContact = value!),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mensaje o motivo de la visita *',
                hintText: 'Cuéntanos brevemente cómo podemos apoyarte...',
                alignLabelWithHint: true,
              ),
              style: AppTextStyles.bodyMedium,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Por favor ingresa tu mensaje' : null,
            ),
            const SizedBox(height: 28),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dorado,
                foregroundColor: AppColors.deepTeal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepTeal),
                    )
                  : const Icon(Icons.send_rounded, color: AppColors.deepTeal),
              label: Text(
                _isSubmitting ? 'ENVIANDO...' : 'ENVIAR SOLICITUD',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.deepTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final rawMessage = _messageController.text.trim();
      final finalMessage = _selectedCellName != null
          ? '[Célula solicitada: $_selectedCellName]\n$rawMessage'
          : rawMessage;

      try {
        final repo = ref.read(requestsRepositoryProvider);
        await repo.submitVisitorRequest(VisitorRequestModel(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          ageRange: _ageRange,
          howDidYouFindUs: _howFound,
          message: finalMessage,
          preferredContact: _preferredContact,
          cellGroupId: _selectedCellId,
        ));

        ref.invalidate(cellStatusProvider);

        // Queda registrada en "Mis Solicitudes" (también en modo invitado).
        await ref.read(submittedRequestsProvider.notifier).add(
              type: SubmittedRequestType.visitor,
              subject: _selectedCellName != null
                  ? 'Quiero integrarme a la célula $_selectedCellName'
                  : 'Solicitud de visita / información',
              detail: rawMessage,
            );

        if (mounted) {
          _showSuccessDialog();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  ApiError.message(e, fallback: 'No pudimos enviar tu solicitud. Intenta de nuevo.'),
                ),
                backgroundColor: AppColors.error,
              ),
            );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dorado.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.dorado, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Solicitud Registrada!',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.dorado,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Gracias por escribirnos. Un líder de la iglesia se pondrá en contacto contigo muy pronto.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/connect');
              }
            },
            child: Text(
              'ACEPTAR',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.dorado),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/storage/local_requests_store.dart';
import '../../../../core/utils/api_error.dart';
import '../providers/requests_provider.dart';
import '../../data/models/requests_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PrayerRequestPage extends ConsumerStatefulWidget {
  const PrayerRequestPage({super.key});

  @override
  ConsumerState<PrayerRequestPage> createState() => _PrayerRequestPageState();
}

class _PrayerRequestPageState extends ConsumerState<PrayerRequestPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;

  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      authState.maybeWhen(
        authenticated: (user) {
          if (mounted) {
            setState(() {
              _nameController.text = user.fullName;
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Petición de Oración'),
      ),
      body: SingleChildScrollView(
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
                        const Icon(Icons.favorite, color: AppColors.dorado, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          '¿En qué podemos orar por ti?',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.dorado,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escribe tu motivo de oración. Nuestro equipo ministerial e intercesores estarán orando por ti con confidencialidad y fe.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Anonymous switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Enviar de forma anónima',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.white),
                  ),
                  subtitle: const Text(
                    'Tu nombre no será compartido públicamente',
                    style: TextStyle(fontSize: 11, color: AppColors.crema),
                  ),
                  value: _isAnonymous,
                  onChanged: (val) {
                    setState(() {
                      _isAnonymous = val;
                    });
                  },
                  activeThumbColor: AppColors.dorado,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 20),

              // Contact fields (shown if not anonymous)
              if (!_isAnonymous) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tu Nombre Completo *',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.dorado),
                  ),
                  style: AppTextStyles.bodyMedium,
                  validator: (value) {
                    if (!_isAnonymous && (value == null || value.trim().isEmpty)) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Tu Correo Electrónico (Opcional)',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.dorado),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Tu Teléfono / WhatsApp (Opcional)',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.dorado),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
              ],

              // Subject Field
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Asunto o Motivo de Oración *',
                  hintText: 'Ej. Salud, familia, empleo, dirección espiritual',
                  prefixIcon: Icon(Icons.title, color: AppColors.dorado),
                ),
                style: AppTextStyles.bodyMedium,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor escribe el asunto de la petición';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Detalle de la Petición *',
                  hintText: 'Escribe los detalles por los que deseas que oremos...',
                  alignLabelWithHint: true,
                ),
                style: AppTextStyles.bodyMedium,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor detalla tu motivo de oración';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Submit Button
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
                  _isSubmitting ? 'ENVIANDO...' : 'ENVIAR PETICIÓN DE ORACIÓN',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final requesterName = _isAnonymous
          ? 'Anónimo'
          : (_nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : 'Hermano/a en Cristo');

      try {
        final repo = ref.read(requestsRepositoryProvider);
        await repo.submitPrayerRequest(PrayerRequestModel(
          requesterName: requesterName,
          requesterEmail: _isAnonymous ? '' : _emailController.text.trim(),
          requesterPhone: _isAnonymous ? '' : _phoneController.text.trim(),
          subject: _subjectController.text.trim(),
          description: _descriptionController.text.trim(),
          isAnonymous: _isAnonymous,
        ));

        // Queda registrada en "Mis Solicitudes" (también en modo invitado).
        await ref.read(submittedRequestsProvider.notifier).add(
              type: SubmittedRequestType.prayer,
              subject: _subjectController.text.trim(),
              detail: _descriptionController.text.trim(),
              isAnonymous: _isAnonymous,
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
                  ApiError.message(e, fallback: 'No pudimos enviar tu petición. Intenta de nuevo.'),
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
              '¡Petición Enviada!',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.dorado,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tu motivo de oración ha sido recibido por nuestro equipo ministerial.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deepTeal,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dorado.withValues(alpha: 0.3)),
              ),
              child: Text(
                '"Por nada estéis afanosos, sino sean conocidas vuestras peticiones delante de Dios en toda oración y ruego." (Filipenses 4:6)',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.dorado,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Cierra el diálogo
              // Si la pantalla se abrió como destino inicial no hay nada que
              // desapilar: se navega explícitamente a Conectar.
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

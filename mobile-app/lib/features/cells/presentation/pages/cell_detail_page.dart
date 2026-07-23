import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/cells_provider.dart';
import '../../data/models/cell_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../requests/presentation/providers/requests_provider.dart';
import '../../../requests/data/models/requests_model.dart';

class CellDetailPage extends ConsumerWidget {
  final String id; // This is the cell slug

  const CellDetailPage({super.key, required this.id});

  String _translateDay(String day) {
    switch (day) {
      case 'MONDAY':
        return 'Lunes';
      case 'TUESDAY':
        return 'Martes';
      case 'WEDNESDAY':
        return 'Miércoles';
      case 'THURSDAY':
        return 'Jueves';
      case 'FRIDAY':
        return 'Viernes';
      case 'SATURDAY':
        return 'Sábado';
      case 'SUNDAY':
        return 'Domingo';
      default:
        return day;
    }
  }

  Future<void> _openMap(BuildContext context, String address) async {
    try {
      final query = Uri.encodeComponent(address);
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } catch (_) {}
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el mapa para: $address')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir mapa: $e')),
        );
      }
    }
  }

  void _showJoinRequestDialog(BuildContext context, WidgetRef ref, CellGroupModel cell) {
    final authState = ref.read(authProvider);
    final user = authState.maybeWhen(
      authenticated: (u) => u,
      orElse: () => null,
    );

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final messageController = TextEditingController(text: 'Hola, me gustaría unirme a la célula "${cell.name}".');

    String ageRange = 'PREFER_NOT_SAY';
    String howFound = 'OTHER';
    String preferredContact = 'WHATSAPP';

    final ageRanges = [
      {'label': '15-25 años', 'value': 'YOUTH'},
      {'label': '26-35 años', 'value': 'YOUNG_ADULT'},
      {'label': '36-50 años', 'value': 'ADULT'},
      {'label': '51+ años', 'value': 'SENIOR'},
      {'label': 'Prefiero no decir', 'value': 'PREFER_NOT_SAY'},
    ];

    final howFoundOptions = [
      {'label': 'Redes sociales', 'value': 'SOCIAL_MEDIA'},
      {'label': 'Amigo o familiar', 'value': 'FRIEND_FAMILY'},
      {'label': 'Página web', 'value': 'WEBSITE'},
      {'label': 'Pasé por la iglesia', 'value': 'STREET'},
      {'label': 'Evento', 'value': 'EVENT'},
      {'label': 'Otro', 'value': 'OTHER'},
    ];

    final contactOptions = [
      {'label': 'Correo electrónico', 'value': 'EMAIL'},
      {'label': 'Llamada telefónica', 'value': 'PHONE'},
      {'label': 'WhatsApp', 'value': 'WHATSAPP'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.groups, color: AppColors.dorado),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unirme a Célula',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.dorado,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Envía tus datos y el líder de la célula "${cell.name}" se contactará contigo.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nombre Completo *'),
                        style: AppTextStyles.bodyMedium,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico *'),
                        style: AppTextStyles.bodyMedium,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa tu correo' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp *'),
                        style: AppTextStyles.bodyMedium,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa tu teléfono' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: ageRange,
                        decoration: const InputDecoration(labelText: 'Rango de Edad'),
                        dropdownColor: AppColors.cardColor,
                        style: AppTextStyles.bodyMedium,
                        items: ageRanges.map((opt) {
                          return DropdownMenuItem(
                            value: opt['value'],
                            child: Text(opt['label']!, style: const TextStyle(color: AppColors.crema)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => ageRange = value!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: howFound,
                        decoration: const InputDecoration(labelText: '¿Cómo nos conociste?'),
                        dropdownColor: AppColors.cardColor,
                        style: AppTextStyles.bodyMedium,
                        items: howFoundOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt['value'],
                            child: Text(opt['label']!, style: const TextStyle(color: AppColors.crema)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => howFound = value!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: preferredContact,
                        decoration: const InputDecoration(labelText: 'Contacto Preferido'),
                        dropdownColor: AppColors.cardColor,
                        style: AppTextStyles.bodyMedium,
                        items: contactOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt['value'],
                            child: Text(opt['label']!, style: const TextStyle(color: AppColors.crema)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => preferredContact = value!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: messageController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Mensaje o Comentarios'),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('CANCELAR', style: TextStyle(color: AppColors.crema)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isSubmitting = true);

                            try {
                              final repo = ref.read(requestsRepositoryProvider);
                              await repo.submitVisitorRequest(VisitorRequestModel(
                                fullName: nameController.text.trim(),
                                email: emailController.text.trim(),
                                phone: phoneController.text.trim(),
                                ageRange: ageRange,
                                howDidYouFindUs: howFound,
                                message: messageController.text.trim(),
                                preferredContact: preferredContact,
                                cellGroupId: cell.id,
                              ));

                              ref.invalidate(cellStatusProvider);

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('¡Solicitud enviada con éxito! El equipo pastoral se contactará contigo.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al enviar la solicitud: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } finally {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dorado,
                    foregroundColor: AppColors.deepTeal,
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepTeal))
                      : const Text('ENVIAR SOLICITUD', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(cellDetailProvider(id));
    final cellStatusAsync = ref.watch(cellStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Célula'),
      ),
      body: detailAsync.when(
        data: (cell) => _CellDetailBody(
          cell: cell,
          cellStatusAsync: cellStatusAsync,
          onOpenMap: () => _openMap(context, cell.address),
          onJoinRequest: () => _showJoinRequestDialog(context, ref, cell),
          translateDay: _translateDay,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.dorado),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error al cargar la célula: $err', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(cellDetailProvider(id)),
                child: const Text('REINTENTAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CellDetailBody extends StatelessWidget {
  final CellGroupModel cell;
  final AsyncValue<Map<String, dynamic>> cellStatusAsync;
  final VoidCallback onOpenMap;
  final VoidCallback onJoinRequest;
  final String Function(String) translateDay;

  const _CellDetailBody({
    required this.cell,
    required this.cellStatusAsync,
    required this.onOpenMap,
    required this.onJoinRequest,
    required this.translateDay,
  });

  @override
  Widget build(BuildContext context) {
    final leaderName = cell.leader != null ? cell.leader!.fullName : 'Equipo Pastoral';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Card
          Card(
            color: AppColors.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.dorado.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.dorado.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.groups_rounded, color: AppColors.dorado, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    cell.name,
                    style: AppTextStyles.titleLarge.copyWith(fontSize: 22, color: AppColors.dorado),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.darkTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 16, color: AppColors.dorado),
                        const SizedBox(width: 6),
                        Text(
                          'Líder: $leaderName',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.crema,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Schedule Row
          _CellInfoRow(
            icon: Icons.calendar_today,
            title: 'Día de Reunión',
            subtitle: translateDay(cell.meetingDay),
          ),
          const SizedBox(height: 16),

          // 3. Time Row
          _CellInfoRow(
            icon: Icons.access_time,
            title: 'Hora de Reunión',
            subtitle: '${cell.meetingTime.substring(0, 5)} HS',
          ),
          const SizedBox(height: 16),

          // 4. Location Row
          GestureDetector(
            onTap: onOpenMap,
            child: _CellInfoRow(
              icon: Icons.location_on_outlined,
              title: 'Dirección (Toca para abrir en Mapa)',
              subtitle: cell.address,
              subtitleColor: AppColors.doradoClaro,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.darkTeal),
          const SizedBox(height: 16),

          // Description
          if (cell.description != null && cell.description!.isNotEmpty) ...[
            Text(
              'DESCRIPCIÓN DE LA CÉLULA',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.dorado, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            Text(
              cell.description!,
              style: AppTextStyles.bodyLarge.copyWith(height: 1.5, color: AppColors.crema),
            ),
            const SizedBox(height: 36),
          ],

          // 5. Dynamic Action Button / Status Banner
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final statusData = cellStatusAsync.value;
    final assignedCell = statusData?['assigned_cell'];
    final pendingRequest = statusData?['pending_request'];

    if (assignedCell != null) {
      final isThisCell = assignedCell['id'] == cell.id;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dorado.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(
              isThisCell ? Icons.check_circle_rounded : Icons.groups_rounded,
              color: AppColors.dorado,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              isThisCell
                  ? '¡YA ERES MIEMBRO DE ESTA CÉLULA!'
                  : 'YA FORMAS PARTE DE OTRA CÉLULA',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.dorado,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isThisCell
                  ? 'Formas parte activa de este grupo celular. ¡Nos vemos en la próxima reunión!'
                  : 'Actualmente estás asignado a la célula "${assignedCell['name']}". Si deseas solicitar un cambio, por favor comunícate directamente con tu líder.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.8),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (pendingRequest != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dorado.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.dorado,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              'SOLICITUD EN REVISIÓN',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.dorado,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Ya enviaste una solicitud de integración. El equipo pastoral la está revisando y se contactará contigo muy pronto.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.8),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onJoinRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.dorado,
        foregroundColor: AppColors.deepTeal,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.group_add_rounded, color: AppColors.deepTeal),
      label: Text(
        'SOLICITAR UNIRME A ESTA CÉLULA',
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.deepTeal,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CellInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? subtitleColor;

  const _CellInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.dorado.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: AppColors.dorado, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: subtitleColor ?? AppColors.crema,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

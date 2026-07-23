import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/requests_provider.dart';

class ConnectPage extends ConsumerWidget {
  const ConnectPage({super.key});

  Future<void> _openWhatsApp(String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'[+\s]'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber?text=Hola,%20quisiera%20contactar%20con%20la%20iglesia%20Génesis.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(publicSettingsProvider);
    final cellStatusAsync = ref.watch(cellStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conéctate con Nosotros'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // "Mi Célula" Banner if assigned
            cellStatusAsync.maybeWhen(
              data: (statusData) {
                final assignedCell = statusData['assigned_cell'];
                if (assignedCell == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dorado.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.darkTeal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.groups_rounded, color: AppColors.dorado, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi Célula Asignada',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.dorado, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assignedCell['name'] ?? '',
                              style: AppTextStyles.titleMedium.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${assignedCell['meeting_day']} • ${assignedCell['address']}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema.withValues(alpha: 0.7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Welcome text
            Text(
              'Estamos aquí para servirte',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.dorado, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona una de las opciones a continuación para contactar al equipo ministerial, enviar tu petición de oración o buscar una célula de comunión.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),

            // Card 1: Prayer request
            _ConnectActionCard(
              title: 'Petición de Oración',
              subtitle: 'Envía tus motivos de oración a nuestro equipo ministerial.',
              icon: Icons.favorite,
              onTap: () => context.push('/requests/prayer'),
            ),
            const SizedBox(height: 16),

            // Card 2: Visitor/Info request
            _ConnectActionCard(
              title: 'Quiero que me visiten / Más información',
              subtitle: 'Solicita una visita pastoral, consejería o información de la iglesia.',
              icon: Icons.home,
              onTap: () => context.push('/requests/visitor'),
            ),
            const SizedBox(height: 16),

            // Card 3: Find a cell
            _ConnectActionCard(
              title: 'Células de Hogar',
              subtitle: 'Encuentra un grupo celular cercano a tu domicilio para integrarte.',
              icon: Icons.people_alt,
              onTap: () => context.push('/cells'),
            ),
            const SizedBox(height: 32),

            // WhatsApp section
            settingsAsync.maybeWhen(
              data: (settings) {
                final phone = settings.church.whatsapp.isNotEmpty ? settings.church.whatsapp : settings.church.phone;
                if (phone.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '¿Prefieres chatear por WhatsApp?',
                        style: TextStyle(
                          color: AppColors.crema,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Escríbenos directamente a nuestra línea oficial.',
                        style: TextStyle(
                          color: AppColors.crema.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.chat),
                        label: const Text('ESCRIBIR POR WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _openWhatsApp(phone),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ConnectActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.darkTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.dorado, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.5),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_outlined, color: AppColors.dorado, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

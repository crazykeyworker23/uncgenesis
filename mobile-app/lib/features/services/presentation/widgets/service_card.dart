import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/service_model.dart';
import '../pages/service_detail_page.dart';

/// Tarjeta de un servicio en un listado.
///
/// Vive aparte de la pantalla de Servicios porque también se usa en el feed de
/// Publicaciones: al filtrar por «Servicios» ahí salían las publicaciones
/// etiquetadas como tal, que es otra cosa, y los cultos de verdad no aparecían
/// por ningún lado sin cambiar de sección.
class ServiceCard extends StatelessWidget {
  final ChurchServiceModel service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: service.isLive
              ? Colors.redAccent
              : AppColors.dorado.withValues(alpha: 0.2),
          width: service.isLive ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ServiceDetailPage(slug: service.slug),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Status Badge or Date Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (service.isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent, width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.live_tv, size: 14, color: Colors.redAccent),
                          SizedBox(width: 4),
                          Text(
                            'EN VIVO',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.dorado),
                        const SizedBox(width: 6),
                        Text(
                          // Llega del servidor como «2026-08-03»: se mostraba
                          // tal cual, en crudo.
                          DateFormatter.longDate(service.date, fallback: service.date),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.dorado,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.crema),
                      const SizedBox(width: 4),
                      Text(
                        '${service.viewsCount}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                service.title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Sermon Notes Snippet
              if (service.sermonNotes != null && service.sermonNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  service.sermonNotes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.crema.withValues(alpha: 0.8),
                  ),
                ),
              ],

              // Verses Chips
              if (service.verses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: service.verses.map((v) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.dorado.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.dorado.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${v.book} ${v.chapter}:${v.verses}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.dorado,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(color: Colors.white10),

              // Bottom Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (service.videoUrl != null)
                        const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_fill, size: 16, color: AppColors.dorado),
                              SizedBox(width: 4),
                              Text('Video', style: TextStyle(fontSize: 12, color: AppColors.crema)),
                            ],
                          ),
                        ),
                      if (service.audioUrl != null)
                        const Row(
                          children: [
                            Icon(Icons.headphones, size: 16, color: AppColors.dorado),
                            SizedBox(width: 4),
                            Text('Audio', style: TextStyle(fontSize: 12, color: AppColors.crema)),
                          ],
                        ),
                    ],
                  ),

                  Row(
                    children: [
                      Text(
                        'Ver Prédica',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.dorado,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.dorado),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

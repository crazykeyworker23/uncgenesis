import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/leader_models.dart';
import '../providers/leader_providers.dart';

/// Aviso al pie de la pantalla tras una acción.
///
/// El texto suele venir del servidor —«Recordatorio enviado a 12 miembro(s)»—,
/// que sabe lo que la app no: a cuánta gente llegó.
void showLeaderMessage(BuildContext context, String text, {bool isError = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.error : AppColors.darkTeal,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
}

/// Cabecera con la célula sobre la que se trabaja.
///
/// Quien lidera una sola célula ve su nombre; quien supervisa varias puede
/// cambiar de una a otra desde aquí.
class LeaderCellHeader extends ConsumerWidget {
  const LeaderCellHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cells = ref.watch(myCellsProvider).valueOrNull?.cells ?? const <LeaderCell>[];
    final active = ref.watch(activeCellProvider);
    if (active == null) return const SizedBox.shrink();

    final schedule = [
      if (active.dayLabel.isNotEmpty) active.dayLabel,
      if (active.meetingTime.isNotEmpty) _clock(active.meetingTime),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dorado.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: AppColors.dorado, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active.name,
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.doradoClaro),
                ),
                if (schedule.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    schedule,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.crema.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (cells.length > 1)
            PopupMenuButton<int>(
              color: AppColors.cardColor,
              icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.dorado),
              tooltip: 'Cambiar de célula',
              onSelected: (id) => ref.read(selectedCellIdProvider.notifier).state = id,
              itemBuilder: (context) => [
                for (final cell in cells)
                  PopupMenuItem<int>(
                    value: cell.id,
                    child: Text(
                      cell.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: cell.id == active.id ? AppColors.dorado : AppColors.crema,
                        fontWeight: cell.id == active.id ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static String _clock(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

/// Acceso a una de las secciones de la gestión de célula.
class LeaderSectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const LeaderSectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.dorado.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.dorado, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.dorado.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.doradoClaro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right, color: AppColors.dorado, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cifra suelta dentro del resumen de la célula.
class LeaderStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? tone;

  const LeaderStatTile({super.key, required this.label, required this.value, this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.crema.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: tone ?? AppColors.dorado,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.crema.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección sin contenido todavía.
class LeaderEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const LeaderEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: AppColors.dorado.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.doradoClaro),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.crema.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallo al cargar, con la opción de volver a intentarlo.
class LeaderErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LeaderErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dorado,
                side: const BorderSide(color: AppColors.dorado),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rueda de carga centrada, con el color de la marca.
class LeaderLoading extends StatelessWidget {
  const LeaderLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(color: AppColors.dorado),
        ),
      );
}

/// Título de un bloque dentro de una pantalla.
class LeaderSectionLabel extends StatelessWidget {
  final String text;

  const LeaderSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.doradoClaro,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}

/// Círculo con las iniciales de una persona.
class LeaderAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? background;

  const LeaderAvatar({super.key, required this.initials, this.size = 40, this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? AppColors.dorado.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.doradoClaro,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

/// Botón de acción principal de una pantalla del módulo.
class LeaderPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isBusy;
  final VoidCallback? onPressed;

  const LeaderPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    this.isBusy = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isBusy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.dorado,
        foregroundColor: AppColors.deepTeal,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepTeal),
            )
          : Icon(icon, color: AppColors.deepTeal, size: 19),
      label: Text(
        isBusy ? 'GUARDANDO...' : label,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.deepTeal,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Hoja inferior donde se rellenan los formularios de la sección.
///
/// Deja sitio al teclado y no pasa de la altura de la pantalla, que era lo que
/// dejaba los últimos campos inalcanzables en teléfonos pequeños.
class LeaderFormSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const LeaderFormSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Cada medida por su lado. Con `MediaQuery.of` se despierta por cualquier
    // cambio, y el hueco del teclado se anima: la hoja entera se reconstruía
    // en cada fotograma. El contenido llega hecho desde fuera, así que aun así
    // Flutter reutiliza su rama; lo que se evita es rehacer el resto.
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.darkTeal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + viewInsets),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.crema.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: AppTextStyles.titleMedium.copyWith(color: AppColors.doradoClaro)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.crema.withValues(alpha: 0.55),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla de respaldo al abrir una sección sin célula resuelta.
class LeaderMissingCellScaffold extends StatelessWidget {
  final String title;

  const LeaderMissingCellScaffold({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const LeaderEmptyState(
        icon: Icons.groups_outlined,
        title: 'No hay ninguna célula seleccionada',
        message: 'Vuelve a «Mi Célula» y elige una para continuar.',
      ),
    );
  }
}

/// Barra con el nombre de la célula bajo el título de la pantalla.
PreferredSizeWidget leaderCellSubtitle(String cellName) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(22),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        cellName,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema.withValues(alpha: 0.6)),
      ),
    ),
  );
}

/// Pregunta de confirmación antes de una acción que no se deshace.
Future<bool> confirmLeaderAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'CONTINUAR',
  bool isDestructive = false,
}) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: AppTextStyles.titleMedium),
      content: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('CANCELAR', style: TextStyle(color: AppColors.crema)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: isDestructive ? AppColors.error : AppColors.dorado),
          ),
        ),
      ],
    ),
  );
  return answer == true;
}

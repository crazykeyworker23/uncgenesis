import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_images.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Cierra la pantalla de acceso volviendo a donde estaba la persona.
  void _leaveLogin(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).login(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    // Al autenticarse se vuelve a la pantalla desde la que se pidió el acceso
    // (por ejemplo el detalle de un evento) en lugar de mandar siempre al
    // inicio y perder lo que la persona estaba haciendo.
    ref.listen<AuthState>(authProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user) => _leaveLogin(context),
        guest: () => _leaveLogin(context),
        error: (message) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
        },
        orElse: () {},
      );
    });

    final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

    // El fondo se queda quieto: vive fuera del `Scaffold` y en su propia capa.
    //
    // Al tocar un campo se abre el teclado y el cuerpo del Scaffold se encoge
    // para dejarle sitio. Con la imagen dentro, esos 10 MB se reescalaban en
    // cada fotograma de la animación. Y con el velo oscuro suelto, encima
    // había que volver a mezclarlo a pantalla completa otras tantas veces.
    // Ahora foto y velo son una sola capa que nadie toca, y el formulario va
    // en la suya: el teclado sólo mueve el formulario.
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base opaca: la daba el `Scaffold` cuando el fondo vivía dentro. Si
        // la foto no cargara, detrás no puede quedar el vacío.
        const ColoredBox(color: AppColors.darkGreen),
        AppBackground('assets/images/splash_bg.png', overlay: AppColors.darkGreen.withValues(alpha: 0.65)),

        RepaintBoundary(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Content
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header logo + text
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AppLogo(size: 38),
                                const SizedBox(width: 8),
                                Text(
                                  'GÉNESIS APP',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    letterSpacing: 2.0,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 48),

                            // Cursive Titles: Accede a Génesis
                            Center(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'cursive',
                                    fontSize: 38,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.white,
                                    height: 1.15,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Accede a\n',
                                      style: TextStyle(color: AppColors.doradoClaro),
                                    ),
                                    TextSpan(
                                      text: 'Génesis',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Subtitle: Bienvenido de nuevo
                            Center(
                              child: Text(
                                'Bienvenido de nuevo ♡',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.crema.withValues(alpha: 0.7),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Email input field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !isLoading,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                              decoration: InputDecoration(
                                hintText: 'Correo electrónico',
                                hintStyle: TextStyle(color: AppColors.crema.withValues(alpha: 0.4)),
                                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.dorado),
                                filled: true,
                                fillColor: AppColors.deepTeal.withValues(alpha: 0.4),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppColors.dorado.withValues(alpha: 0.15)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.dorado, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa tu correo';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                  return 'Ingresa un correo válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password input field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              enabled: !isLoading,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                              decoration: InputDecoration(
                                hintText: 'Contraseña',
                                hintStyle: TextStyle(color: AppColors.crema.withValues(alpha: 0.4)),
                                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.dorado),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.crema.withValues(alpha: 0.5),
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: AppColors.deepTeal.withValues(alpha: 0.4),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppColors.dorado.withValues(alpha: 0.15)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.dorado, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tu contraseña';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isLoading ? null : () => context.push('/auth/forgot-password'),
                                style: TextButton.styleFrom(foregroundColor: AppColors.doradoClaro),
                                child: const Text(
                                  'Olvidé mi contraseña',
                                  style: TextStyle(fontSize: 13, decoration: TextDecoration.underline),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Iniciar Sesion Button
                            ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dorado,
                                foregroundColor: AppColors.deepTeal,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.deepTeal,
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar sesión',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                            const SizedBox(height: 16),

                            // Crear cuenta Button
                            OutlinedButton(
                              onPressed: isLoading ? null : () => context.push('/auth/register'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.dorado,
                                side: const BorderSide(color: AppColors.dorado, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text(
                                'Crear cuenta',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Continuation line divider with indicator circle
                            Row(
                              children: [
                                Expanded(child: Divider(color: AppColors.dorado.withValues(alpha: 0.15))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.dorado, width: 1.5),
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: AppColors.dorado.withValues(alpha: 0.15))),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Continue as guest
                            Center(
                              child: TextButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () => ref.read(authProvider.notifier).loginAsGuest(),
                                icon: const Icon(Icons.person_outline, size: 20),
                                label: const Text(
                                  'Continuar como invitado',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.crema.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Botón para volver cuando se llegó desde otra pantalla: antes
                // no había forma visible de regresar sin cerrar la app.
                if (context.canPop())
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 4,
                    left: 4,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.crema),
                      tooltip: 'Volver',
                      onPressed: isLoading ? null : () => context.pop(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

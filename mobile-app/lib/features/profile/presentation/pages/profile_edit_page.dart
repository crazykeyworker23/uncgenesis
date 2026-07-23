import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late String _firstName = '';
  late String _lastName = '';
  late String _phone = '';
  late String _location = '';
  late String _bio = '';
  String? _selectedImagePath;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: authState.maybeWhen(
        authenticated: (user) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Avatar selector
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: AppColors.dorado,
                          backgroundImage: _selectedImagePath != null
                              ? FileImage(File(_selectedImagePath!))
                              : (user.avatar != null ? NetworkImage(user.avatar!) : null) as ImageProvider?,
                          child: _selectedImagePath == null && user.avatar == null
                              ? Text(
                                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    color: AppColors.deepTeal,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.cardColor,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: AppColors.dorado, size: 16),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2. Personal Info fields
                  TextFormField(
                    initialValue: user.firstName,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.dorado),
                    ),
                    style: AppTextStyles.bodyMedium,
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'El nombre es requerido' : null,
                    onSaved: (value) => _firstName = value!.trim(),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: user.lastName,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.dorado),
                    ),
                    style: AppTextStyles.bodyMedium,
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'El apellido es requerido' : null,
                    onSaved: (value) => _lastName = value!.trim(),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: user.phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.dorado),
                    ),
                    style: AppTextStyles.bodyMedium,
                    onSaved: (value) => _phone = (value ?? '').trim(),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: user.location,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación / Ciudad',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.dorado),
                    ),
                    style: AppTextStyles.bodyMedium,
                    onSaved: (value) => _location = (value ?? '').trim(),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: user.bio,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Biografía / Breve presentación',
                      alignLabelWithHint: true,
                    ),
                    style: AppTextStyles.bodyMedium,
                    onSaved: (value) => _bio = (value ?? '').trim(),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepTeal),
                          )
                        : Text(
                            'GUARDAR CAMBIOS',
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
        },
        orElse: () => const Center(
          child: Text('Por favor, inicia sesión para editar tu perfil.'),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.dorado),
                title: const Text('Galería', style: TextStyle(color: AppColors.crema)),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (picked != null) {
                    setState(() => _selectedImagePath = picked.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.dorado),
                title: const Text('Cámara', style: TextStyle(color: AppColors.crema)),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                  if (picked != null) {
                    setState(() => _selectedImagePath = picked.path);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSubmitting = true);

      try {
        await ref.read(authProvider.notifier).updateProfile(
              firstName: _firstName,
              lastName: _lastName,
              phone: _phone,
              location: _location,
              bio: _bio,
              avatarFilePath: _selectedImagePath,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado con éxito.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al actualizar el perfil. Intenta de nuevo.'),
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
}

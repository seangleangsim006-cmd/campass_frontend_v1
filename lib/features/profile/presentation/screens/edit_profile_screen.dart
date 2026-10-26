import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/skeleton_placeholder.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _controllersInitialized = profile != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;
    if (profile != null && !_controllersInitialized) {
      _nameController.text = profile.fullName;
      _emailController.text = profile.email;
      _controllersInitialized = true;
    }
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const _EditProfileSkeleton(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: Color(0x140F5C63),
                    child: Icon(
                      Icons.person_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your name.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: provider.isLoading ? null : _save,
                    child: provider.isLoading
                        ? SkeletonPlaceholder(
                            child: SkeletonPlaceholder.block(
                              width: 92,
                              height: 14,
                              radius: 7,
                            ),
                          )
                        : const Text('Save changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProfileProvider>();
    final current = provider.profile!;
    final saved = await provider.updateProfile(
      current.copyWith(fullName: _nameController.text.trim()),
    );
    if (!mounted) return;
    if (saved) {
      context.pop();
    }
  }
}

class _EditProfileSkeleton extends StatelessWidget {
  const _EditProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPlaceholder(
      child: ListView(
        key: const ValueKey('edit_profile_skeleton'),
        padding: const EdgeInsets.all(20),
        children: [
          Align(
            alignment: Alignment.center,
            child: SkeletonPlaceholder.block(width: 84, height: 84, radius: 48),
          ),
          const SizedBox(height: 28),
          for (var index = 0; index < 3; index++) ...[
            SkeletonPlaceholder.block(
              width: double.infinity,
              height: 58,
              radius: 12,
            ),
            const SizedBox(height: 16),
          ],
          SkeletonPlaceholder.block(
            width: double.infinity,
            height: 50,
            radius: 12,
          ),
        ],
      ),
    );
  }
}

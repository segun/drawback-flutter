import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/display_name_text_field.dart';
import '../../domain/home_models.dart';
import '../home_controller.dart';

/// Profile management screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.controller,
    super.key,
  });

  final HomeController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late UserMode _selectedMode;
  late bool _appearInSearches;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.controller.profileDisplayName,
    );
    _selectedMode = widget.controller.profileMode;
    _appearInSearches = widget.controller.appearInSearches;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String displayName = _displayNameController.text.trim();
    
    // Update display name if changed
    if (displayName != widget.controller.profileDisplayName) {
      await widget.controller.updateProfile(displayName);
    }

    // Update mode if changed
    if (_selectedMode != widget.controller.profileMode) {
      await widget.controller.updateMode(_selectedMode);
    }

    // Update search visibility if changed
    if (_appearInSearches != widget.controller.appearInSearches) {
      await widget.controller.updateAppearInSearches(_appearInSearches);
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final bool success = await widget.controller.deleteAccount();
      if (success && mounted) {
        // Navigate to login screen
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Profile Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF9F1239),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    border: Border.all(color: const Color(0xFFFDA4AF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Display Name',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF9F1239),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      DisplayNameTextField(
                        controller: _displayNameController,
                        hintText: '@username',
                        onChanged: (String _) {},
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty || value.trim() == '@') {
                            return 'Display name is required.';
                          }
                          if (value.length < 4) {
                            return 'Display name must be at least 4 characters.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    border: Border.all(color: const Color(0xFFFDA4AF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Privacy Mode',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF9F1239),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<UserMode>(
                        title: const Text('Public', style: TextStyle(fontSize: 13)),
                        subtitle: const Text(
                          'Visible in public user lists',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: UserMode.public,
                        groupValue: _selectedMode,
                        onChanged: (UserMode? value) {
                          if (value != null) {
                            setState(() {
                              _selectedMode = value;
                            });
                          }
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<UserMode>(
                        title: const Text('Private', style: TextStyle(fontSize: 13)),
                        subtitle: const Text(
                          'Only findable by search',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: UserMode.private,
                        groupValue: _selectedMode,
                        onChanged: (UserMode? value) {
                          if (value != null) {
                            setState(() {
                              _selectedMode = value;
                            });
                          }
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    border: Border.all(color: const Color(0xFFFDA4AF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text('Appear in Searches', style: TextStyle(fontSize: 13)),
                    subtitle: const Text(
                      'Allow others to find you via search',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _appearInSearches,
                    onChanged: (bool value) {
                      setState(() {
                        _appearInSearches = value;
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: widget.controller.isBusy ? null : _updateProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFBE123C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: widget.controller.isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Update Profile'),
                ),

                const SizedBox(height: 32),

                const Divider(),

                const SizedBox(height: 16),

                Text(
                  'Danger Zone',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: _deleteAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Delete My Account'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

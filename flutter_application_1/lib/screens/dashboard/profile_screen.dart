import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../auth/landing_screen.dart';
import 'input_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final primaryColor = const Color(0xFF2885E5);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String initial = 'U';
    String name = 'User';
    String email = 'No email';
    String phone = 'Add Phone Number';

    if (user != null) {
      if (user.displayName.isNotEmpty) {
        initial = user.displayName[0].toUpperCase();
        name = user.displayName;
      }
      if (user.email.isNotEmpty) email = user.email;
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        phone = user.phoneNumber!;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AppHeader(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // Profile Avatar
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          image: user?.photoUrl != null && user!.photoUrl.isNotEmpty
                              ? DecorationImage(
                                  image: user.photoUrl.startsWith('http')
                                      ? NetworkImage(user.photoUrl) as ImageProvider
                                      : MemoryImage(base64Decode(user.photoUrl)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user?.photoUrl != null && user!.photoUrl.isNotEmpty 
                            ? null 
                            : Center(
                                child: Text(
                                  initial,
                                  style: GoogleFonts.inter(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showAvatarPicker(context, authProvider),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Name and Email
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.blueGrey[400],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Account Information Card
                  _buildSectionTitle('ACCOUNT INFORMATION'),
                  _buildCard(
                    children: [
                      _buildInfoTile(
                        icon: Icons.person_outline,
                        iconColor: Colors.blue,
                        label: 'Full Name',
                        value: name,
                        isLast: false,
                        isDark: isDark,
                        onTap: () => _showEditDialog(context, authProvider, 'Name', name, (val) => authProvider.updateProfile(name: val)),
                      ),
                      _buildInfoTile(
                        icon: Icons.email_outlined,
                        iconColor: Colors.purple,
                        label: 'Email Address',
                        value: email,
                        isLast: false,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        icon: Icons.phone_outlined,
                        iconColor: Colors.green,
                        label: 'Phone Number',
                        value: phone,
                        isLast: true,
                        isDark: isDark,
                        onTap: () => _showEditDialog(context, authProvider, 'Phone Number', phone == 'Add Phone Number' ? '' : phone, (val) => authProvider.updateProfile(phoneNumber: val)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Security Card
                  _buildSectionTitle('SECURITY'),
                  _buildCard(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.orange, size: 20),
                        ),
                        title: Text(
                          'Change Password',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                        trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
                        onTap: () => _showChangePasswordDialog(context, authProvider),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Sign Out Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      authProvider.logout().then((_) {
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LandingScreen()), (route) => false);
                        }
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InputScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider authProvider) {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final primaryColor = const Color(0xFF2885E5);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.lock_reset_outlined, color: Colors.orange),
                  const SizedBox(width: 10),
                  Text('Change Password', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => obscureNew = !obscureNew),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val != newPasswordController.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          final success = await authProvider.changePassword(
                            newPasswordController.text.trim(),
                          );
                          
                          if (!context.mounted) return;
                          if (success) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(authProvider.errorMessage ?? 'Failed to update password.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[400],
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    // using Builder to get the theme
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.blueGrey.withValues(alpha: 0.1)),
          ),
          child: Column(children: children),
        );
      }
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isLast,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey[400]),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              value,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          trailing: onTap != null ? Icon(Icons.edit, color: Colors.blueGrey[300], size: 18) : null,
          onTap: onTap,
        ),
        if (!isLast)
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : Colors.grey[100], indent: 64, endIndent: 16),
      ],
    );
  }

  void _showEditDialog(BuildContext context, AuthProvider authProvider, String title, String initialValue, Future<bool> Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter $title',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await onSave(controller.text.trim());
                if (!context.mounted) return;
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authProvider.errorMessage ?? 'Update failed')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAvatarPicker(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.face),
                title: const Text('Pick predefined Avatar'),
                onTap: () {
                  Navigator.pop(context);
                  _showPredefinedAvatars(context, authProvider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    final base64String = base64Encode(bytes);
                    await authProvider.updateProfile(photoBase64: base64String);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    final base64String = base64Encode(bytes);
                    await authProvider.updateProfile(photoBase64: base64String);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPredefinedAvatars(BuildContext context, AuthProvider authProvider) {
    final List<String> avatars = [
      'https://api.dicebear.com/7.x/bottts/png?seed=male1',
      'https://api.dicebear.com/7.x/bottts/png?seed=female1',
      'https://api.dicebear.com/7.x/bottts/png?seed=male2',
      'https://api.dicebear.com/7.x/bottts/png?seed=female2',
      'https://api.dicebear.com/7.x/bottts/png?seed=robot1',
      'https://api.dicebear.com/7.x/bottts/png?seed=robot2',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Avatar'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await authProvider.updateProfile(photoBase64: avatars[index]);
                  },
                  child: Image.network(avatars[index]),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

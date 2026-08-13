import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/features/auth/presentation/screens/login_screen.dart';
import 'package:lingoocall/features/profile/presentation/screens/user_profile_screen.dart';

class AppDrawer extends StatelessWidget {
  final AppController controller;

  const AppDrawer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = controller.currentUser;

    return Drawer(
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFF9FAFB),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white,
              backgroundImage: user.avatarUrl.isNotEmpty
                  ? NetworkImage(user.avatarUrl)
                  : null,
              child: user.avatarUrl.isEmpty
                  ? Text(
                      user.name.isNotEmpty
                          ? user.name.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            accountName: Text(
              user.name.isNotEmpty ? user.name : 'مستخدم LingooCall',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              user.username.isNotEmpty ? user.username : user.email,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildDrawerTile(
                  icon: Icons.person_outline_rounded,
                  title: 'الملف الشخصي',
                  subtitle: 'عرض وتعديل صفحتك الشخصية ومنشوراتك',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UserProfileScreen(controller: controller),
                      ),
                    );
                  },
                ),
                const Divider(height: 16),
                _buildDrawerTile(
                  icon: Icons.settings_outlined,
                  title: 'الإعدادات والتفضيلات العامة',
                  subtitle: 'اللغة، المظهر، الترجمة، والخصوصية',
                  onTap: () {
                    Navigator.pop(context);
                    _showToast(context, 'جاري فتح لوحة الإعدادات والتفضيلات...');
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.security_rounded,
                  title: 'الأمان والتشفير العصبي',
                  subtitle: 'حماية المكالمات والرسائل بنهاية لنهاية',
                  onTap: () => _showToast(context, 'التشفير مفعل وحصري 100%'),
                ),
                _buildDrawerTile(
                  icon: Icons.info_outline_rounded,
                  title: 'عن التطبيق',
                  subtitle: 'LingooCall v2.5.0',
                  onTap: () => _showToast(context, 'الإصدار الأحدث عالمياً'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: Colors.red.withValues(alpha: 0.1),
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                controller.logout();
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(controller: controller),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      horizontalTitleGap: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            )
          : null,
      onTap: onTap,
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
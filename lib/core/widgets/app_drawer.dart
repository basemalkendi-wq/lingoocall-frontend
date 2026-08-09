import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/constants/app_constants.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/features/auth/presentation/screens/login_screen.dart';
import 'package:lingoocall/features/contacts/presentation/screens/public_profile_screen.dart';
import 'package:lingoocall/features/settings/presentation/screens/phone_privacy_screen.dart';

class AppDrawer extends StatelessWidget {
  final AppController controller;

  const AppDrawer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = controller.currentUser; // جلب بيانات المستخدم المسجل ديناميكياً

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      child: Column(
        children: [
          // 1. هيدر الحساب الشخصي المحسن والربط الديناميكي
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                    : [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
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
            accountEmail: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${user.nativeLanguage} ${user.nativeFlag}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  user.username.isNotEmpty ? user.username : user.phone,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),

          // 2. قائمة الخيارات المنظمة في مجموعات مقسمة
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                // أ) قسم الحساب والملف الشخصي
                _buildSectionHeader('الحساب والشبكة'),
                _buildDrawerTile(
                  icon: Icons.person_outline_rounded,
                  title: 'الملف الشخصي',
                  subtitle: 'عرض وتعديل بياناتك والبيو',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          controller: controller,
                          userProfile: user,
                        ),
                      ),
                    );
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.star_border_rounded,
                  title: 'الرسائل المميزة بنجمة',
                  onTap: () => _showToast(context, 'الرسائل المميزة بنجمة'),
                ),

                const Divider(height: 24),

                // ب) قسم اللغات والترجمة المباشرة
                _buildSectionHeader('إعدادات الترجمة واللغة'),
                _buildDrawerTile(
                  icon: Icons.language_rounded,
                  title: 'لغة واجهة التطبيق',
                  subtitle: controller.appLocale.languageCode == 'ar'
                      ? 'العربية (Arabic)'
                      : 'English',
                  onTap: () {
                    controller.setAppLanguage(
                      controller.appLocale.languageCode == 'ar' ? 'en' : 'ar',
                    );
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.translate_rounded,
                  title: 'اللغة الأم للبروفايل',
                  subtitle: '${user.nativeLanguage} ${user.nativeFlag}',
                  onTap: () => _showToast(context, 'تغيير اللغة الأم'),
                ),
                _buildDrawerTile(
                  icon: Icons.g_translate_rounded,
                  title: 'لغة الترجمة المفضلة',
                  subtitle: '${user.targetLanguage} ${user.targetFlag}',
                  onTap: () => _showToast(context, 'تغيير لغة الترجمة'),
                ),

                const Divider(height: 24),

                // ج) قسم الخصوصية والأمان والتصميم
                _buildSectionHeader('الخصوصية والأمان'),
                _buildDrawerTile(
                  icon: Icons.phonelink_lock_rounded,
                  title: 'خصوصية رقم الهاتف',
                  subtitle: 'من يمكنه رؤية رقمك',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhonePrivacyScreen(controller: controller),
                      ),
                    );
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.security_rounded,
                  title: 'الأمان والتشفير المباشر',
                  subtitle: 'تشفير المكالمات والذكاء الاصطناعي',
                  onTap: () => _showToast(context, 'حالة التشفير: مفعلة بنسبة 100%'),
                ),
                _buildDrawerTile(
                  icon: isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: 'مظهر التطبيق',
                  subtitle: isDark ? 'الوضع الداكن' : 'الوضع الفاتح',
                  onTap: () {
                    controller.setThemeMode(
                      isDark ? ThemeMode.light : ThemeMode.dark,
                    );
                  },
                ),

                const Divider(height: 24),

                // د) حول التطبيق والدعم
                _buildSectionHeader('عن التطبيق'),
                _buildDrawerTile(
                  icon: Icons.info_outline_rounded,
                  title: 'حول LingooCall',
                  subtitle: 'الإصدار v2.5.0 • ترجمة العصبية المباشرة',
                  onTap: () => _showToast(context, 'LingooCall v2.5.0'),
                ),
              ],
            ),
          ),

          // 3. زر تسجيل الخروج السفلي الأنيق
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.accent,
        ),
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
      horizontalTitleGap: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: AppColors.primary, size: 22),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
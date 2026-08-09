import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/constants/app_constants.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/core/localization/app_localizations.dart';

class AppNavigationDrawer extends StatelessWidget {
  final AppController controller;

  const AppNavigationDrawer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    final tr = AppLocalizations.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.name.substring(0, 1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            accountName: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              '${tr.translate('nativeLanguageTitle')}: ${user.nativeLanguage} ${user.nativeFlag}',
            ),
          ),

          // --- خيار تغيير لغة واجهة التطبيق الفعلية (App Interface Language) ---
          ListTile(
            leading: const Icon(
              Icons.language_rounded,
              color: AppColors.primary,
            ),
            title: Text(tr.translate('appLanguageTitle')),
            subtitle: Text(
              controller.appLocale.languageCode == 'ar'
                  ? 'العربية (Arabic)'
                  : controller.appLocale.languageCode == 'tr'
                      ? 'Türkçe (Turkish)'
                      : 'English',
            ),
            onTap: () => _showAppLanguageSelector(context),
          ),
          const Divider(),

          // --- لغة البروفايل ولغة الترجمة المفضلة ---
          ListTile(
            leading: const Icon(
              Icons.translate_rounded,
              color: AppColors.primary,
            ),
            title: Text(tr.translate('nativeLanguageTitle')),
            subtitle: Text('${user.nativeLanguage} ${user.nativeFlag}'),
            onTap: () => _showLanguageSelector(context, isNative: true),
          ),
          ListTile(
            leading: const Icon(
              Icons.g_translate_rounded,
              color: AppColors.accent,
            ),
            title: Text(tr.translate('preferredTargetLanguageTitle')),
            subtitle: Text('${user.targetLanguage} ${user.targetFlag}'),
            onTap: () => _showLanguageSelector(context, isNative: false),
          ),
          const Divider(),

          // --- مظهر التطبيق ---
          ListTile(
            leading: const Icon(Icons.brightness_6_rounded),
            title: Text(tr.translate('themeModeTitle')),
            trailing: DropdownButton<ThemeMode>(
              value: controller.themeMode,
              onChanged: (mode) {
                if (mode != null) controller.setThemeMode(mode);
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(tr.translate('systemTheme')),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(tr.translate('lightTheme')),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(tr.translate('darkTheme')),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.security_rounded),
            title: Text(tr.translate('securityEncryptionTitle')),
            subtitle: Text(tr.translate('securityEncryptionSubtitle')),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: Text(tr.translate('aboutAppTitle')),
            subtitle: Text(tr.translate('aboutAppSubtitle')),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              tr.translate('logOutButton'),
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              controller.logout();
            },
          ),
        ],
      ),
    );
  }

  // نافذة اختيار لغة واجهة التطبيق
  void _showAppLanguageSelector(BuildContext context) {
    final tr = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.translate('selectAppLangModal'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('🇾🇪', style: TextStyle(fontSize: 24)),
                title: const Text('العربية'),
                subtitle: const Text('Arabic'),
                trailing: controller.appLocale.languageCode == 'ar'
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  controller.setAppLanguage('ar');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: const Text('English'),
                subtitle: const Text('الإنجليزية'),
                trailing: controller.appLocale.languageCode == 'en'
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  controller.setAppLanguage('en');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
                title: const Text('Türkçe'),
                subtitle: const Text('التركية'),
                trailing: controller.appLocale.languageCode == 'tr'
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  controller.setAppLanguage('tr');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // نافذة اختيار لغة البروفايل ولغة الترجمة المفضلة
  void _showLanguageSelector(BuildContext context, {required bool isNative}) {
    final tr = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isNative
                    ? tr.translate('selectNativeLangModal')
                    : tr.translate('selectTargetLangModal'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AppConstants.supportedLanguages.length,
                  itemBuilder: (context, idx) {
                    final lang = AppConstants.supportedLanguages[idx];
                    return ListTile(
                      leading: Text(
                        lang['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(lang['name']!),
                      subtitle: Text(lang['native']!),
                      onTap: () {
                        if (isNative) {
                          controller.updateNativeLanguage(
                            lang['name']!,
                            lang['flag']!,
                          );
                        } else {
                          controller.updateTargetLanguage(
                            lang['name']!,
                            lang['flag']!,
                          );
                        }
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
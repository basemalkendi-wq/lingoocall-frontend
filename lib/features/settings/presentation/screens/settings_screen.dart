import 'package:flutter/material.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/localization/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  final AppController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('settingsProfile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person_rounded, color: Colors.white),
              ),
              title: Text(controller.currentUser.name),
              subtitle: Text(
                '${controller.currentUser.nativeLanguage} ${controller.currentUser.nativeFlag} · ${controller.currentUser.targetLanguage} ${controller.currentUser.targetFlag}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.translate_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(l10n.translate('nativeLanguage')),
                  subtitle: Text(
                    '${controller.currentUser.nativeLanguage} ${controller.currentUser.nativeFlag}',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.g_translate_rounded,
                    color: AppColors.accent,
                  ),
                  title: Text(l10n.translate('preferredTargetLanguage')),
                  subtitle: Text(
                    '${controller.currentUser.targetLanguage} ${controller.currentUser.targetFlag}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_rounded),
                  title: Text(l10n.translate('themeMode')),
                  subtitle: Text(controller.themeMode.name),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded),
                  title: Text(l10n.translate('securityEncryption')),
                  subtitle: Text(l10n.translate('endToEndPrivacy')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: Text(l10n.translate('aboutApp')),
                  subtitle: Text(l10n.translate('versionInfo')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              controller.logout();
              controller.setBottomTab(0);
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.translate('logOut')),
          ),
        ],
      ),
    );
  }
}

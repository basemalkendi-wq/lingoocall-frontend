import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/features/auth/domain/models/user_profile.dart';

class PhonePrivacyScreen extends StatefulWidget {
  final AppController controller;

  const PhonePrivacyScreen({super.key, required this.controller});

  @override
  State<PhonePrivacyScreen> createState() => _PhonePrivacyScreenState();
}

class _PhonePrivacyScreenState extends State<PhonePrivacyScreen> {
  PhoneNumberPrivacy _selectedPrivacy = PhoneNumberPrivacy.nobody;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('خصوصية رقم الهاتف'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'من يمكنه رؤية رقم هاتفي؟',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                RadioListTile<PhoneNumberPrivacy>(
                  title: const Text('الجميع'),
                  subtitle: const Text('يمكن لأي شخص يزيل ملفك الشخصي رؤية رقمك'),
                  value: PhoneNumberPrivacy.everyone,
                  groupValue: _selectedPrivacy,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _selectedPrivacy = val!),
                ),
                const Divider(height: 1),
                RadioListTile<PhoneNumberPrivacy>(
                  title: const Text('المتابعون المتبادلون'),
                  subtitle: const Text('يظهر الرقم فقط للأشخاص الذين تتابعهم ويتابعونك'),
                  value: PhoneNumberPrivacy.mutual,
                  groupValue: _selectedPrivacy,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _selectedPrivacy = val!),
                ),
                const Divider(height: 1),
                RadioListTile<PhoneNumberPrivacy>(
                  title: const Text('لا أحد (مخفي دائماً)'),
                  subtitle: const Text('لن يستطيع أي شخص رؤية رقمك، والتواصل يتم عبر اليوزر فقط'),
                  value: PhoneNumberPrivacy.nobody,
                  groupValue: _selectedPrivacy,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _selectedPrivacy = val!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
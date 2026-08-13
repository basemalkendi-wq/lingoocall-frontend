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
      appBar: AppBar(title: const Text('خصوصية رقم الهاتف')),
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
                _buildPrivacyOption(
                  title: 'الجميع',
                  subtitle: 'يمكن لأي شخص يزيل ملفك الشخصي رؤية رقمك',
                  value: PhoneNumberPrivacy.everyone,
                ),
                const Divider(height: 1),
                _buildPrivacyOption(
                  title: 'المتابعون المتبادلون',
                  subtitle: 'يظهر الرقم فقط للأشخاص الذين تتابعهم ويتابعونك',
                  value: PhoneNumberPrivacy.mutual,
                ),
                const Divider(height: 1),
                _buildPrivacyOption(
                  title: 'لا أحد (مخفي دائماً)',
                  subtitle:
                      'لن يستطيع أي شخص رؤية رقمك، والتواصل يتم عبر اليوزر فقط',
                  value: PhoneNumberPrivacy.nobody,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String subtitle,
    required PhoneNumberPrivacy value,
  }) {
    final isSelected = _selectedPrivacy == value;

    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      leading: Icon(
        isSelected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: isSelected ? AppColors.primary : Colors.grey,
      ),
      onTap: () => setState(() => _selectedPrivacy = value),
    );
  }
}

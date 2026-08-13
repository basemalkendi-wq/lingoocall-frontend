import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/core/services/backend_api_service.dart';
import 'package:lingoocall/features/auth/domain/models/user_profile.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final AppController controller;
  final bool isSignUp;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.controller,
    this.isSignUp = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // تجميع الأرقام المكتوبة
  String get _enteredOtp =>
      _otpControllers.map((controller) => controller.text.trim()).join();

  // إرسال الكود للتحقق عبر البريد الإلكتروني من السيرفر
  Future<void> _verifyOtp() async {
    final otp = _enteredOtp;

    if (otp.length < 6) {
      _showSnackBar('الرجاء إدخال رمز التحقق المكون من 6 أرقام كاملاً');
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final data = await BackendApiService.instance.verifyOtp(
        email: widget.email,
        otp: otp,
        isSignUp: widget.isSignUp,
      );

      if (data['success'] == true && data['user'] is Map) {
        if (!mounted) return;
        await widget.controller.applyAuthenticatedUser(
          UserProfile.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
        );

        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'تم تأكيد البريد الإلكتروني بنجاح! مرحباً بك في LingooCall.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // التوجيه إلى الشاشة الرئيسية
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        _showSnackBar(data['message']?.toString() ?? 'رمز التحقق غير صحيح، حاول مجدداً.');
      }
    } catch (e) {
      _showSnackBar('حدث خطأ في الاتصال بالسيرفر أثناء التحقق.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد البريد الإلكتروني'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Icon(
                Icons.mark_email_read_outlined,
                size: 65,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'أدخل رمز التحقق',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'تم إرسال رمز التحقق المكون من 6 أرقام إلى بريدك الإلكتروني:\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 28),

              // حقول إدخال الـ 6 أرقام (مضبوطة لتبدأ من اليسار لليمين LTR)
              Directionality(
                textDirection: TextDirection.ltr,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 46,
                        height: 55,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                            if (_enteredOtp.length == 6) {
                              _verifyOtp();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'تأكيد واستمرار',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
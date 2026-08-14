import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/constants/app_constants.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/core/services/auth_browser_service.dart';
import 'package:lingoocall/core/services/backend_api_service.dart';
import 'package:lingoocall/features/auth/domain/models/user_profile.dart';

class LoginScreen extends StatefulWidget {
  final AppController controller;

  const LoginScreen({super.key, required this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignUp = false;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  String selectedCountryCode = '+967';
  String currentLang = 'ar';

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final Map<String, Map<String, String>> localizedTexts = {
    'ar': {
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'welcome': 'مرحباً بك مجدداً!',
      'create_acc': 'أنشئ حسابك في LingooCall',
      'login_desc': 'أدخل بياناتك لتسجيل الدخول إلى حسابك.',
      'signup_desc': 'أدخل بياناتك كاملة لإنشاء حساب جديد وتأكيده عبر البريد.',
      'full_name': 'الاسم الشخصي الكامل',
      'username': 'اسم المستخدم (اليوزر)',
      'email': 'البريد الإلكتروني',
      'phone_number': 'رقم الهاتف المحمول',
      'password': 'كلمة السر',
      'confirm_password': 'تأكيد كلمة السر',
      'forgot_password': 'نسيت كلمة السر؟',
      'send_otp': 'تأكيد وإنشاء الحساب',
      'do_login': 'تسجيل الدخول',
      'err_email_empty': 'الرجاء إدخال البريد الإلكتروني بشكل صحيح',
      'err_password_empty': 'الرجاء إدخال كلمة السر',
      'err_password_mismatch': 'كلمتا السر غير متطابقتين',
      'err_password_short': 'كلمة السر يجب أن تكون 6 أحرف أو أكثر',
      'err_phone_empty': 'الرجاء إدخال رقم الهاتف',
      'err_name_empty': 'الرجاء إدخال اسمك الشخصي',
      'err_user_empty': 'الرجاء إدخال اسم المستخدم (اليوزر)',
      'err_user_invalid':
          'اليوزر يجب أن يحتوي على حروف إنجليزية، أرقام، (_) أو (.) فقط وبدون مسافات.',
      'err_user_reserved': 'اسم المستخدم يجب أن يكون 5 أحرف أو أكثر.',
      'err_general': 'حدث خطأ غير متوقع، يرجى إعادة المحاولة.',
      'err_network': 'تعذر الاتصال بالسيرفر، يرجى التأكد من اتصالك بالإنترنت.',
    },
    'en': {
      'login': 'Log In',
      'signup': 'Sign Up',
      'welcome': 'Welcome back!',
      'create_acc': 'Create your LingooCall account',
      'login_desc': 'Enter your credentials to access your account.',
      'signup_desc': 'Fill in your details to set up your new account.',
      'full_name': 'Full Name',
      'username': 'Username (@handle)',
      'email': 'Email Address',
      'phone_number': 'Mobile Phone Number',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'send_otp': 'Verify & Create Account',
      'do_login': 'Log In',
      'err_email_empty': 'Please enter a valid email address',
      'err_password_empty': 'Please enter your password',
      'err_password_mismatch': 'Passwords do not match',
      'err_password_short': 'Password must be at least 6 characters',
      'err_phone_empty': 'Please enter phone number',
      'err_name_empty': 'Please enter your full name',
      'err_user_empty': 'Please enter username',
      'err_user_invalid':
          'Username can only contain English letters, numbers, (_) or (.) without spaces.',
      'err_user_reserved': 'Username must be at least 5 characters.',
      'err_general': 'An unexpected error occurred.',
      'err_network': 'Connection error. Please check your internet connection.',
    },
  };

  String tr(String key) {
    return localizedTexts[currentLang]?[key] ?? localizedTexts['ar']![key]!;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _continueWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final googleUrl =
          'https://accounts.google.com/o/oauth2/v2/auth?client_id=your-google-client-id.apps.googleusercontent.com&redirect_uri=${Uri.encodeComponent(AuthBrowserService.defaultRedirectUri)}&response_type=code&scope=${Uri.encodeComponent('openid email profile')}&state=lingoocall-google-auth';

      final params = await AuthBrowserService.openOAuthFlow(
        authorizationUrl: googleUrl,
        redirectUri: AuthBrowserService.defaultRedirectUri,
      );

      if (!mounted) return;

      final accessToken = params['access_token'];
      final authCode = params['code'];
      final state = params['state'];

      if ((accessToken == null || accessToken.isEmpty) &&
          (authCode == null || authCode.isEmpty)) {
        _showSnackBar(
          'Google sign-in was cancelled or the redirect did not return a token.',
        );
        return;
      }

      if (state != null && state.isNotEmpty) {
        final fakeUser = UserProfile(
          id: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Google User',
          phone: '+0000000000',
          nativeLanguage: widget.controller.currentUser.nativeLanguage,
          nativeFlag: widget.controller.currentUser.nativeFlag,
          targetLanguage: widget.controller.currentUser.targetLanguage,
          targetFlag: widget.controller.currentUser.targetFlag,
          avatarUrl: '',
          username: 'googleuser',
          email: 'google-user@lingoocall.app',
        );

        await widget.controller.applyAuthenticatedUser(fakeUser);
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
        return;
      }

      widget.controller.login();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (_) {
      if (mounted) {
        _showSnackBar('Unable to start Google Sign-In in the system browser.');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _submitAuth() async {
    if (isSignUp) {
      final fullNameText = fullNameController.text.trim();
      final usernameText = usernameController.text.trim().toLowerCase();
      final emailText = emailController.text.trim();
      final phoneText = phoneController.text.trim();
      final passwordText = passwordController.text;
      final confirmPasswordText = confirmPasswordController.text;

      if (fullNameText.isEmpty) return _showSnackBar(tr('err_name_empty'));
      if (usernameText.isEmpty) return _showSnackBar(tr('err_user_empty'));
      if (usernameText.length < 5) {
        return _showSnackBar(tr('err_user_reserved'));
      }

      // خوارزمية التحقق من صيغة اليوزر (نفس انستقرام: حروف، أرقام، _، .)
      final usernameRegex = RegExp(r'^[a-zA-Z0-9_.]+$');
      if (!usernameRegex.hasMatch(usernameText)) {
        return _showSnackBar(tr('err_user_invalid'));
      }

      if (emailText.isEmpty || !emailText.contains('@')) {
        return _showSnackBar(tr('err_email_empty'));
      }
      if (phoneText.isEmpty) {
        return _showSnackBar(tr('err_phone_empty'));
      }
      if (passwordText.length < 6) {
        return _showSnackBar(tr('err_password_short'));
      }
      if (passwordText != confirmPasswordText) {
        return _showSnackBar(tr('err_password_mismatch'));
      }

      final fullPhone = '$selectedCountryCode$phoneText';

      setState(() => isLoading = true);

      try {
        final data = await BackendApiService.instance.register(
          email: emailText,
          username: usernameText,
          fullName: fullNameText,
          phone: fullPhone,
          password: passwordText,
          nativeLanguage: widget.controller.currentUser.nativeLanguage,
          avatarUrl: widget.controller.currentUser.avatarUrl,
        );

        if (data['success'] == true && data['user'] is Map) {
          if (!mounted) return;
          await widget.controller.applyAuthenticatedUser(
            UserProfile.fromJson(
              Map<String, dynamic>.from(data['user'] as Map),
            ),
          );
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
          return;
        }

        _showSnackBar(data['message']?.toString() ?? tr('err_general'));
      } catch (_) {
        _showSnackBar(tr('err_network'));
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      final identifier = emailController.text.trim();
      final password = passwordController.text;

      if (identifier.isEmpty) return _showSnackBar(tr('err_email_empty'));
      if (password.isEmpty) return _showSnackBar(tr('err_password_empty'));

      setState(() => isLoading = true);
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      try {
        final data = await BackendApiService.instance.login(
          identifier: identifier,
          password: password,
        );

        if (data['success'] == true && data['user'] is Map) {
          if (!mounted) return;
          await widget.controller.applyAuthenticatedUser(
            UserProfile.fromJson(
              Map<String, dynamic>.from(data['user'] as Map),
            ),
          );
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                tr('welcome'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
          navigator.pushNamedAndRemoveUntil('/home', (route) => false);
        } else {
          _showSnackBar(data['message']?.toString() ?? tr('err_general'));
        }
      } catch (_) {
        _showSnackBar(tr('err_network'));
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(
    String message, {
    bool isSuccess = false,
    int durationSeconds = 4,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: durationSeconds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = currentLang == 'ar';

    return Scaffold(
      body: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // شريط اللغة
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentLang,
                        items: const [
                          DropdownMenuItem(
                            value: 'ar',
                            child: Text('العربية 🇸🇦'),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('English 🇺🇸'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => currentLang = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // الشعار
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.g_translate_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // التبويب
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isSignUp = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isSignUp
                                  ? (isDark ? AppColors.primary : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tr('login'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !isSignUp
                                    ? (isDark
                                          ? Colors.white
                                          : AppColors.primary)
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isSignUp = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSignUp
                                  ? (isDark ? AppColors.primary : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tr('signup'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSignUp
                                    ? (isDark
                                          ? Colors.white
                                          : AppColors.primary)
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  isSignUp ? tr('create_acc') : tr('welcome'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSignUp ? tr('signup_desc') : tr('login_desc'),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // الحقول
                if (isSignUp) ...[
                  TextField(
                    controller: fullNameController,
                    decoration: InputDecoration(
                      hintText: tr('full_name'),
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      hintText: tr('username'),
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      helperText: 'مسموح: حروف إنجليزية، أرقام، _ ، .',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: isSignUp
                        ? tr('email')
                        : 'اسم المستخدم أو البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (isSignUp) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          color: isDark ? AppColors.darkSurface : Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCountryCode,
                            items: AppConstants.countryCodes.map((c) {
                              return DropdownMenuItem<String>(
                                value: c['code'],
                                child: Text('${c['flag']} ${c['code']}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => selectedCountryCode = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: tr('phone_number'),
                            prefixIcon: const Icon(Icons.phone_android_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: tr('password'),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () => isPasswordVisible = !isPasswordVisible,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (isSignUp) ...[
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      hintText: tr('confirm_password'),
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => isConfirmPasswordVisible =
                              !isConfirmPasswordVisible,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: isLoading ? null : _submitAuth,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isSignUp ? tr('send_otp') : tr('do_login'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _continueWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingoocall/core/constants/app_constants.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/core/localization/app_localizations.dart';
import 'package:lingoocall/core/services/notification_service.dart';
import 'package:lingoocall/core/theme/app_theme.dart';
import 'package:lingoocall/firebase_options.dart';
import 'package:lingoocall/features/auth/presentation/screens/login_screen.dart';
import 'package:lingoocall/features/auth/presentation/screens/oauth_callback_screen.dart';
import 'package:lingoocall/features/call/presentation/screens/video_call_screen.dart';
import 'package:lingoocall/main_shell.dart';

// دالة معالجة الإشعارات الواردة أثناء إغلاق التطبيق أو وجوده في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تهيئة Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. تسجيل معالج الإشعارات في الخلفية
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // 3. تهيئة خدمة الإشعارات وطلب الصلاحيات (غير متاحة على Flutter Web)
  if (!kIsWeb) {
    await NotificationService().initialize();
  }

  // 4. قفل اتجاه الشاشة على الوضع العمودي
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // 5. التحقق من حالة تسجيل الدخول المحفوظة للجلسة
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(LingooCallApp(initialIsLoggedIn: isLoggedIn));
}

class LingooCallApp extends StatefulWidget {
  final bool initialIsLoggedIn;

  const LingooCallApp({super.key, required this.initialIsLoggedIn});

  @override
  State<LingooCallApp> createState() => _LingooCallAppState();
}

class _LingooCallAppState extends State<LingooCallApp> {
  final AppController _appController = AppController();

  @override
  void initState() {
    super.initState();
    _appController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appController,
      builder: (context, _) {
        return MaterialApp(
          title: AppConstants.appName,
          onGenerateTitle: (context) =>
              AppLocalizations.of(context).translate('appName'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _appController.themeMode,
          locale: _appController.appLocale,
          supportedLocales: const [Locale('ar'), Locale('en'), Locale('tr')],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routes: {
            '/login': (context) => LoginScreen(controller: _appController),
            '/home': (context) => MainShell(controller: _appController),
            '/auth-callback': (context) =>
                OAuthCallbackScreen(controller: _appController),
          },
          home: _appController.isInCall
              ? VideoCallScreen(controller: _appController)
              : widget.initialIsLoggedIn
              ? MainShell(controller: _appController)
              : LoginScreen(controller: _appController),
        );
      },
    );
  }
}

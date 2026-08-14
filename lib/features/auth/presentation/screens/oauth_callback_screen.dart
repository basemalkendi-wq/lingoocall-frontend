import 'package:flutter/material.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/core/services/auth_browser_service.dart';

class OAuthCallbackScreen extends StatefulWidget {
  final AppController controller;
  const OAuthCallbackScreen({super.key, required this.controller});

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  String _status = 'Processing sign-in callback...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCallback();
    });
  }

  Future<void> _handleCallback() async {
    final redirectUrl = AuthBrowserService.lastRedirectUrl.isNotEmpty
        ? AuthBrowserService.lastRedirectUrl
        : Uri.base.toString();
    final uri = Uri.tryParse(redirectUrl);
    final params = uri == null
        ? const <String, String>{}
        : AuthBrowserService.parseCallbackFromUri(uri);

    if (!mounted) return;

    if (params.isEmpty) {
      setState(() {
        _status = 'No callback data was returned. Please try again.';
      });
      return;
    }

    final isValid =
        params['access_token'] != null ||
        params['code'] != null ||
        params['state'] != null;

    if (isValid) {
      widget.controller.login();
      if (!mounted) return;
      setState(() {
        _status = 'Authentication complete. Redirecting...';
      });
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

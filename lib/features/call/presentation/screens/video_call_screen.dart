import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:simple_pip_mode/pip_widget.dart';
import 'package:simple_pip_mode/simple_pip.dart';

import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/core/services/call_foreground_service.dart';
import 'package:lingoocall/core/services/webrtc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final AppController controller;

  const VideoCallScreen({super.key, required this.controller});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final WebRTCService _webRTCService = WebRTCService();
  final SimplePip _simplePip = SimplePip();
  bool _isCameraInitialized = false;
  bool _isEndingCall = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    if (!kIsWeb) {
      CallForegroundService.initService();
    }
  }

  Future<void> _initRenderers() async {
    await _webRTCService.initializeRenderers(
      localRenderer: _localRenderer,
      remoteRenderer: _remoteRenderer,
    );
    await _webRTCService.openUserMedia(_localRenderer);

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }

    final target = widget.controller.activeCallContact;
    if (target != null) {
      _webRTCService.makeCall(target.id, _remoteRenderer);

      if (!kIsWeb) {
        CallForegroundService.startCallNotification(
          contactName: target.name,
          durationText: '00:00',
        );
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      CallForegroundService.stopCallNotification();
    }
    _webRTCService.disposeRenderers(_localRenderer, _remoteRenderer);
    super.dispose();
  }

  /// 🔴 الدالة الوحيدة والمسؤولة حصراً عن إنهاء المكالمة بالكامل
  Future<void> _handleEndCall() async {
    if (_isEndingCall) return;
    _isEndingCall = true;

    if (!kIsWeb) {
      CallForegroundService.stopCallNotification();
    }
    widget.controller.endCall();

    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  /// 🟢 دالة الخروج/التصغير دون قطع الاتصال
  Future<void> _handleMinimizeOrExit() async {
    if (!kIsWeb) {
      await _simplePip.enterPipMode();
    } else if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final durationStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final contact = widget.controller.activeCallContact;
    if (contact != null && !kIsWeb) {
      CallForegroundService.startCallNotification(
        contactName: contact.name,
        durationText: durationStr,
      );
    }

    return durationStr;
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.controller.activeCallContact;

    return PipWidget(
      // --- الواجهة المصغرة للنافذة العائمة (خفيفة ونظيفة بدون أزرار متداخلة) ---
      pipChild: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _remoteRenderer.srcObject != null &&
                          !widget.controller.isVideoOff
                      ? RTCVideoView(
                          _remoteRenderer,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : (_isCameraInitialized && !widget.controller.isVideoOff
                          ? RTCVideoView(
                              _localRenderer,
                              mirror: true,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                            )
                          : Container(
                              color: const Color(0xFF111827),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      child: Text(
                                        contact != null && contact.name.isNotEmpty
                                            ? contact.name
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : 'A',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      contact?.name ?? 'LingooCall',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                ),
              ],
            ),
          ),
        ),
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            // الرجوع بالإيماءات أو الزر الهاردوير يقوم بالتصغير فقط دون إنهاء الاتصال
            _handleMinimizeOrExit();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // --- عرض فيديو المستقبل الحقيقي أو الخلفية الكبيرة ---
              Positioned.fill(
                child: _remoteRenderer.srcObject != null &&
                        !widget.controller.isVideoOff
                    ? RTCVideoView(
                        _remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : (_isCameraInitialized && !widget.controller.isVideoOff
                        ? RTCVideoView(
                            _localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF1E1E2C),
                                  Color(0xFF2A2A40),
                                  Color(0xFF111827),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 54,
                                    backgroundColor: AppColors.accent
                                        .withValues(alpha: 0.3),
                                    child: Text(
                                      contact != null &&
                                              contact.name.isNotEmpty
                                          ? contact.name
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : 'A',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    contact?.name ?? 'Ayla Yılmaz',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.graphic_eq_rounded,
                                        color: AppColors.accent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Speaking ${contact?.nativeLanguage ?? "Turkish"} ${contact?.flag ?? "🇹🇷"}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),
              ),

              // --- زر التصغير العلوي وشريط زمن الاتصال (لا ينهي المكالمة) ---
              Positioned(
                top: 50,
                left: 16,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _handleMinimizeOrExit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ListenableBuilder(
                            listenable: widget.controller,
                            builder: (context, _) => Text(
                              _formatDuration(widget.controller.callSeconds),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'AI Streaming ${contact?.flag ?? "🇹🇷"} ⇄ ${widget.controller.currentUser.nativeFlag}',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- نافذة معاينة الفيديو الشخصي ---
              if (!widget.controller.isVideoOff)
                Positioned(
                  top: 50,
                  right: 16,
                  child: Container(
                    width: 110,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x80000000), blurRadius: 10),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          _isCameraInitialized
                              ? RTCVideoView(
                                  _localRenderer,
                                  mirror: true,
                                  objectFit: RTCVideoViewObjectFit
                                      .RTCVideoViewObjectFitCover,
                                )
                              : Container(
                                  color: const Color(0xFF334155),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              color: const Color(0x80000000),
                              child: const Text(
                                'You (Self)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // --- مربع الترجمة المباشرة الحية (Glassmorphism AI Subtitles) ---
              ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final currentSub = widget.controller.currentSubtitle;
                  if (!widget.controller.showSubtitles || currentSub == null) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    left: 16,
                    right: 16,
                    bottom: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.record_voice_over_rounded,
                                    color: AppColors.accent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${currentSub.speakerName} (${currentSub.originalLang})',
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'LIVE AI',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentSub.originalSentence,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6.0),
                                child: Divider(
                                  color: Colors.white24,
                                  height: 1,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.subtitles_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      currentSub.translatedSentence,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // --- شريط أزرار التحكم السفلي للمكالمة ---
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: widget.controller.isMicMuted
                            ? Colors.red
                            : Colors.white24,
                        child: IconButton(
                          icon: Icon(
                            widget.controller.isMicMuted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => widget.controller.toggleMic(),
                        ),
                      ),
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: widget.controller.isVideoOff
                            ? Colors.red
                            : Colors.white24,
                        child: IconButton(
                          icon: Icon(
                            widget.controller.isVideoOff
                                ? Icons.videocam_off_rounded
                                : Icons.videocam_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => widget.controller.toggleVideo(),
                        ),
                      ),
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: widget.controller.showSubtitles
                            ? AppColors.accent
                            : Colors.white24,
                        child: IconButton(
                          icon: const Icon(
                            Icons.subtitles_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => widget.controller.toggleSubtitles(),
                        ),
                      ),
                      // زر تحويل الشاشة إلى النافذة الطافية المصغرة يدوياً (لا ينهي المكالمة)
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white24,
                        child: IconButton(
                          icon: const Icon(
                            Icons.picture_in_picture_alt_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _handleMinimizeOrExit,
                        ),
                      ),
                      // 🔴 زر إنهاء المكالمة الوحيد والمسؤول حصراً عن قطع الاتصال
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.error,
                        child: IconButton(
                          icon: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _handleEndCall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
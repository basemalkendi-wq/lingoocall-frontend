import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lingoocall/core/services/socket_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final SocketService _socketService = SocketService();

  // إعدادات خوادم STUN و TURN لإتاحة الاتصال عبر مختلف الشبكات والجدران النارية
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      // خوادم STUN المجانية من Google
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},

      // خوادم TURN لتمرير الصوت والفيديو
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ]
  };

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  Future<void> initializeRenderers({
    required RTCVideoRenderer localRenderer,
    required RTCVideoRenderer remoteRenderer,
  }) async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  // فتح الكاميرا والميكروفون المحليين
  Future<MediaStream> openUserMedia(RTCVideoRenderer localVideo) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': {
        'facingMode': 'user',
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localVideo.srcObject = _localStream;
    return _localStream!;
  }

  // إنشاء الاتصال وبدء الاتصال بطرف آخر (Offer)
  Future<void> makeCall(String targetUserId, RTCVideoRenderer remoteRenderer) async {
    _peerConnection = await createPeerConnection(_configuration);

    _registerPeerEvents(targetUserId, remoteRenderer);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // إرسال العرض عبر سيرفر السوكت
    _socketService.sendCallOffer(
      to: targetUserId,
      offer: offer.toMap(),
    );
  }

  void _registerPeerEvents(String targetUserId, RTCVideoRenderer remoteRenderer) {
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      _socketService.sendIceCandidate(
        to: targetUserId,
        candidate: candidate.toMap(),
      );
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
      }
    };
  }

  // الإجابة على مكالمة قادمة (Answer Call)
  Future<void> answerCall(String fromUserId, dynamic offer, RTCVideoRenderer remoteRenderer) async {
    _peerConnection = await createPeerConnection(_configuration);

    _registerPeerEvents(fromUserId, remoteRenderer);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _socketService.sendCallAnswer(
      to: fromUserId,
      answer: answer.toMap(),
    );
  }

  // إضافة الـ ICE Candidate المستلم من الطرف الآخر
  Future<void> addIceCandidate(dynamic candidateData) async {
    if (_peerConnection != null) {
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    }
  }

  // التحكم بكتم الصوت وتوقف الكاميرا على مستوى دفق WebRTC
  void toggleLocalAudio(bool isMuted) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
  }

  void toggleLocalVideo(bool isVideoOff) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !isVideoOff;
    });
  }

  // تحرير وإغلاق كافة المسارات الكاميرا والميكروفون بمرونة
  void disposeRenderers(RTCVideoRenderer local, RTCVideoRenderer remote) {
    local.srcObject = null;
    remote.srcObject = null;
    local.dispose();
    remote.dispose();

    _localStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.getTracks().forEach((track) => track.stop());

    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.close();
    _peerConnection = null;
  }
}
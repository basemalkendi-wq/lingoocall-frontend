import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lingoocall/core/services/socket_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final SocketService _socketService = SocketService();

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
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
    ],
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

  Future<MediaStream> openUserMedia(RTCVideoRenderer localVideo) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': {'facingMode': 'user'},
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localVideo.srcObject = _localStream;
    return _localStream!;
  }

  Future<void> makeCall(
    String targetUserId,
    RTCVideoRenderer remoteRenderer,
  ) async {
    _peerConnection ??= await createPeerConnection(_configuration);
    _registerPeerEvents(targetUserId, remoteRenderer);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _socketService.sendCallOffer(to: targetUserId, offer: offer.toMap());
  }

  Future<void> answerCall(
    String fromUserId,
    dynamic offer,
    RTCVideoRenderer remoteRenderer,
  ) async {
    _peerConnection ??= await createPeerConnection(_configuration);
    _registerPeerEvents(fromUserId, remoteRenderer);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    if (offer is Map && offer['sdp'] != null && offer['type'] != null) {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
    }

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    _socketService.sendCallAnswer(to: fromUserId, answer: answer.toMap());
  }

  Future<void> setRemoteAnswer(dynamic answerData) async {
    if (_peerConnection == null ||
        answerData is! Map ||
        answerData['sdp'] == null) {
      return;
    }

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(answerData['sdp'], answerData['type'] ?? 'answer'),
    );
  }

  void _registerPeerEvents(String peerUserId, RTCVideoRenderer remoteRenderer) {
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      _socketService.sendIceCandidate(
        to: peerUserId,
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

  Future<void> addIceCandidate(dynamic candidateData) async {
    if (_peerConnection == null || candidateData is! Map) {
      return;
    }

    final candidate = candidateData['candidate'];
    final sdpMid = candidateData['sdpMid'];
    final sdpMLineIndex = candidateData['sdpMLineIndex'];

    if (candidate == null || candidate.toString().isEmpty) {
      return;
    }

    await _peerConnection!.addCandidate(
      RTCIceCandidate(
        candidate.toString(),
        sdpMid?.toString(),
        sdpMLineIndex is int ? sdpMLineIndex : 0,
      ),
    );
  }

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

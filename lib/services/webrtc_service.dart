// lib/services/webrtc_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class WebRtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  final List<RTCIceCandidate> _pendingIceCandidates = [];

  bool _isMuted = true;
  bool get isMuted => _isMuted;

  bool _isVideoOff = false;
  bool get isVideoOff => _isVideoOff;

  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      {'urls': 'stun:stun.cloudflare.com:3478'},
    ],
    'iceTransportPolicy': 'all',
  };

  static const Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<bool> startLocalStream({required bool isVideo}) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      debugPrint("Camera/Microphone permissions denied.");
      return false;
    }

    try {
      // Fundamentals: Simplified standard constraints for maximum mobile hardware compatibility
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': isVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 640},
                'height': {'ideal': 480},
                'frameRate': {'ideal': 30},
              }
            : false,
      };

     _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;

      // ==================== KEY CHANGE HERE ====================
      // 2. Mute audio tracks immediately upon capturing stream
      if (_isMuted) {
        for (var track in _localStream!.getAudioTracks()) {
          track.enabled = false;
        }
        debugPrint("🎤 [WebRTC] Local microphone muted by default.");
      }
      // =========================================================

      return true;
    } catch (e) {
      debugPrint("WebRTC getUserMedia error: $e");
      return false;
    }
  }

  Future<void> createPeerConnectionInstance({
    required Function(RTCIceCandidate candidate) onIceCandidate,
    required Function(MediaStream stream) onAddStream,
    Function(MediaStream stream)? onRemoteStream,
  }) async {
    try {
      _peerConnection = await createPeerConnection(_iceServers, _config);

      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate != null) {
          onIceCandidate(candidate);
        }
      };

      _peerConnection!.onTrack = (event) async {
        debugPrint("🎬 [WebRTC] onTrack fired: ${event.track.kind}");
        MediaStream stream;
        if (event.streams.isNotEmpty) {
          stream = event.streams[0];
        } else {
          _remoteStream ??= await createLocalMediaStream('remote_stream_id');
          _remoteStream!.addTrack(event.track);
          stream = _remoteStream!;
        }
        _remoteStream = stream;
        remoteRenderer.srcObject = stream;

        onRemoteStream?.call(stream);
        onAddStream(stream);
      };

      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          await _peerConnection!.addTrack(track, _localStream!);
        }
      }
    } catch (e) {
      debugPrint("❌ createPeerConnection error: $e");
    }
  }

  Future<RTCSessionDescription?> createOffer() async {
    if (_peerConnection == null) return null;
    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
        'optional': [],
      });
      await _peerConnection!.setLocalDescription(offer);
      return offer;
    } catch (e) {
      debugPrint("❌ createOffer error: $e");
      return null;
    }
  }

  Future<RTCSessionDescription?> createAnswer(
      RTCSessionDescription remoteOffer) async {
    if (_peerConnection == null) return null;
    try {
      await _peerConnection!.setRemoteDescription(remoteOffer);
      await _drainPendingIceCandidates();

      RTCSessionDescription answer = await _peerConnection!.createAnswer({
        'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
        'optional': [],
      });
      await _peerConnection!.setLocalDescription(answer);
      return answer;
    } catch (e) {
      debugPrint("❌ createAnswer error: $e");
      return null;
    }
  }

  Future<void> setRemoteAnswer(RTCSessionDescription remoteAnswer) async {
    if (_peerConnection != null) {
      try {
        await _peerConnection!.setRemoteDescription(remoteAnswer);
        await _drainPendingIceCandidates();
      } catch (e) {
        debugPrint("❌ setRemoteAnswer error: $e");
      }
    }
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection != null) {
      final remoteDesc = await _peerConnection!.getRemoteDescription();
      if (remoteDesc == null) {
        _pendingIceCandidates.add(candidate);
        return;
      }
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint("❌ addIceCandidate error: $e");
      }
    }
  }

  Future<void> _drainPendingIceCandidates() async {
    if (_peerConnection != null && _pendingIceCandidates.isNotEmpty) {
      for (var candidate in List<RTCIceCandidate>.from(_pendingIceCandidates)) {
        try {
          await _peerConnection!.addCandidate(candidate);
        } catch (e) {
          debugPrint("❌ Error flushing queued candidate: $e");
        }
      }
      _pendingIceCandidates.clear();
    }
  }

  void toggleMute() {
    if (_localStream != null) {
      _isMuted = !_isMuted;
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !_isMuted;
      }
    }
  }

  void toggleVideo() {
    if (_localStream != null) {
      _isVideoOff = !_isVideoOff;
      for (var track in _localStream!.getVideoTracks()) {
        track.enabled = !_isVideoOff;
      }
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      final videoTrack = _localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
    }
  }

  Future<void> dispose() async {
    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
      await localRenderer.dispose();
      await remoteRenderer.dispose();

      _localStream?.getTracks().forEach((track) async => await track.stop());
      await _localStream?.dispose();
      await _remoteStream?.dispose();

      await _peerConnection?.close();
      _peerConnection = null;
    } catch (e) {
      debugPrint("WebRTC dispose error: $e");
    }
  }
}

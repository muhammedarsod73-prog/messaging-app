import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class WebRtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  final List<RTCIceCandidate> _pendingIceCandidates = [];

  bool _isMuted = true; // Muted by default upon joining call
  bool get isMuted => _isMuted;

  bool _isVideoOff = false;
  bool get isVideoOff => _isVideoOff;

  // Fallback STUN + TURN Relay Configuration for 4G/5G Mobile Data (CGNAT) Traversal
  static const Map<String, dynamic> _fallbackIceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun.cloudflare.com:3478'},
      {'urls': 'stun:global.stun.twilio.com:3478'},
      {'urls': 'stun:stun.services.mozilla.com:3478'},
      {
        'urls': [
          'turn:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:443',
          'turn:openrelay.metered.ca:443?transport=tcp',
          'turns:openrelay.metered.ca:443',
          'turns:openrelay.metered.ca:443?transport=tcp',
        ],
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'iceTransportPolicy': 'all',
  };

  // Dynamically fetch Metered.ca or Cloudflare Calls TURN credentials, or fallback to static servers
  Future<Map<String, dynamic>> _fetchIceServers() async {
    String meteredDomain = '';
    String meteredApiKey = '';
    String turnKeyId = '';
    String turnKeyApiToken = '';

    try {
      if (dotenv.isInitialized) {
        meteredDomain = dotenv.env['METERED_DOMAIN'] ?? '';
        meteredApiKey = dotenv.env['METERED_API_KEY'] ?? '';
        turnKeyId = dotenv.env['CLOUDFLARE_TURN_KEY_ID'] ?? '';
        turnKeyApiToken = dotenv.env['CLOUDFLARE_TURN_KEY_API_TOKEN'] ?? '';
      }
    } catch (_) {}

    if (meteredDomain.isEmpty) {
      meteredDomain = const String.fromEnvironment('METERED_DOMAIN');
    }
    if (meteredApiKey.isEmpty) {
      meteredApiKey = const String.fromEnvironment('METERED_API_KEY');
    }
    if (turnKeyId.isEmpty) {
      turnKeyId = const String.fromEnvironment('CLOUDFLARE_TURN_KEY_ID');
    }
    if (turnKeyApiToken.isEmpty) {
      turnKeyApiToken = const String.fromEnvironment('CLOUDFLARE_TURN_KEY_API_TOKEN');
    }

    // 1. Fetch from Metered.ca API if credentials provided
    if (meteredDomain.isNotEmpty && meteredApiKey.isNotEmpty) {
      try {
        debugPrint("⚡ [WebRTC Debug] Requesting dynamic Metered.ca TURN credentials...");
        final response = await http.get(
          Uri.parse('https://$meteredDomain/api/v1/turn/credentials?apiKey=$meteredApiKey'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final meteredServers = List<Map<String, dynamic>>.from(data);

          debugPrint("✅ [WebRTC Debug] Received ${meteredServers.length} Metered.ca TURN servers!");
          return {
            'iceServers': [
              ...meteredServers,
              {'urls': 'stun:stun.l.google.com:19302'},
              {'urls': 'stun:stun.cloudflare.com:3478'},
            ],
            'iceTransportPolicy': 'all',
          };
        }
      } catch (e) {
        debugPrint("⚠️ [WebRTC Debug] Failed to fetch Metered.ca TURN credentials: $e");
      }
    }

    // 2. Fetch from Cloudflare Calls API if credentials provided
    if (turnKeyId.isNotEmpty && turnKeyApiToken.isNotEmpty) {
      try {
        debugPrint("⚡ [WebRTC Debug] Requesting dynamic Cloudflare Calls TURN credentials...");
        final response = await http.post(
          Uri.parse('https://rtc.live.cloudflare.com/v1/turn/keys/$turnKeyId/credentials/generate-ice-servers'),
          headers: {
            'Authorization': 'Bearer $turnKeyApiToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'ttl': 86400}),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final cloudflareServers = List<Map<String, dynamic>>.from(data['iceServers']);

          debugPrint("✅ [WebRTC Debug] Received ${cloudflareServers.length} Cloudflare Calls TURN servers!");
          return {
            'iceServers': [
              ...cloudflareServers,
              {'urls': 'stun:stun.l.google.com:19302'},
              {'urls': 'stun:stun.cloudflare.com:3478'},
            ],
            'iceTransportPolicy': 'all',
          };
        }
      } catch (e) {
        debugPrint("⚠️ [WebRTC Debug] Failed to fetch Cloudflare TURN credentials: $e");
      }
    }

    return _fallbackIceServers;
  }

  static const Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true}, // End-to-End DTLS-SRTP Media Encryption
    ],
    'iceTransportPolicy': 'all',
  };

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<bool> startLocalStream({required bool isVideo}) async {
    // 1. Request Camera & Mic Permissions
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
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': isVideo
            ? {
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;

      // Apply default muted state to audio tracks
      if (_isMuted) {
        for (var track in _localStream!.getAudioTracks()) {
          track.enabled = false;
        }
      }

      return true;
    } catch (e) {
      debugPrint("WebRTC getUserMedia error: $e");
      return false;
    }
  }

  Future<void> createPeerConnectionInstance({
    required Function(RTCIceCandidate candidate) onIceCandidate,
    required Function(MediaStream stream) onAddStream,
  }) async {
    try {
      debugPrint("🎥 [WebRTC Debug] Creating RTCPeerConnection instance...");
      final iceConfig = await _fetchIceServers();
      _peerConnection = await createPeerConnection(iceConfig, _config);

      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate != null) {
          debugPrint("📡 [WebRTC Debug] Local ICE Candidate generated: ${candidate.sdpMid}");
          onIceCandidate(candidate);
        }
      };

      _peerConnection!.onTrack = (event) async {
        debugPrint("🎬 [WebRTC Debug] onTrack event fired! Track kind: ${event.track.kind}");
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
        debugPrint("✅ [WebRTC Debug] Bound remote track (${event.track.kind}) to remoteRenderer!");
        onAddStream(stream);
      };

      _peerConnection!.onAddStream = (stream) {
        debugPrint("🎬 [WebRTC Debug] onAddStream event fired!");
        _remoteStream = stream;
        remoteRenderer.srcObject = stream;
        debugPrint("✅ [WebRTC Debug] Set remoteRenderer.srcObject from onAddStream!");
        onAddStream(stream);
      };

      if (_localStream != null) {
        debugPrint("📹 [WebRTC Debug] Adding local media tracks to PeerConnection...");
        for (var track in _localStream!.getTracks()) {
          await _peerConnection!.addTrack(track, _localStream!);
        }
        debugPrint("✅ [WebRTC Debug] Added all local tracks to PeerConnection!");
      }
    } catch (e) {
      debugPrint("❌ [WebRTC Debug] createPeerConnection error: $e");
    }
  }

  Future<RTCSessionDescription?> createOffer() async {
    if (_peerConnection == null) return null;
    try {
      debugPrint("📝 [WebRTC Debug] Creating SDP Offer...");
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
        'optional': [],
      });
      await _peerConnection!.setLocalDescription(offer);
      debugPrint("✅ [WebRTC Debug] Set LocalDescription (Offer) successfully!");
      return offer;
    } catch (e) {
      debugPrint("❌ [WebRTC Debug] createOffer error: $e");
      return null;
    }
  }

  Future<RTCSessionDescription?> createAnswer(RTCSessionDescription remoteOffer) async {
    if (_peerConnection == null) return null;
    try {
      final state = await _peerConnection!.getSignalingState();
      debugPrint("📥 [WebRTC Debug] signalingState before createAnswer: $state");

      // Only process remote offer if peerConnection is stable or expecting offer
      if (state == RTCSignalingState.RTCSignalingStateStable ||
          state == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        await _peerConnection!.setRemoteDescription(remoteOffer);
        await _drainPendingIceCandidates();

        RTCSessionDescription answer = await _peerConnection!.createAnswer({
          'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
          'optional': [],
        });
        await _peerConnection!.setLocalDescription(answer);
        debugPrint("✅ [WebRTC Debug] Set LocalDescription (Answer) successfully!");
        return answer;
      } else {
        debugPrint("⚠️ [WebRTC Debug] Skipping createAnswer because signalingState is $state");
        return null;
      }
    } catch (e) {
      debugPrint("❌ [WebRTC Debug] createAnswer error: $e");
      return null;
    }
  }

  Future<void> setRemoteAnswer(RTCSessionDescription remoteAnswer) async {
    if (_peerConnection != null) {
      try {
        final state = await _peerConnection!.getSignalingState();
        debugPrint("📥 [WebRTC Debug] signalingState before setRemoteAnswer: $state");

        if (state == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
          await _peerConnection!.setRemoteDescription(remoteAnswer);
          await _drainPendingIceCandidates();
          debugPrint("✅ [WebRTC Debug] Set RemoteDescription (Answer) successfully!");
        } else {
          debugPrint("⚠️ [WebRTC Debug] Skipping setRemoteAnswer because signalingState is $state");
        }
      } catch (e) {
        debugPrint("❌ [WebRTC Debug] setRemoteAnswer error: $e");
      }
    }
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection != null) {
      final remoteDesc = await _peerConnection!.getRemoteDescription();
      if (remoteDesc == null) {
        debugPrint("⏳ [WebRTC Debug] Remote description is null. Queuing ICE Candidate: ${candidate.sdpMid}");
        _pendingIceCandidates.add(candidate);
        return;
      }
      try {
        debugPrint("➕ [WebRTC Debug] Adding Remote ICE Candidate: ${candidate.sdpMid}");
        await _peerConnection!.addCandidate(candidate);
        debugPrint("✅ [WebRTC Debug] Added Remote ICE Candidate successfully!");
      } catch (e) {
        debugPrint("❌ [WebRTC Debug] addIceCandidate error: $e");
      }
    }
  }

  Future<void> _drainPendingIceCandidates() async {
    if (_peerConnection != null && _pendingIceCandidates.isNotEmpty) {
      debugPrint("🚀 [WebRTC Debug] Flushing ${_pendingIceCandidates.length} queued ICE Candidates...");
      for (var candidate in List<RTCIceCandidate>.from(_pendingIceCandidates)) {
        try {
          await _peerConnection!.addCandidate(candidate);
          debugPrint("✅ [WebRTC Debug] Flushed queued ICE Candidate: ${candidate.sdpMid}");
        } catch (e) {
          debugPrint("❌ [WebRTC Debug] Error flushing queued candidate: $e");
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
      for (var track in _localStream!.getVideoTracks()) {
        track.enabled = _isVideoOff;
      }
      _isVideoOff = !_isVideoOff;
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

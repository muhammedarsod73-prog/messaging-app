import 'package:duo_chat/providers/auth_provider.dart';
import 'package:duo_chat/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../services/webrtc_service.dart';
import '../../theme/app_theme.dart';

class VideoCallScreen extends StatefulWidget {
  final String partnerName;
  final String channelId;
  final bool isVideoCall;
  final bool isCaller;
  final VoidCallback onEndCall;

  const VideoCallScreen({
    Key? key,
    required this.partnerName,
    this.channelId = 'duochat_call_room',
    required this.isVideoCall,
    required this.isCaller,
    required this.onEndCall,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final WebRtcService _rtcService = WebRtcService();
  bool _isConnected = false;
  bool _hasRemoteStream = false;

  @override
  void initState() {
    super.initState();
    _initWebRtc();
  }

  Future<void> _initWebRtc() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    await _rtcService.initRenderers();
    final hasStream = await _rtcService.startLocalStream(isVideo: widget.isVideoCall);

    if (hasStream) {
      // 1. Subscribe to WebRTC P2P Signaling Events
      SupabaseService().subscribeToCallSignals(
        pairCode: auth.pairCode,
        onCallSignal: (payload) async {
          if (!mounted) return;
          final type = payload['type'];
          final senderId = payload['sender_id'];

          debugPrint("📞 [CallScreen Debug] Received signal type: '$type' from sender: '$senderId'");

          if (senderId != auth.currentUserId) {
            // When Partner Accepts, Caller creates and sends SDP Offer NOW!
            if (type == 'call_accepted' && widget.isCaller) {
              debugPrint("🚀 [CallScreen Debug] Partner accepted call! Creating & sending SDP Offer now...");
              final offer = await _rtcService.createOffer();
              if (offer != null) {
                await SupabaseService().sendCallSignal(
                  pairCode: auth.pairCode,
                  senderId: auth.currentUserId,
                  receiverId: auth.partnerUser.id,
                  callerName: auth.currentUser.name,
                  type: 'webrtc_offer',
                  isVideo: widget.isVideoCall,
                  extraData: {'sdp': offer.sdp},
                );
              }
            } else if (type == 'webrtc_offer') {
              final sdp = payload['sdp'];
              if (sdp != null) {
                debugPrint("📩 [CallScreen Debug] Handling incoming webrtc_offer...");
                final offer = RTCSessionDescription(sdp, 'offer');
                final answer = await _rtcService.createAnswer(offer);
                if (answer != null) {
                  debugPrint("📤 [CallScreen Debug] Sending webrtc_answer payload back to caller...");
                  await SupabaseService().sendCallSignal(
                    pairCode: auth.pairCode,
                    senderId: auth.currentUserId,
                    receiverId: auth.partnerUser.id,
                    callerName: auth.currentUser.name,
                    type: 'webrtc_answer',
                    isVideo: widget.isVideoCall,
                    extraData: {'sdp': answer.sdp},
                  );
                }
              }
            } else if (type == 'webrtc_answer') {
              final sdp = payload['sdp'];
              if (sdp != null) {
                debugPrint("📩 [CallScreen Debug] Handling incoming webrtc_answer...");
                final answer = RTCSessionDescription(sdp, 'answer');
                await _rtcService.setRemoteAnswer(answer);
              }
            } else if (type == 'webrtc_ice') {
              final candidateMap = payload['candidate'];
              if (candidateMap != null) {
                debugPrint("📩 [CallScreen Debug] Handling incoming webrtc_ice candidate...");
                final candidate = RTCIceCandidate(
                  candidateMap['candidate'],
                  candidateMap['sdpMid'],
                  candidateMap['sdpMLineIndex'],
                );
                await _rtcService.addIceCandidate(candidate);
              }
            } else if (type == 'call_ended') {
              debugPrint("🔴 [CallScreen Debug] Call ended by partner!");
              Navigator.pop(context);
            }
          }
        },
      );

      // 2. Initialize PeerConnection and set candidate & stream handlers
      await _rtcService.createPeerConnectionInstance(
        onIceCandidate: (candidate) {
          SupabaseService().sendCallSignal(
            pairCode: auth.pairCode,
            senderId: auth.currentUserId,
            receiverId: auth.partnerUser.id,
            callerName: auth.currentUser.name,
            type: 'webrtc_ice',
            isVideo: widget.isVideoCall,
            extraData: {
              'candidate': {
                'sdpMid': candidate.sdpMid,
                'sdpMLineIndex': candidate.sdpMLineIndex,
                'candidate': candidate.candidate,
              }
            },
          );
        },
        onAddStream: (stream) {
          debugPrint("🎬 [CallScreen Debug] Remote media stream received! Updating UI state...");
          if (mounted) {
            setState(() {
              _hasRemoteStream = true;
            });
          }
        },
      );

      // 3. If Receiver, send call_accepted signal to notify Caller that VideoCallScreen is active
      if (!widget.isCaller) {
        debugPrint("🟢 [CallScreen Debug] Receiver joined VideoCallScreen! Sending call_accepted signal...");
        await SupabaseService().sendCallSignal(
          pairCode: auth.pairCode,
          senderId: auth.currentUserId,
          receiverId: auth.partnerUser.id,
          callerName: auth.currentUser.name,
          type: 'call_accepted',
          isVideo: widget.isVideoCall,
        );
      }

      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _rtcService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Remote Video Stream View (Fullscreen)
            if (_hasRemoteStream && widget.isVideoCall)
              Positioned.fill(
                child: RTCVideoView(
                  _rtcService.remoteRenderer,
                  mirror: false,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              // Waiting for partner / Avatar View
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.whatsappAccent,
                      child: Text(
                        widget.partnerName.isNotEmpty
                            ? widget.partnerName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.partnerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConnected
                          ? 'Secured WebRTC P2P Call Connected'
                          : 'Connecting End-to-End Encrypted P2P...',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),

            // 2. Local PIP Camera Overlay (top right thumbnail)
            if (widget.isVideoCall && !_rtcService.isVideoOff)
              Positioned(
                top: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 110,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFF202C33),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.whatsappAccent, width: 2),
                    ),
                    child: RTCVideoView(
                      _rtcService.localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // 3. Bottom Control Bar (Mute, Camera Toggle, Flip, End Call)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111B21).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Mute Microphone
                    IconButton(
                      icon: Icon(
                        _rtcService.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: _rtcService.isMuted ? Colors.redAccent : Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _rtcService.toggleMute();
                        });
                      },
                    ),

                    // Toggle Camera
                    if (widget.isVideoCall)
                      IconButton(
                        icon: Icon(
                          _rtcService.isVideoOff
                              ? Icons.videocam_off_rounded
                              : Icons.videocam_rounded,
                          color: _rtcService.isVideoOff ? Colors.redAccent : Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            _rtcService.toggleVideo();
                          });
                        },
                      ),

                    // Flip Camera
                    if (widget.isVideoCall)
                      IconButton(
                        icon: const Icon(
                          Icons.cameraswitch_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          _rtcService.switchCamera();
                        },
                      ),

                    // End Call Button (Red)
                    InkWell(
                      onTap: () {
                        widget.onEndCall();
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

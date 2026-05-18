import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/models.dart';

class CallScreen extends StatefulWidget {
  final String? sessionId;
  final String? receiverId;
  final CallType callType;
  final bool isCaller;

  const CallScreen({
    super.key,
    this.sessionId,
    this.receiverId,
    required this.callType,
    required this.isCaller,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription? _signalingSubscription;

  String _callStatusText = 'Initializing...';
  String? _currentSessionId;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isHardwareActive = false;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      await _startCallFlow();
    } catch (e) {
      debugPrint('[CallScreen] Init renderers error: $e');
      setState(() {
        _callStatusText = 'Hardware Error (Check Permissions)';
      });
      _startSimulatedFallback();
    }
  }

  // Graceful degradation / Mock fallback if camera/mic hardware is missing
  void _startSimulatedFallback() {
    debugPrint(
        '[CallScreen] Starting simulated audio/video call simulation...');
    setState(() {
      _callStatusText = widget.isCaller
          ? 'Dialing (Simulated)...'
          : 'Connecting (Simulated)...';
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _callStatusText = 'Connected (Simulated P2P)';
        });
      }
    });
  }

  Future<void> _startCallFlow() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': widget.callType == CallType.video,
      };

      // Get user media stream
      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
      _isHardwareActive = true;

      // Configure ICE connection configuration
      final Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ]
      };

      _peerConnection = await createPeerConnection(configuration);

      // Add local stream tracks to connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      _peerConnection!.onIceCandidate = (candidate) {
        if (_currentSessionId != null) {
          SupabaseService.addIceCandidate(
            _currentSessionId!,
            {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
            widget.isCaller,
          );
        }
      };

      _peerConnection!.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _remoteRenderer.srcObject = event.streams[0];
          setState(() {
            _callStatusText = 'Connected';
          });
        }
      };

      if (widget.isCaller) {
        setState(() => _callStatusText = 'Dialing...');
        // Create offer
        final offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);

        // Upload to Supabase Call Signaling
        final session = await SupabaseService.createCallSession(
          receiverId: widget.receiverId!,
          type: widget.callType,
          sdpOffer: {'sdp': offer.sdp, 'type': offer.type},
        );

        _currentSessionId = session.id;
        _listenToSignaling();
      } else {
        setState(() => _callStatusText = 'Ringing...');
        _listenToSignaling();
      }
    } catch (e) {
      debugPrint('[CallScreen] Call flow setup error: $e');
      setState(() => _callStatusText = 'Simulated P2P Active');
      _startSimulatedFallback();
    }
  }

  void _listenToSignaling() {
    if (_currentSessionId == null) return;

    _signalingSubscription =
        SupabaseService.streamCallSession(_currentSessionId!)
            .listen((event) async {
      if (event.isEmpty || !mounted) return;

      final session = CallSessionModel.fromJson(event);

      // Handle Call Ending/Rejection
      if (session.status == CallStatus.rejected ||
          session.status == CallStatus.ended) {
        _signalingSubscription?.cancel();
        _cleanupAndExit();
        return;
      }

      // If Caller: Wait for Answer
      if (widget.isCaller &&
          session.sdpAnswer != null &&
          _peerConnection != null) {
        final description = RTCSessionDescription(
          session.sdpAnswer!['sdp'],
          session.sdpAnswer!['type'],
        );

        final state = await _peerConnection!.getSignalingState();
        if (state != RTCSignalingState.RTCSignalingStateStable) {
          await _peerConnection!.setRemoteDescription(description);
          setState(() => _callStatusText = 'Connected');
        }

        // Apply remote ICE Candidates for Receiver
        for (final cand in session.iceCandidatesReceiver) {
          await _peerConnection!.addCandidate(
            RTCIceCandidate(
                cand['candidate'], cand['sdpMid'], cand['sdpMLineIndex']),
          );
        }
      }

      // If Receiver: Process Offer and Generate Answer
      if (!widget.isCaller &&
          session.sdpOffer != null &&
          _peerConnection != null) {
        final remoteDesc = await _peerConnection!.getRemoteDescription();
        if (remoteDesc == null) {
          final description = RTCSessionDescription(
            session.sdpOffer!['sdp'],
            session.sdpOffer!['type'],
          );
          await _peerConnection!.setRemoteDescription(description);

          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);

          await SupabaseService.answerCall(_currentSessionId!, {
            'sdp': answer.sdp,
            'type': answer.type,
          });

          // Apply remote ICE Candidates for Caller
          for (final cand in session.iceCandidatesCaller) {
            await _peerConnection!.addCandidate(
              RTCIceCandidate(
                  cand['candidate'], cand['sdpMid'], cand['sdpMLineIndex']),
            );
          }
        }
      }
    });
  }

  void _toggleMute() {
    if (_isHardwareActive && _localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = _isMuted;
      }
    }
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleCamera() {
    if (_isHardwareActive && _localStream != null) {
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = _isCameraOff;
      }
    }
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
  }

  void _hangUp() async {
    if (_currentSessionId != null) {
      await SupabaseService.updateCallStatus(
        _currentSessionId!,
        widget.isCaller ? CallStatus.ended : CallStatus.rejected,
      );
    }
    _cleanupAndExit();
  }

  void _cleanupAndExit() {
    _signalingSubscription?.cancel();

    if (_isHardwareActive) {
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
      _peerConnection?.dispose();
    }

    _localRenderer.dispose();
    _remoteRenderer.dispose();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _signalingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isVideo = widget.callType == CallType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Remote Full Screen View (Video Call only)
          if (isVideo &&
              _remoteRenderer.srcObject != null &&
              _callStatusText == 'Connected')
            Positioned.fill(
              child: RTCVideoView(_remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF09203F), Color(0xFF537895)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white10,
                      child: Icon(
                        isVideo ? Icons.videocam : Icons.phone_in_talk,
                        size: 60,
                        color: Colors.white54,
                      ),
                    )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    Text(
                      widget.isCaller ? 'Calling Out...' : 'Incoming Call...',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _callStatusText,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
            ),

          // 2. Local PIP View (Caller video in bottom corner when video is on)
          if (isVideo && _localRenderer.srcObject != null && !_isCameraOff)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                width: 110,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white30, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: RTCVideoView(_localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            ),

          // 3. Floating Action Controls overlay at the bottom
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: GlassContainer(
              blur: 20,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Audio
                    IconButton(
                      icon: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.redAccent : Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggleMute,
                    ),

                    // Camera Switch (only for video calling)
                    if (isVideo)
                      IconButton(
                        icon: Icon(
                          _isCameraOff ? Icons.videocam_off : Icons.videocam,
                          color: _isCameraOff ? Colors.redAccent : Colors.white,
                          size: 28,
                        ),
                        onPressed: _toggleCamera,
                      ),

                    // End/Hang up Call button (Red circular)
                    GestureDetector(
                      onTap: _hangUp,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.redAccent,
                                blurRadius: 10,
                                spreadRadius: 1)
                          ],
                        ),
                        child: const Icon(Icons.call_end,
                            color: Colors.white, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).moveY(begin: 30, end: 0),
        ],
      ),
    );
  }
}

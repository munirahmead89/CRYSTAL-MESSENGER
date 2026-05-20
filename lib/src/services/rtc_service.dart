import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';

class RTCService {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;

  Future<void> initLocalStream({bool audio = true, bool video = true}) async {
    final constraints = <String, dynamic>{
      'audio': audio,
      'video': video ? {'facingMode': 'user'} : false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
  }

  Future<RTCPeerConnection> _createPeer() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };
    final pc = await createPeerConnection(config);
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        pc.addTrack(track, _localStream!);
      }
    }
    pc.onIceCandidate = (candidate) async {
      // send ICE candidate over Supabase realtime signaling (implement as needed)
      if (candidate != null) {
        try {
          await Supabase.instance.client.from('calls_signaling').insert({
            'call_id': 'unknown',
            'type': 'ice',
            'payload': {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMlineIndex,
            }
          });
        } catch (e) {
          AppLogger.e('ICEPub', e.toString());
        }
      }
    };
    pc.onTrack = (event) {
      // remote stream handling
      AppLogger.d('Remote track received');
    };
    return pc;
  }

  Future<void> startCall(String callId) async {
    _pc = await _createPeer();
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    // Post offer to Supabase calls table
    try {
      await Supabase.instance.client.from('calls').insert({
        'id': callId,
        'sdp_offer': {'sdp': offer.sdp, 'type': offer.type},
        'status': 'ringing'
      });
    } catch (e) {
      AppLogger.e('StartCall', e.toString());
    }
  }

  Future<void> handleRemoteOffer(Map<String, dynamic> offer, String callId) async {
    _pc = await _createPeer();
    await _pc!.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await Supabase.instance.client.from('calls').update({'sdp_answer': {'sdp': answer.sdp, 'type': answer.type}, 'status': 'active'}).eq('id', callId);
  }

  void dispose() {
    _pc?.close();
    _localStream?.dispose();
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:dio/dio.dart';

// 1. Keeping your precise State Definition Framework
class MeetRoomState {
  final bool isLoading;
  final String? error;
  final Room? room;
  final bool isAudioEnabled;
  final bool isVideoEnabled;
  final bool isScreenSharing;
  final List<Map<String, dynamic>> chatMessages;

  MeetRoomState({
    this.isLoading = true,
    this.error,
    this.room,
    this.isAudioEnabled = true,
    this.isVideoEnabled = true,
    this.isScreenSharing = false,
    this.chatMessages = const [],
  });

  MeetRoomState copyWith({
    bool? isLoading,
    String? error,
    Room? room,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isScreenSharing,
    List<Map<String, dynamic>>? chatMessages,
  }) {
    return MeetRoomState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      room: room ?? this.room,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}

// 2. Updated StateNotifier Provider passing the Ref context object
final meetControllerProvider = StateNotifierProvider.family<MeetController, MeetRoomState, String>((ref, interviewId) {
  return MeetController(interviewId, ref);
});

class MeetController extends StateNotifier<MeetRoomState> {
  final String interviewId;
  final Ref _ref;

  // Your base LiveKit WebRTC SFU server URL endpoint configuration
  final String livekitUrl = "http://10.0.2.2:7880";

  MeetController(this.interviewId, this._ref) : super(MeetRoomState());

  // Resolves the fully configured persistent cookie client instance
  Future<Dio> _getDio() async {
    return await _ref.read(dioProvider.future);
  }

  Future<void> initRoomAndConnect() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Fetch our configured instance of Dio containing cookies & interceptors
      final dio = await _getDio();

      // 1. Fetch Room Authentication Token payload signatures from Express
      // Hit path relative to base ('http://10.0.2.2:8000/api/')
      final response = await dio.post('interviews/$interviewId/token/jobseeker');

      if (response.data?['success'] != true || response.data?['token'] == null) {
        throw Exception(response.data?['message'] ?? 'Failed to parse authorization token signatures.');
      }

      final String token = response.data['token'];

      // 2. Initialize LiveKit Room Engine
      final room = Room();
      final listener = room.createListener();
      _setupRoomListeners(listener);

      // Connect to the room signaling transport channels
      await room.connect(livekitUrl, token);

      // 3. Publish Local Video & Audio Tracks automatically on launch
      await room.localParticipant?.setCameraEnabled(true);
      await room.localParticipant?.setMicrophoneEnabled(true);

      state = state.copyWith(
        isLoading: false,
        room: room,
        isAudioEnabled: true,
        isVideoEnabled: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupRoomListeners(EventsListener<RoomEvent> listener) {
    // Listen for incoming Data Messages (Chat Text Messages)
    listener.on<DataReceivedEvent>((event) {
      try {
        final decodedString = utf8.decode(event.data);
        final Map<String, dynamic> messageMap = jsonDecode(decodedString);

        state = state.copyWith(
          chatMessages: [...state.chatMessages, messageMap],
        );
      } catch (e) {
        debugPrint('Failed parsing data channel payload buffer structure: $e');
      }
    });

    // Structural room events setup to trigger UI repaints
    listener.on<ParticipantConnectedEvent>((_) => _forceStateRefresh());
    listener.on<ParticipantDisconnectedEvent>((_) => _forceStateRefresh());
    listener.on<TrackSubscribedEvent>((_) => _forceStateRefresh());
    listener.on<TrackUnsubscribedEvent>((_) => _forceStateRefresh());
  }

  // Media Track Control Triggers
  Future<void> toggleAudio() async {
    if (state.room == null) return;
    final newValue = !state.isAudioEnabled;
    await state.room!.localParticipant?.setMicrophoneEnabled(newValue);
    state = state.copyWith(isAudioEnabled: newValue);
  }

  Future<void> toggleVideo() async {
    if (state.room == null) return;
    final newValue = !state.isVideoEnabled;
    await state.room!.localParticipant?.setCameraEnabled(newValue);
    state = state.copyWith(isVideoEnabled: newValue);
  }

  Future<void> toggleScreenShare() async {
    if (state.room == null) return;
    final newValue = !state.isScreenSharing;
    try {
      await state.room!.localParticipant?.setScreenShareEnabled(newValue);
      state = state.copyWith(isScreenSharing: newValue);
    } catch (e) {
      debugPrint("Screenshare platform pipeline activation error: $e");
    }
  }

  // Real-time Chat Data Channel Emitter
  // Real-time Chat Data Channel Emitter
  Future<void> sendChatMessage(String messageText) async {
    if (state.room == null || messageText.trim().isEmpty) return;

    final messagePayload = {
      'sender': state.room!.localParticipant?.identity ?? 'Candidate',
      'text': messageText.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final List<int> dataBuffer = utf8.encode(jsonEncode(messagePayload));

      // FIX: Use the simple 'reliable' named boolean parameter directly
      await state.room!.localParticipant?.publishData(
        dataBuffer,
        reliable: true,
      );

      // Append your own message locally to the list array layout
      state = state.copyWith(
        chatMessages: [...state.chatMessages, messagePayload],
      );
    } catch (e) {
      debugPrint("Failed processing message broadcast stream frames: $e");
    }
  }

  void _forceStateRefresh() {
    state = state.copyWith(room: state.room);
  }

  Future<void> disconnectRoom() async {
    await state.room?.disconnect();
    state.room?.dispose();
  }
}
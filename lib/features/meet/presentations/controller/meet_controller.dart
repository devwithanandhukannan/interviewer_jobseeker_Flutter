import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

// Precise State Definition Framework
class MeetRoomState {
  final bool isLoading;
  final String? error;
  final Room? room;
  final bool isAudioEnabled;
  final bool isVideoEnabled;
  final List<Map<String, dynamic>> chatMessages;

  MeetRoomState({
    this.isLoading = true,
    this.error,
    this.room,
    this.isAudioEnabled = true,
    this.isVideoEnabled = true,
    this.chatMessages = const [],
  });

  MeetRoomState copyWith({
    bool? isLoading,
    String? error,
    Room? room,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    List<Map<String, dynamic>>? chatMessages,
  }) {
    return MeetRoomState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      room: room ?? this.room,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}

// StateNotifier Provider passing the Ref context object
final meetControllerProvider = StateNotifierProvider.family<MeetController, MeetRoomState, String>((ref, interviewId) {
  return MeetController(interviewId, ref);
});

class MeetController extends StateNotifier<MeetRoomState> {
  final String interviewId;
  final Ref _ref;

  // Base LiveKit WebRTC SFU server URL endpoint configuration
  final String livekitUrl = "http://10.0.2.2:7880";

  MeetController(this.interviewId, this._ref) : super(MeetRoomState());

  // Resolves the fully configured persistent cookie client instance
  Future<Dio> _getDio() async {
    return await _ref.read(dioProvider.future);
  }

  Future<void> initRoomAndConnect() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 1. Request Runtime Permissions directly prior to starting WebRTC tracks
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        throw Exception('Hardware Permissions (Camera/Microphone) are required to join the call.');
      }

      // Fetch our configured instance of Dio containing cookies & interceptors
      final dio = await _getDio();

      // 2. Fetch Room Authentication Token payload signatures from Express
      final response = await dio.post('interviews/$interviewId/token/jobseeker');

      if (response.data?['success'] != true || response.data?['token'] == null) {
        throw Exception(response.data?['message'] ?? 'Failed to parse authorization token signatures.');
      }

      final String token = response.data['token'];

      // 3. Initialize LiveKit Room Engine
      final room = Room();
      final listener = room.createListener();
      _setupRoomListeners(listener);

      // Connect to the room signaling transport channels
      await room.connect(livekitUrl, token);

      // 4. Publish Local Video & Audio Tracks automatically on launch
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
      // CRITICAL FIX: Only parse messages sent explicitly over the 'chat' topic channel
      if (event.topic == 'chat') {
        try {
          final decodedString = utf8.decode(event.data);
          final Map<String, dynamic> messageMap = jsonDecode(decodedString);

          state = state.copyWith(
            chatMessages: [...state.chatMessages, messageMap],
          );
        } catch (e) {
          debugPrint('Failed parsing data channel payload buffer structure: $e');
        }
      }
    });

    // Structural room events setup to trigger UI repaints
    listener.on<ParticipantConnectedEvent>((_) => _forceStateRefresh());
    listener.on<ParticipantDisconnectedEvent>((_) => _forceStateRefresh());

    // Track publication updates (Crucial for remote hardware toggles & layout changes)
    listener.on<TrackSubscribedEvent>((_) => _forceStateRefresh());
    listener.on<TrackUnsubscribedEvent>((_) => _forceStateRefresh());
    listener.on<TrackPublishedEvent>((_) => _forceStateRefresh());
    listener.on<TrackUnpublishedEvent>((_) => _forceStateRefresh());
    listener.on<TrackMutedEvent>((_) => _forceStateRefresh());
    listener.on<TrackUnmutedEvent>((_) => _forceStateRefresh());
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

      // CRITICAL FIX: Explicitly pass the topic label to map with the Next.js frontend filter
      await state.room!.localParticipant?.publishData(
        dataBuffer,
        reliable: true,
        topic: 'chat',
      );

      // Append your own message locally to the state array layout
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
    final room = state.room;
    await room?.disconnect();
    room?.dispose();
  }
}
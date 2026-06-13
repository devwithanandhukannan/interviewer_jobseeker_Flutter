import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:interviewer/features/meet/presentations/controller/meet_controller.dart';

class InterviewRoomScreen extends ConsumerStatefulWidget {
  final String interviewId;
  const InterviewRoomScreen({super.key, required this.interviewId});

  @override
  ConsumerState<InterviewRoomScreen> createState() => _InterviewRoomScreenState();
}

class _InterviewRoomScreenState extends ConsumerState<InterviewRoomScreen> {
  final TextEditingController _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(meetControllerProvider(widget.interviewId).notifier).initRoomAndConnect();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(meetControllerProvider(widget.interviewId));

    if (roomState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(height: 16),
              Text(
                'Configuring secure WebRTC media pipes...',
                style: TextStyle(color: Color(0xFF71717A), fontSize: 13, fontFamily: 'monospace'),
              )
            ],
          ),
        ),
      );
    }

    if (roomState.error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 44),
                const SizedBox(height: 16),
                const Text('Verification Intercepted', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(roomState.error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Dashboard', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      );
    }

    // Explicit compilation type mapping to pass down clean Participant arrays
    final List<Participant> participants = [
      if (roomState.room?.localParticipant != null) roomState.room!.localParticipant!,
      ...roomState.room?.remoteParticipants.values.toList() ?? [],
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: participants.isEmpty
                    ? const Center(child: Text('Waiting for other parties to join...', style: TextStyle(color: Colors.grey)))
                    : _buildParticipantLayout(participants),
              ),
              _buildControlActionDock(context, roomState),
            ],
          ),
        ),
      ),
    );
  }

  // Balanced Interface Window Splitting Matrix
  Widget _buildParticipantLayout(List<Participant> participants) {
    if (participants.length == 1) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: _buildVideoTile(participants.first),
      );
    }

    if (participants.length == 2) {
      // Side-by-Side balanced layout array filling horizontally with 0 scroll constraints
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(child: _buildVideoTile(participants[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildVideoTile(participants[1])),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: participants.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        return _buildVideoTile(participants[index]);
      },
    );
  }

  Widget _buildVideoTile(Participant participant) {
    final videoPub = participant.videoTrackPublications.isNotEmpty
        ? participant.videoTrackPublications.first
        : null;

    final videoTrack = videoPub?.track;
    final bool hasVideo = videoTrack != null && videoPub!.subscribed && !videoPub.muted;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasVideo && videoTrack is VideoTrack)
            VideoTrackRenderer(videoTrack)
          else
            Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withOpacity(0.04),
                child: Text(
                  (participant.identity ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    participant.identity ?? 'User',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    participant.isMicrophoneEnabled() ? Icons.mic_rounded : Icons.mic_off_rounded,
                    size: 13,
                    color: participant.isMicrophoneEnabled() ? Colors.greenAccent : Colors.redAccent,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildControlActionDock(BuildContext context, MeetRoomState state) {
    final notifier = ref.read(meetControllerProvider(widget.interviewId).notifier);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            isActive: state.isAudioEnabled,
            activeIcon: Icons.mic_rounded,
            inactiveIcon: Icons.mic_off_rounded,
            onPressed: () => notifier.toggleAudio(),
          ),
          _buildActionButton(
            isActive: state.isVideoEnabled,
            activeIcon: Icons.videocam_rounded,
            inactiveIcon: Icons.videocam_off_rounded,
            onPressed: () => notifier.toggleVideo(),
          ),
          Badge(
            label: Text(state.chatMessages.length.toString()),
            isLabelVisible: state.chatMessages.isNotEmpty,
            backgroundColor: Colors.blueAccent,
            child: _buildActionButton(
              isActive: true,
              activeIcon: Icons.chat_bubble_outline_rounded,
              inactiveIcon: Icons.chat_bubble_outline_rounded,
              onPressed: () => _openChatBottomSheet(context),
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.red.shade600,
            radius: 24,
            child: IconButton(
              icon: const Icon(Icons.call_end_rounded, color: Colors.white),
              onPressed: () async {
                await notifier.disconnectRoom();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required bool isActive,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required VoidCallback onPressed,
  }) {
    return CircleAvatar(
      backgroundColor: isActive ? const Color(0xFF18181B) : Colors.redAccent.withOpacity(0.9),
      radius: 24,
      child: IconButton(
        icon: Icon(isActive ? activeIcon : inactiveIcon, color: Colors.white, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  void _openChatBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final roomState = ref.watch(meetControllerProvider(widget.interviewId));
            final roomNotifier = ref.read(meetControllerProvider(widget.interviewId).notifier);
            final localIdentity = roomState.room?.localParticipant?.identity ?? 'Candidate';

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        const Text(
                          'IN-CALL CHAT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: roomState.chatMessages.isEmpty
                          ? const Center(child: Text('No messages shared yet.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                          : ListView.builder(
                        itemCount: roomState.chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = roomState.chatMessages[index];
                          final String sender = msg['sender'] ?? 'User';
                          final bool isSelf = sender == localIdentity;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    isSelf ? 'You' : sender.split('_').first,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelf
                                        ? const Color(0xFF2563EB) // Blue for self (Right)
                                        : Colors.white.withOpacity(0.06), // Slate dark for others (Left)
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isSelf ? 16 : 4),
                                      bottomRight: Radius.circular(isSelf ? 4 : 16),
                                    ),
                                  ),
                                  child: Text(
                                    msg['text'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF09090B),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2563EB)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: const Color(0xFF2563EB),
                          radius: 22,
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            onPressed: () {
                              if (_msgCtrl.text.trim().isNotEmpty) {
                                roomNotifier.sendChatMessage(_msgCtrl.text);
                                _msgCtrl.clear();
                              }
                            },
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
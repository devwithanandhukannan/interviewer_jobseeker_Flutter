import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/interview/presentation/controller/interview_controller.dart';

class InterviewScreen extends ConsumerStatefulWidget {
  const InterviewScreen({super.key});

  @override
  ConsumerState<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(interviewControllerProvider.notifier).fetchData();
    });
  }

  String _formatDateTime(String rawDateTime) {
    if (rawDateTime.isEmpty) return 'TBD';
    try {
      final parsed = DateTime.parse(rawDateTime).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[parsed.month - 1];
      final day = parsed.day;

      final period = parsed.hour >= 12 ? 'PM' : 'AM';
      int hour = parsed.hour % 12;
      if (hour == 0) hour = 12;

      final minute = parsed.minute.toString().padLeft(2, '0');
      return '$month $day • $hour:$minute $period';
    } catch (_) {
      return rawDateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Interview Hub",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.15), height: 0.5),
        ),
      ),
      body: state.interviewData.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)),
        error: (error, stackTrace) => Center(
          child: Text(error.toString(), style: const TextStyle(color: Color(0xFF3A3A3C))),
        ),
        data: (response) {
          final List interviews = (response['data'] as List?) ?? [];

          if (interviews.isEmpty) {
            return RefreshIndicator(
              color: Colors.black,
              onRefresh: () => ref.read(interviewControllerProvider.notifier).fetchData(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "No interviews scheduled",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.black,
            onRefresh: () => ref.read(interviewControllerProvider.notifier).fetchData(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: interviews.length,
              itemBuilder: (context, index) {
                final interview = interviews[index];
                final application = interview['application'] ?? {};
                final jobPosting = application['jobPosting'] ?? {};
                final company = jobPosting['company'] ?? {};

                final id = interview['id']?.toString() ?? '';
                final title = jobPosting['title'] ?? 'Technical Session';
                final companyName = company['name'] ?? 'Company';
                final status = (interview['status'] ?? 'scheduled').toString().toLowerCase();
                final format = interview['format'] ?? 'Video Call';
                final duration = interview['durationMinutes'] ?? 0;
                final scheduledTime = interview['scheduledTime'] ?? '';

                final hasPendingReschedule = status == 'reschedule_requested';
                final isInactive = ['completed', 'cancelled'].contains(status);

                // Design Color Mapping Tokens
                Color statusColor = const Color(0xFF8E8E93);
                Color statusBg = const Color(0xFFF2F2F7);
                String labelText = status.toUpperCase();

                if (status == 'confirmed') {
                  statusColor = const Color(0xFF34C759);
                  statusBg = const Color(0xFFEAF9EB);
                  labelText = "CONFIRMED";
                } else if (status == 'scheduled') {
                  statusColor = const Color(0xFF007AFF);
                  statusBg = const Color(0xFFE5F1FF);
                  labelText = "SCHEDULED";
                } else if (status == 'reschedule_requested') {
                  statusColor = const Color(0xFFFF9500);
                  statusBg = const Color(0xFFFFF2E0);
                  labelText = "RESCHEDULE PENDING";
                } else if (status == 'in_progress') {
                  statusColor = const Color(0xFFA55EEA);
                  statusBg = const Color(0xFFF5E6FF);
                  labelText = "LIVE SESSION";
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black, letterSpacing: -0.3),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    companyName,
                                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                labelText,
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0xFFE5E5EA), height: 1, thickness: 0.6),
                        ),

                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF8E8E93)),
                            const SizedBox(width: 8),
                            Text(_formatDateTime(scheduledTime), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1C1C1E))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.videocam_outlined, size: 15, color: Color(0xFF8E8E93)),
                            const SizedBox(width: 8),
                            Text("$format  •  $duration mins", style: const TextStyle(fontSize: 13, color: Color(0xFF636366))),
                          ],
                        ),

                        // Render Proposal Tracker Alert Info Banner
                        if (hasPendingReschedule && interview['rescheduleRequests'] != null && (interview['rescheduleRequests'] as List).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9F0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFE5BC), width: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Proposed New Window:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF9500))),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDateTime(interview['rescheduleRequests'][0]['proposedTime'] ?? ''),
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                                if (interview['rescheduleRequests'][0]['candidateNote']?.toString().isNotEmpty ?? false) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Note: \"${interview['rescheduleRequests'][0]['candidateNote']}\"",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontStyle: FontStyle.italic),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],

                        // Control Button Interface Container
                        if (!isInactive) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              if (!hasPendingReschedule && status != 'confirmed') ...[
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFE5E5EA)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                    ),
                                    onPressed: state.isSubmitting ? null : () async {
                                      final success = await ref.read(interviewControllerProvider.notifier).confirmInterview(id);
                                      if (context.mounted && success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Attendance presence verified.')),
                                        );
                                      }
                                    },
                                    child: const Text("Confirm", style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (!hasPendingReschedule) ...[
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFE5E5EA)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                    ),
                                    onPressed: state.isSubmitting ? null : () => _showRescheduleSheet(context, id),
                                    child: const Text("Reschedule", style: TextStyle(color: Color(0xFF636366), fontSize: 13, fontWeight: FontWeight.w500)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                  ),
                                  onPressed: () {
                                    // Deep link channel route mapping handler target
                                  },
                                  child: const Text("Join", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Interactive Bottom Sheet for Proposing a Reschedule
  void _showRescheduleSheet(BuildContext context, String interviewId) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Request Modification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                  const SizedBox(height: 4),
                  const Text("Propose a fresh scheduling availability matrix coordinate window.", style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.calendar_month, size: 16, color: Colors.black87),
                          label: Text(
                            selectedDate == null ? "Select Date" : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) setModalState(() => selectedDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.access_time_rounded, size: 16, color: Colors.black87),
                          label: Text(
                            selectedTime == null ? "Select Time" : selectedTime!.format(context),
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) setModalState(() => selectedTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Provide context regarding availability shifts...",
                      hintStyle: const TextStyle(color: Color(0xFFBcBcBd), fontSize: 13),
                      fillColor: const Color(0xFFF2F2F7),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE5E5EA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (selectedDate == null || selectedTime == null) ? null : () async {
                        final combinedDateTime = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );

                        Navigator.pop(context); // Dismiss drawer

                        final dispatch = await ref.read(interviewControllerProvider.notifier).requestReschedule(
                          interviewId: interviewId,
                          proposedTime: combinedDateTime,
                          note: noteController.text.trim(),
                        );

                        if (context.mounted && dispatch) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reschedule proposal request pipeline dispatched.')),
                          );
                        }
                      },
                      child: const Text("Submit Proposal Request", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
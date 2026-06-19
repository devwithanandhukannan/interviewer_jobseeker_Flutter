import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:interviewer/core/dio_controller.dart';
import 'package:interviewer/features/dashboard/presentation/controller/job_controller.dart';
import 'package:interviewer/features/dashboard/presentation/controller/resume_controller.dart';
import 'package:interviewer/features/interview/presentation/controller/interview_controller.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class ViewapplicationstatusScreen extends ConsumerStatefulWidget {
  final String applicationID;

  const ViewapplicationstatusScreen({
    super.key,
    required this.applicationID,
  });

  @override
  ConsumerState<ViewapplicationstatusScreen> createState() =>
      _ViewapplicationstatusScreenState();
}

class _ViewapplicationstatusScreenState
    extends ConsumerState<ViewapplicationstatusScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(jobApplicationProvider.notifier)
          .fetchApplicationLogs(widget.applicationID);
    });
  }

  String _formatDateTimeString(String? rawIso) {
    if (rawIso == null || rawIso.isEmpty) return 'Date/Time Unknown';
    try {
      final DateTime dt = DateTime.parse(rawIso).toLocal();
      final List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final String month = months[dt.month - 1];
      final int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final String period = dt.hour >= 12 ? 'PM' : 'AM';
      final String minute = dt.minute.toString().padLeft(2, '0');

      return '$month ${dt.day}, ${dt.year} • $hour:$minute $period';
    } catch (_) {
      return 'Date/Time Unknown';
    }
  }

  String _formatShortTime(String? rawIso) {
    if (rawIso == null) return '';
    try {
      final DateTime dt = DateTime.parse(rawIso).toLocal();
      final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final String period = dt.hour >= 12 ? 'PM' : 'AM';
      final String minute = dt.minute.toString().padLeft(2, '0');

      return '${months[dt.month - 1]} ${dt.day}, $hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobApplicationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Application Status',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        centerTitle: false,
      ),
      body: state.applicationState.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error: ${e.toString()}', style: const TextStyle(color: Colors.redAccent)),
          ),
        ),
        data: (rawResponse) {
          if (rawResponse == null) {
            return const Center(child: Text('No application information found.'));
          }

          final Map<String, dynamic> responseMap = rawResponse is Map<String, dynamic> ? rawResponse : {};
          final Map<String, dynamic> data = responseMap['data'] ?? {};

          if (data.isEmpty) {
            return const Center(child: Text('Failed to parse application layout data.'));
          }

          final jobDetails = data['jobDetails'] ?? {};
          final companyDetails = data['companyDetails'] ?? {};
          final resumeUsed = data['resumeUsed'] ?? {};
          final List<dynamic> timeline = data['timelineView'] ?? [];
          final List<dynamic> interviews = data['interviewHistory'] ?? [];
          final String currentStage = data['currentStage']?.toString() ?? 'applied';

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(jobApplicationProvider.notifier)
                  .fetchApplicationLogs(widget.applicationID);
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildOverviewCard(jobDetails, companyDetails, currentStage),
                const SizedBox(height: 20),

                if (resumeUsed.isNotEmpty) ...[
                  _buildSectionHeader('Attached Documents'),
                  const SizedBox(height: 10),
                  _buildResumeCard(resumeUsed),
                  const SizedBox(height: 24),
                ],

                if (interviews.isNotEmpty) ...[
                  _buildSectionHeader('Scheduled Interviews'),
                  const SizedBox(height: 10),
                  ...interviews.map((item) => _buildInterviewItem(item)).toList(),
                  const SizedBox(height: 24),
                ],

                if (timeline.isNotEmpty) ...[
                  _buildSectionHeader('Application Timeline'),
                  const SizedBox(height: 16),
                  _buildTimelineBlock(timeline),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildOverviewCard(Map<String, dynamic> job, Map<String, dynamic> company, String stage) {
    final bool isHired = stage.toLowerCase() == 'hired';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  job['title'] ?? 'Role Title',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isHired ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  stage.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHired ? Colors.green.shade700 : Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            company['name'] ?? 'Company Name',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFEDF2F7)),
          ),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _buildCompactFactRow(Icons.location_on_outlined, job['location'] ?? 'N/A'),
              _buildCompactFactRow(Icons.work_outline, job['jobType'] ?? 'N/A'),
              _buildCompactFactRow(Icons.payments_outlined, job['compensationContext'] ?? 'N/A'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCompactFactRow(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568))),
      ],
    );
  }

  Widget _buildResumeCard(Map<String, dynamic> resume) {
    final String resumeId = resume['id']?.toString() ?? '';
    final String resumeName = resume['name'] ?? 'Applied CV';
    final String fileName = resumeName.toLowerCase().endsWith('.pdf') ? resumeName : '$resumeName.pdf';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.withOpacity(0.08),
            radius: 20,
            child: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.redAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              resumeName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, size: 22, color: Colors.blueAccent),
            onPressed: () async {
              if (resumeId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Missing reference identifier for this document resource.')),
                );
                return;
              }

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 12),
                      Text('Preparing document...'),
                    ],
                  ),
                  duration: Duration(seconds: 30),
                ),
              );

              try {
                final dio = await ref.read(dioProvider.future);
                final cacheDir = await getTemporaryDirectory();
                final tempPath = '${cacheDir.path}/$fileName';

                await dio.download(
                  'jobseeker/resumes/$resumeId/download',
                  tempPath,
                );

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                final XFile file = XFile(tempPath);
                await Share.shareXFiles([file], text: 'Resume: $fileName');
              } catch (err) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Download failed: $err')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewItem(Map<String, dynamic> interview) {
    final String interviewId = interview['interviewId']?.toString() ?? '';
    final String formattedTime = _formatDateTimeString(interview['scheduledTime']?.toString());
    final String formatType = interview['format']?.toString().toUpperCase() ?? 'VIDEO CALL';
    final String status = (interview['status'] ?? 'scheduled').toString().toLowerCase();

    final hasPendingReschedule = status == 'reschedule_requested';
    final isInactive = ['completed', 'cancelled'].contains(status);
    final interviewState = ref.watch(interviewControllerProvider);

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

    // Safe Extraction Logic for Reschedule Window Payload
    Map<String, dynamic>? latestRescheduleRequest;
    if (hasPendingReschedule && interview['rescheduleRequests'] != null) {
      final rawRequests = interview['rescheduleRequests'];
      if (rawRequests is Map<String, dynamic>) {
        latestRescheduleRequest = rawRequests;
      } else if (rawRequests is List && rawRequests.isNotEmpty) {
        latestRescheduleRequest = rawRequests[0] is Map<String, dynamic> ? rawRequests[0] : null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.video_call_outlined, size: 20, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    formatType,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  labelText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formattedTime,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Duration: ${interview['durationMinutes'] ?? 30} mins',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),

          if (latestRescheduleRequest != null) ...[
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
                  const Text(
                    "Proposed New Window:",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF9500)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTimeString(latestRescheduleRequest['proposedTime']?.toString() ?? ''),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  if (latestRescheduleRequest['candidateNote']?.toString().isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Note: \"${latestRescheduleRequest['candidateNote']}\"",
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontStyle: FontStyle.italic),
                    ),
                  ]
                ],
              ),
            ),
          ],

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
                      onPressed: interviewState.isSubmitting ? null : () async {
                        final success = await ref.read(interviewControllerProvider.notifier).confirmInterview(interviewId);
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Attendance presence verified.')),
                          );
                          await ref.read(jobApplicationProvider.notifier).fetchApplicationLogs(widget.applicationID);
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
                      onPressed: interviewState.isSubmitting ? null : () => _showRescheduleSheet(context, interviewId),
                      child: const Text("Reschedule", style: TextStyle(color: Color(0xFF636366), fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (interview['joinLink'] != null)
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: () {
                        final links = interview['joinLink'].toString().split(',');
                        final targetLink = links.isNotEmpty ? links[0] : interview['joinLink'];
                        debugPrint('Navigating directly out to target system: $targetLink');
                      },
                      child: const Text("Join", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ]
        ],
      ),
    );
  }

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

                        Navigator.pop(context);

                        final dispatch = await ref.read(interviewControllerProvider.notifier).requestReschedule(
                          interviewId: interviewId,
                          proposedTime: combinedDateTime,
                          note: noteController.text.trim(),
                        );

                        if (context.mounted && dispatch) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reschedule proposal request pipeline dispatched.')),
                          );
                          await ref.read(jobApplicationProvider.notifier).fetchApplicationLogs(widget.applicationID);
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

  Widget _buildTimelineBlock(List<dynamic> logs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final currentLog = logs[logs.length - 1 - index];
          final bool isLastItem = index == logs.length - 1;
          final String parsedDate = _formatShortTime(currentLog['date']?.toString());

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: index == 0 ? Colors.blue.shade600 : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index == 0 ? Colors.blue.shade100 : Colors.white,
                          width: index == 0 ? 3 : 1,
                        ),
                      ),
                    ),
                    if (!isLastItem)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatStageHeader(currentLog['stage']?.toString()),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: index == 0 ? const Color(0xFF1A1A1A) : const Color(0xFF718096),
                              ),
                            ),
                            Text(
                              parsedDate,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        if (currentLog['notes'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            currentLog['notes'].toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatStageHeader(String? rawStage) {
    if (rawStage == null) return 'Update Status';
    return rawStage.replaceAll('_', ' ').toUpperCase();
  }
}
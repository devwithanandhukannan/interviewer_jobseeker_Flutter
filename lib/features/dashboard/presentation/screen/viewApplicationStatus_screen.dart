import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/dashboard/presentation/controller/job_controller.dart';

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

  // Pure Dart helper to format ISO strings without relying on package:intl
  String _formatDateTimeString(String? rawIso) {
    if (rawIso == null) return 'Date/Time Unknown';
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

  // Compact formatter for timeline logs
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
          const Expanded(
            child: Text(
              'Applied CV',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, size: 22, color: Colors.blueAccent),
            onPressed: () {
              debugPrint('Downloading track or opening path file layout: ${resume['downloadPath']}');
              // Hook your execution environment's download manager logic here
            },
          )
        ],
      ),
    );
  }

  Widget _buildInterviewItem(Map<String, dynamic> interview) {
    final String formattedTime = _formatDateTimeString(interview['scheduledTime']?.toString());
    final String formatType = interview['format']?.toString().toUpperCase() ?? 'VIDEO';
    final String status = interview['status']?.toString() ?? 'scheduled';

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
                  Icon(Icons.video_call_outlined, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '$formatType INTERVIEW',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
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
          if (interview['joinLink'] != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.videocam, size: 16),
                label: const Text('Join Interview Room'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  final links = interview['joinLink'].toString().split(',');
                  final targetLink = links.isNotEmpty ? links[0] : interview['joinLink'];
                  debugPrint('Navigating directly out to target system: $targetLink');
                },
              ),
            )
          ]
        ],
      ),
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
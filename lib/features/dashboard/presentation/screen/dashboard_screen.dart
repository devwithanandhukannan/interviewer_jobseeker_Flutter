import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/dashboard/presentation/controller/dashboard_controller.dart';
import 'package:interviewer/features/dashboard/presentation/screen/job_detail_popup.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _activeView = 'pipeline'; // Core navigation filter tabs: 'pipeline' | 'interviews' | 'applied' | 'insights'

  /// Helper to safely format ISO strings into human-readable data format
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
    final state = ref.watch(dashboardControllerProvider);

    // Dynamic clean styling layout overrides for system bars
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ));

    // 1. Handle Asynchronous Active Loading State Block
    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
        ),
      );
    }

    // 2. Handle Telemetry Failure State Block
    if (state.errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Telemetry Error: ${state.errorMessage}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }

    // 3. Map Data Structures Safely Out of State Payload Map Configuration
    // if (state.dashboardData != null) {
    //   const encoder = JsonEncoder.withIndent('  ');
    //   final prettyString = encoder.convert(state.dashboardData);
    //   developer.log(prettyString, name: 'DASHBOARD_PAYLOAD');
    // }


    final profile = state.dashboardData?['profile'] ?? {};
    final summary = state.dashboardData?['applicationSummary'] ?? {};
    final recentApps = state.dashboardData?['recentApplications'] as List<dynamic>? ?? [];
    final interviews = state.dashboardData?['upcomingInterviews'] as List<dynamic>? ?? [];
    final offers = state.dashboardData?['pendingOffers'] as List<dynamic>? ?? [];
    final resume = state.dashboardData?['resume'] as Map<String, dynamic>? ?? {};
    final insights = state.dashboardData?['insights'] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hi, ${profile['fullName'] ?? 'Candidate'}',
              style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.4),
            ),
            const SizedBox(height: 2),
            const Text(
              'Monitor active evaluation matching pipelines.',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),

      ),
      body: RefreshIndicator(
        backgroundColor: Colors.white,
        color: Colors.black,
        onRefresh: () => ref.read(dashboardControllerProvider.notifier).fetchDashboardPayload(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildViewToggle(),
            const SizedBox(height: 16),

            if (_activeView == 'pipeline') ...[
              _buildProfileCompletionCard(profile),
              const SizedBox(height: 16),
              _buildMetricsGrid(summary, resume),
              if (offers.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildOffersSection(offers),
              ],
              const SizedBox(height: 20),
              _buildSectionHeader('Priority Panel Pipeline', () => setState(() => _activeView = 'interviews')),
              const SizedBox(height: 8),
              _buildInterviewsList(interviews),
              const SizedBox(height: 20),
              _buildSectionHeader('Recent Submissions Log', () => setState(() => _activeView = 'applied')),
              const SizedBox(height: 8),
              _buildApplicationsLedger(recentApps),
              const SizedBox(height: 20),
              _buildAssetMetadataCard(resume, profile),
            ] else if (_activeView == 'interviews') ...[
              _buildSectionHeaderCount('Active Panel Queues', interviews.length),
              const SizedBox(height: 8),
              _buildInterviewsList(interviews, expandedView: true),
            ] else if (_activeView == 'applied') ...[
              _buildSectionHeaderCount('Submission Ledger Trace', recentApps.length),
              const SizedBox(height: 8),
              _buildApplicationsLedger(recentApps, expandedView: true),
            ] else ...[
              _buildInsightsView(insights, summary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton('Pipeline', 'pipeline'),
            _buildTabButton('Interviews Spot', 'interviews'),
            _buildTabButton('Applied Jobs', 'applied'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tabKey) {
    final bool isSelected = _activeView == tabKey;
    return GestureDetector(
      onTap: () => setState(() => _activeView = tabKey),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF636366),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeaderCount(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '$title ($count)',
        style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildProfileCompletionCard(Map<String, dynamic> profile) {
    final int score = profile['completionScore'] ?? 0;
    final tips = profile['completionTips'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile Verification Vector', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('With visibility metrics engine', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$score', style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace', height: 1)),
                  const Text('/100', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontFamily: 'monospace')),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: const Color(0xFFF2F2F7),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            minHeight: 5,
            borderRadius: BorderRadius.circular(10),
          ),
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFE5E5EA), height: 1),
            const SizedBox(height: 10),
            Text(
              "Recommendation: ${tips.first}",
              style: const TextStyle(color: Color(0xFF636366), fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> summary, Map<String, dynamic> resume) {
    final String parsedAts = resume['atsScore'] != null ? '${resume['atsScore']}%' : 'N/A';
    final String resumeLabel = resume['name'] ?? 'No Master Asset';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildMetricTile('Applications', '${summary['total'] ?? 0}', '${summary['active'] ?? 0} active processing', Icons.business_center_outlined, Colors.blue),
        _buildMetricTile('Interview Spot', '${summary['inInterview'] ?? 0}', 'Live technical panels', Icons.video_camera_front_outlined, Colors.purple),
        _buildMetricTile('Offers Appended', '${summary['offerStage'] ?? 0}', 'Contract approval pending', Icons.workspace_premium_outlined, Colors.green),
        _buildMetricTile('ATS Parsing Index', parsedAts, resumeLabel, Icons.description_outlined, Colors.amber),
      ],
    );
  }

  Widget _buildMetricTile(String title, String mainValue, String subText, IconData icon, Color marker) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w600)),
              Icon(icon, size: 16, color: marker.withOpacity(0.8)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mainValue, style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(subText, style: const TextStyle(color: Color(0xFF636366), fontSize: 9, overflow: TextOverflow.ellipsis)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOffersSection(List<dynamic> offers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: offers.map((offer) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF9EB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF34C759).withOpacity(0.3), width: 0.8),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Icon(Icons.emoji_events_rounded, color: Color(0xFF34C759), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer['position'] ?? 'Offer Generated', style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(offer['company']?['name'] ?? 'Company Matrix', style: const TextStyle(color: Color(0xFF636366), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('Salary Asset: ${offer['currency']} ${offer['salary']}', style: const TextStyle(color: Color(0xFF34C759), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF34C759), size: 14),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
        GestureDetector(
          onTap: onAction,
          child: const Row(
            children: [
              Text('See All', style: TextStyle(color: Color(0xFF007AFF), fontSize: 12, fontWeight: FontWeight.w600)),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF007AFF), size: 14),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildInterviewsList(List<dynamic> interviews, {bool expandedView = false}) {
    if (interviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E5EA))),
        child: const Center(child: Text('No evaluation panels scheduled inside loop.', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12))),
      );
    }

    final displayList = expandedView ? interviews : interviews.take(2).toList();

    return Column(
      children: displayList.map((i) {
        final String status = (i['status'] ?? 'scheduled').toString().toLowerCase();
        Color statusColor = const Color(0xFF8E8E93);
        Color statusBg = const Color(0xFFF2F2F7);

        if (status == 'confirmed') {
          statusColor = const Color(0xFF34C759);
          statusBg = const Color(0xFFEAF9EB);
        } else if (status == 'scheduled') {
          statusColor = const Color(0xFF007AFF);
          statusBg = const Color(0xFFE5F1FF);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i['job'] ?? 'Technical Session', style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(i['company']?['name'] ?? 'Corporate Node', style: const TextStyle(color: Color(0xFF636366), fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Color(0xFFE5E5EA), height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF8E8E93)),
                      const SizedBox(width: 6),
                      Text(_formatDateTime(i['scheduledTime'] ?? ''), style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Text('• ${i['durationMinutes']} mins', style: const TextStyle(color: Color(0xFF636366), fontSize: 12)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      minimumSize: const Size(60, 28),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => debugPrint('Launching video: ${i['joinLink']}'),
                    child: const Text('Join', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplicationsLedger(List<dynamic> apps, {bool expandedView = false}) {
    if (apps.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E5EA))),
        child: const Center(child: Text('No active trace entries parsed.', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12))),
      );
    }

    final displayList = expandedView ? apps : apps.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
      ),
      child: Column(
        children: displayList.map((app) {
          final String status = (app['status'] ?? 'applied').toString().toLowerCase();
          Color tokenColor = const Color(0xFF636366);
          Color tokenBg = const Color(0xFFF2F2F7);

          if (status.contains('round') || status.contains('interview')) {
            tokenColor = const Color(0xFFA55EEA);
            tokenBg = const Color(0xFFF5E6FF);
          } else if (status == 'offer_sent') {
            tokenColor = const Color(0xFF34C759);
            tokenBg = const Color(0xFFEAF9EB);
          } else if (status == 'rejected') {
            tokenColor = const Color(0xFFFF453A);
            tokenBg = const Color(0xFFFFEAEA);
          }

          // Safe lookup for the nested Job Reference ID field inside the data item
          final String targetApplicationId = app['job']?['jobId'].toString() ?? '';

          return InkWell(
            onTap: () {
              if (targetApplicationId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot extract job reference identifier.')),
                );
                return;
              }

              // Kicks off and triggers the Draggable Scrollable popup view overlay layer
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withOpacity(0.5),
                builder: (context) => JobDetailPopup(jobId: targetApplicationId),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF2F2F7), width: 1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text((app['company']?['name'] ?? 'C').toString().substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(app['job']?['title'] ?? 'Role Position', style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis)),
                              const SizedBox(height: 1),
                              Text('${app['company']?['name']} • ${app['job']?['location']}', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: tokenBg, borderRadius: BorderRadius.circular(4)),
                    child: Text(status.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: tokenColor, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAssetMetadataCard(Map<String, dynamic> resume, Map<String, dynamic> profile) {
    final skills = profile['skills'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SYSTEM ASSET METADATA', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E5EA)), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active Artifact Vector', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('Total Submissions: ${resume['totalResumes'] ?? 0}', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(4)),
                    child: const Text('OPERATIONAL', style: TextStyle(color: Color(0xFF636366), fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Text(resume['name'] ?? 'Empty track index', style: const TextStyle(color: Color(0xFF636366), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E5EA))),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AUTOMATED ATS PARSING SCORE', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 9, fontWeight: FontWeight.bold)),
                        Text('${resume['atsScore'] ?? 0}%', style: const TextStyle(color: Colors.black, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: (resume['atsScore'] ?? 0) / 100, backgroundColor: const Color(0xFFE5E5EA), valueColor: const AlwaysStoppedAnimation<Color>(Colors.black), minHeight: 4),
                  ],
                ),
              ),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Configured Technical Vectors', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE5E5EA))),
                    child: Text(s.toString(), style: const TextStyle(color: Color(0xFF636366), fontSize: 10, fontFamily: 'monospace')),
                  )).toList(),
                )
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsView(Map<String, dynamic> insights, Map<String, dynamic> summary) {
    final industryBreakdown = insights['industryBreakdown'] as List<dynamic>? ?? [];
    final activityChart = stateDataActivityChartLookup();
    final int totalApps = summary['total'] ?? 1;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildInsightMetricTile('Conversion Velocity', '${insights['responseRate'] ?? 0}%', 'Foundational progression', Icons.trending_up)),
            const SizedBox(width: 12),
            Expanded(child: _buildInsightMetricTile('Mean Operational SLA', '${insights['avgResponseTimeDays'] ?? 0}d', 'Tracking baseline metric', Icons.speed_rounded)),
          ],
        ),
        const SizedBox(height: 16),

        // Industry Breakdown
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E5EA)), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TARGET DOMAIN CLUSTERS', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Telemetry matrix distribution of targets', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
              const SizedBox(height: 16),
              ...industryBreakdown.map((item) {
                final int count = item['count'] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['industry'] ?? '', style: const TextStyle(color: Color(0xFF636366), fontSize: 12)),
                          Text('$count loops', style: const TextStyle(color: Colors.black, fontSize: 11, fontFamily: 'monospace')),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: count / totalApps, backgroundColor: const Color(0xFFF2F2F7), valueColor: const AlwaysStoppedAnimation<Color>(Colors.black), minHeight: 4),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Weekly Activity Velocity Bar Chart
        if (activityChart.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E5EA)), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WEEKLY TRACKING VELOCITY', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('Volumetric validation index trailing chart metrics', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: activityChart.map<Widget>((t) {
                      final int count = t['count'] ?? 0;
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('$count', style: const TextStyle(color: Colors.black, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              height: (count * 6.0).clamp(4.0, 70.0),
                              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                            ),
                            const SizedBox(height: 6),
                            Text('Wk ${t['weekOffset']?.toString().replaceAll('-', '')}', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 9)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          )
      ],
    );
  }

  List<dynamic> stateDataActivityChartLookup() {
    final state = ref.read(dashboardControllerProvider);
    return state.dashboardData?['activityChart'] as List<dynamic>? ?? [];
  }

  Widget _buildInsightMetricTile(String title, String value, String sub, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E5EA)), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(icon, size: 14, color: const Color(0xFF8E8E93)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Color(0xFF636366), fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
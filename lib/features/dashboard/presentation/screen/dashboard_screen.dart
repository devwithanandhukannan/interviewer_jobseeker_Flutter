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
  String _activeView = 'overview';

  String _formatDateTime(String raw) {
    if (raw.isEmpty) return 'TBD';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day} • $h:$m $period';
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hired':         return const Color(0xFF34C759);
      case 'rejected':      return const Color(0xFFFF453A);
      case 'offer_sent':    return const Color(0xFFFF9500);
      case 'technical_round':
      case 'hr_round':      return const Color(0xFFA55EEA);
      default:              return const Color(0xFF636366);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'hired':         return const Color(0xFFEAF9EB);
      case 'rejected':      return const Color(0xFFFFEAEA);
      case 'offer_sent':    return const Color(0xFFFFF3E0);
      case 'technical_round':
      case 'hr_round':      return const Color(0xFFF5E6FF);
      default:              return const Color(0xFFF2F2F7);
    }
  }

  String _statusLabel(String status) =>
      status.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ));

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            height: 24, width: 24,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
          ),
        ),
      );
    }

    if (state.errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFFE5E5EA)),
                const SizedBox(height: 12),
                const Text('Something went wrong', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(state.errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () => ref.read(dashboardControllerProvider.notifier).fetchDashboardPayload(),
                  child: const Text('Try Again'),
                )
              ],
            ),
          ),
        ),
      );
    }

    final profile    = state.dashboardData?['profile']             as Map<String, dynamic>? ?? {};
    final summary    = state.dashboardData?['applicationSummary']  as Map<String, dynamic>? ?? {};
    final recentApps = state.dashboardData?['recentApplications']  as List<dynamic>?        ?? [];
    final interviews = state.dashboardData?['upcomingInterviews']  as List<dynamic>?        ?? [];
    final offers     = state.dashboardData?['pendingOffers']       as List<dynamic>?        ?? [];
    final resume     = state.dashboardData?['resume']              as Map<String, dynamic>? ?? {};
    final insights   = state.dashboardData?['insights']            as Map<String, dynamic>? ?? {};

    final String firstName = (profile['fullName'] ?? 'there').toString().split(' ').first;

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
            Text('Hi, $firstName',
                style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
            const SizedBox(height: 2),
            const Text("Here's your job search summary.",
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w500)),
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

            if (_activeView == 'overview') ...[
              _buildProfileCompletion(profile),
              const SizedBox(height: 16),
              _buildStatsGrid(summary, resume),
              if (offers.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildOffersSection(offers),
              ],
              const SizedBox(height: 20),
              _buildSectionHeader('Upcoming Interviews', 'See All', () => setState(() => _activeView = 'interviews')),
              const SizedBox(height: 8),
              _buildInterviewsList(interviews),
              const SizedBox(height: 20),
              _buildSectionHeader('Recent Applications', 'See All', () => setState(() => _activeView = 'applied')),
              const SizedBox(height: 8),
              _buildApplicationsList(recentApps),
              const SizedBox(height: 20),
              _buildResumeAndSkillsCard(resume, profile),
              const SizedBox(height: 20),
              _buildThisMonthCard(summary),
            ] else if (_activeView == 'interviews') ...[
              _buildCountHeader('Interviews', interviews.length),
              const SizedBox(height: 8),
              _buildInterviewsList(interviews, expandedView: true),
            ] else if (_activeView == 'applied') ...[
              _buildCountHeader('Applications', recentApps.length),
              const SizedBox(height: 8),
              _buildApplicationsList(recentApps, expandedView: true),
            ] else ...[
              _buildInsightsView(insights, summary),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Tab Toggle ──────────────────────────────────────────────────────────────

  Widget _buildViewToggle() {
    final tabs = [
      ('Overview',    'overview'),
      ('Interviews',  'interviews'),
      ('Applied',     'applied'),
      ('Insights',    'insights'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final selected = _activeView == t.$2;
          return GestureDetector(
            onTap: () => setState(() => _activeView = t.$2),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.black : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t.$1,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF636366),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Profile Completion ──────────────────────────────────────────────────────

  Widget _buildProfileCompletion(Map<String, dynamic> profile) {
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
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile Completion', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('A complete profile helps employers find you.', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$score', style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold, height: 1)),
                  const Text('/100', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                ],
              ),
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
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF8E8E93)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(tips.first.toString(),
                      style: const TextStyle(color: Color(0xFF636366), fontSize: 11)),
                ),
                if (tips.length > 1)
                  Text('+${tips.length - 1} more',
                      style: const TextStyle(color: Color(0xFF007AFF), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Stats Grid ──────────────────────────────────────────────────────────────

  Widget _buildStatsGrid(Map<String, dynamic> summary, Map<String, dynamic> resume) {
    final atsScore = resume['atsScore'];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildStatTile(
          'Total Applications',
          '${summary['total'] ?? 0}',
          '${summary['active'] ?? 0} still in progress',
          Icons.business_center_outlined,
          const Color(0xFF007AFF),
        ),
        _buildStatTile(
          'Interviews',
          '${summary['inInterview'] ?? 0}',
          'Technical or HR rounds',
          Icons.video_camera_front_outlined,
          const Color(0xFFA55EEA),
        ),
        _buildStatTile(
          'Offers Received',
          '${summary['offerStage'] ?? 0}',
          summary['offerStage'] != null && summary['offerStage'] > 0
              ? 'Waiting for your response'
              : 'No pending offers',
          Icons.workspace_premium_outlined,
          const Color(0xFF34C759),
        ),
        _buildStatTile(
          'Resume Score',
          atsScore != null ? '$atsScore%' : 'N/A',
          resume['name'] ?? 'No resume uploaded',
          Icons.description_outlined,
          const Color(0xFFFF9500),
        ),
      ],
    );
  }

  Widget _buildStatTile(String title, String value, String sub, IconData icon, Color iconColor) {
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
              Expanded(child: Text(title, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w600))),
              Icon(icon, size: 16, color: iconColor.withOpacity(0.9)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(color: Color(0xFF636366), fontSize: 9, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Offers ──────────────────────────────────────────────────────────────────

  Widget _buildOffersSection(List<dynamic> offers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Offers Awaiting Your Response', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFEAF9EB), borderRadius: BorderRadius.circular(10)),
              child: Text('${offers.length}', style: const TextStyle(color: Color(0xFF34C759), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...offers.map((offer) => Container(
          margin: const EdgeInsets.only(bottom: 8),
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
                radius: 18,
                child: Icon(Icons.workspace_premium_rounded, color: Color(0xFF34C759), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer['position'] ?? 'Job Offer',
                        style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(offer['company']?['name'] ?? '',
                        style: const TextStyle(color: Color(0xFF636366), fontSize: 11)),
                    const SizedBox(height: 3),
                    Text('${offer['currency']} ${offer['salary']} / year',
                        style: const TextStyle(color: Color(0xFF34C759), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                child: const Text('Review', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  // ─── Interviews ──────────────────────────────────────────────────────────────

  Widget _buildInterviewsList(List<dynamic> interviews, {bool expandedView = false}) {
    if (interviews.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No interviews scheduled',
        subtitle: 'Your upcoming interviews will appear here.',
      );
    }

    final list = expandedView ? interviews : interviews.take(2).toList();

    return Column(
      children: list.map((i) {
        final status = (i['status'] ?? 'scheduled').toString().toLowerCase();
        Color statusColor;
        Color statusBg;
        if (status == 'confirmed') {
          statusColor = const Color(0xFF34C759); statusBg = const Color(0xFFEAF9EB);
        } else {
          statusColor = const Color(0xFF007AFF); statusBg = const Color(0xFFE5F1FF);
        }

        final format = (i['format'] ?? 'video').toString().toLowerCase();
        String formatLabel;
        if (format == 'video')        formatLabel = '🎥 Video';
        else if (format == 'coding_test') formatLabel = '💻 Coding';
        else                           formatLabel = format;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i['job'] ?? 'Interview',
                            style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(i['company']?['name'] ?? '',
                            style: const TextStyle(color: Color(0xFF636366), fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(6)),
                        child: Text(formatLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
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
                      const SizedBox(width: 5),
                      Text(_formatDateTime(i['scheduledTime'] ?? ''),
                          style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      Text('· ${i['durationMinutes']} min',
                          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(60, 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => debugPrint('Join: ${i['joinLink']}'),
                    child: const Text('Join', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Applications List ───────────────────────────────────────────────────────

  Widget _buildApplicationsList(List<dynamic> apps, {bool expandedView = false}) {
    if (apps.isEmpty) {
      return _buildEmptyState(
        icon: Icons.business_center_outlined,
        title: "You haven't applied yet",
        subtitle: 'Jobs you apply to will appear here.',
        actionLabel: 'Browse Jobs',
      );
    }

    final list = expandedView ? apps : apps.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
      ),
      child: Column(
        children: list.asMap().entries.map((entry) {
          final idx = entry.key;
          final app = entry.value;
          final status = (app['status'] ?? 'applied').toString().toLowerCase();
          final jobId  = app['job']?['jobId']?.toString() ?? '';
          final isLast = idx == list.length - 1;

          return InkWell(
            borderRadius: BorderRadius.vertical(
              top: idx == 0 ? const Radius.circular(14) : Radius.zero,
              bottom: isLast ? const Radius.circular(14) : Radius.zero,
            ),
            onTap: () {
              if (jobId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job details not available.')));
                return;
              }
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withOpacity(0.5),
                builder: (_) => JobDetailPopup(jobId: jobId),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF2F2F7))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(9)),
                    child: Center(
                      child: Text(
                        (app['company']?['name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app['job']?['title'] ?? 'Job',
                            style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis)),
                        const SizedBox(height: 1),
                        Text(
                          [app['company']?['name'], app['job']?['location']].where((v) => v != null && v.toString().isNotEmpty).join(' · '),
                          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(5)),
                    child: Text(_statusLabel(status),
                        style: TextStyle(color: _statusColor(status), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFE5E5EA)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Resume & Skills Card ────────────────────────────────────────────────────

  Widget _buildResumeAndSkillsCard(Map<String, dynamic> resume, Map<String, dynamic> profile) {
    final skills   = profile['skills'] as List<dynamic>? ?? [];
    final atsScore = resume['atsScore'] as int?;

    String atsHint = '';
    Color  atsBarColor = Colors.black;
    if (atsScore != null) {
      if (atsScore >= 75)      { atsHint = 'Well optimised'; atsBarColor = const Color(0xFF34C759); }
      else if (atsScore >= 50) { atsHint = 'Could be improved'; atsBarColor = const Color(0xFFFF9500); }
      else                     { atsHint = 'Needs improvement'; atsBarColor = const Color(0xFFFF453A); }
    }

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
            children: [
              const Text('My Resume', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
              if (resume.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFEAF9EB), borderRadius: BorderRadius.circular(5)),
                  child: const Text('Uploaded', style: TextStyle(color: Color(0xFF34C759), fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFFEAEA), borderRadius: BorderRadius.circular(5)),
                  child: const Text('Missing', style: TextStyle(color: Color(0xFFFF453A), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (resume.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 16, color: Color(0xFF8E8E93)),
                const SizedBox(width: 6),
                Expanded(child: Text(resume['name'] ?? '',
                    style: const TextStyle(color: Color(0xFF636366), fontSize: 12, fontWeight: FontWeight.w500))),
                Text('${resume['totalResumes'] ?? 1} file${(resume['totalResumes'] ?? 1) > 1 ? 's' : ''}',
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
              ],
            ),

            if (atsScore != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E5EA))),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ATS Compatibility Score', style: TextStyle(color: Color(0xFF636366), fontSize: 11)),
                        Text('$atsScore%', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: atsScore / 100,
                      backgroundColor: const Color(0xFFE5E5EA),
                      valueColor: AlwaysStoppedAnimation<Color>(atsBarColor),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(atsHint, style: TextStyle(color: atsBarColor, fontSize: 10, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            const Text('Upload a resume so employers can find you.',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: const Text('Upload Resume →', style: TextStyle(color: Color(0xFF007AFF), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],

          if (skills.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE5E5EA), height: 1),
            const SizedBox(height: 14),
            const Text('My Skills', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: skills.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Text(s.toString(), style: const TextStyle(color: Color(0xFF636366), fontSize: 11)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Placeholder/Dummy Stubs to ensure valid Widget compilation ────────────

  Widget _buildSectionHeader(String title, String actionText, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
        GestureDetector(
          onTap: onTap,
          child: Text(actionText, style: const TextStyle(color: Color(0xFF007AFF), fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildCountHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$title ($count)', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildThisMonthCard(Map<String, dynamic> summary) => const SizedBox.shrink();
  Widget _buildInsightsView(Map<String, dynamic> insights, Map<String, dynamic> summary) => const SizedBox.shrink();

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle, String? actionLabel}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8)),
      child: Column(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF8E8E93)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
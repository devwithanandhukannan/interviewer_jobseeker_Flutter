import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/company/presentation/screen/companyProfile_screen.dart';
import 'package:interviewer/features/dashboard/presentation/controller/job_controller.dart';
import './applyJob_screen.dart';
import './viewApplicationStatus_screen.dart';

class JobDetailPopup extends ConsumerWidget {
  final String jobId;
  const JobDetailPopup({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(jobDetailDataProvider(jobId));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 25, spreadRadius: 1),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: detailState.when(
                    loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                    error: (err, stack) => Center(
                      child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                    ),
                    data: (data) {
                      if (data == null) return const Center(child: Text('No details found.'));

                      final jobData = data is Map<String, dynamic> && data.containsKey('data')
                          ? data['data']
                          : data;

                      final company = jobData['company'] ?? {};
                      final List<dynamic> skills = jobData['requiredSkills'] ?? [];

                      return Stack(
                        children: [
                          ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                            child: ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                              physics: const ClampingScrollPhysics(),
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            jobData['title']?.toString() ?? 'Job Title',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A1A1A),
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                company['name']?.toString() ?? 'Company',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue.shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (company['verificationBadge'] == 'verified')
                                                Icon(Icons.verified, size: 16, color: Colors.blue.shade600),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildCompanyLogo(context, company['logoUrl'], jobData['companyId']?.toString() ?? ''),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildQuickFactsGrid(jobData),
                                const SizedBox(height: 24),
                                if (skills.isNotEmpty) ...[
                                  const Text('Required Skills',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: skills.map((skill) => _buildTechChip(skill.toString())).toList(),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                const SizedBox(height: 24),
                                const Text('Job Description',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                                const SizedBox(height: 12),
                                _buildCleanDescription(jobData['description']?.toString() ?? ''),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildStickyActionBar(context, ref, jobData, jobId),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyLogo(BuildContext context, String? logoUrl, String companyId) {
    Widget logoWidget;

    if (logoUrl == null || !logoUrl.contains('base64,')) {
      logoWidget = Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.business, color: Colors.grey),
      );
    } else {
      try {
        final base64String = logoUrl.split('base64,')[1].trim();
        final imageBytes = base64Decode(base64String);
        logoWidget = Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(6),
          child: Image.memory(imageBytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey)),
        );
      } catch (e) {
        logoWidget = const Icon(Icons.broken_image, color: Colors.grey);
      }
    }

    return GestureDetector(
      onTap: () {
        if (companyId.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CompanyProfileScreen(companyId: companyId)));
        }
      },
      child: logoWidget,
    );
  }

  Widget _buildCleanDescription(String rawDescription) {
    if (rawDescription.isEmpty) return const Text('No description available.');
    final cleanText = rawDescription.replaceAll('###', '').replaceAll('**', '').replaceAll('* ', '• ');
    return Text(cleanText, style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.6));
  }

  Widget _buildQuickFactsGrid(Map<String, dynamic> jobData) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildFactCard(Icons.work_outline, 'Job Type', jobData['jobType'] ?? 'N/A'),
        _buildFactCard(Icons.location_on_outlined, 'Location',
            '${jobData['location'] ?? 'N/A'} (${jobData['locationType'] ?? 'N/A'})'),
        _buildFactCard(Icons.payments_outlined, 'Salary Range', jobData['salaryRange'] ?? 'N/A'),
        _buildFactCard(Icons.stars_outlined, 'Experience', jobData['experienceRequired'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildFactCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.08),
            radius: 18,
            child: Icon(icon, size: 18, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(8)),
      child: Text(label.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A5568))),
    );
  }

  // ── Added ref parameter so we can invalidate providers after apply ──
  Widget _buildStickyActionBar(BuildContext context, WidgetRef ref, Map<String, dynamic> jobData, String currentJobId) {
    final applicationCount = jobData['_count']?['applications'] ?? 0;
    final String? rawStatus =
        jobData['appliedStatus']?.toString() ?? jobData['applicationStatus']?.toString();
    final bool hasApplied =
        rawStatus != null && rawStatus != 'false' && rawStatus.trim().isNotEmpty && rawStatus != 'null';

    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final double calculatedBottomPadding = systemBottomPadding > 0 ? systemBottomPadding + 10 : 24.0;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, calculatedBottomPadding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06), width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eighteen_mp, size: 14, color: Color(0xFF4A5568)),
                        const SizedBox(width: 4),
                        Text(
                          '${jobData['openings'] ?? 1} Openings',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2D3748)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$applicationCount applicants',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: hasApplied
                        ? null
                        : [
                      BoxShadow(
                        color: Colors.blue.shade700.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (hasApplied) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewapplicationstatusScreen(applicationID: rawStatus),
                          ),
                        );
                      } else {
                        // Await result — true means successfully applied
                        final bool? didApply = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplyjobScreen(jobId: currentJobId),
                          ),
                        );

                        // If applied successfully, close this popup too so list refreshes visibly
                        if (didApply == true && context.mounted) {
                          Navigator.pop(context, true); // propagate success upward
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: hasApplied
                            ? LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade200])
                            : LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          hasApplied ? 'View Application' : 'Apply Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: hasApplied ? Colors.black87 : Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
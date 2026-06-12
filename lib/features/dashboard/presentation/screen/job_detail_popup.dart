import 'dart:convert'; // Required for base64 decoding
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

    // Using DraggableScrollableSheet so users can drag it up/down naturally
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
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grab Handle Indicator
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
                      if (data == null) {
                        return const Center(child: Text('No details found.'));
                      }

                      final jobData = data is Map<String, dynamic> && data.containsKey('data')
                          ? data['data']
                          : data;

                      final company = jobData['company'] ?? {};
                      final List<dynamic> skills = jobData['requiredSkills'] ?? [];

                      return Stack(
                        children: [
                          // ScrollConfiguration fixes standard scroll physics issues inside popups
                          ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                            child: ListView(
                              controller: scrollController, // Vital for linking drag gesture to sheet
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                              physics: const ClampingScrollPhysics(),
                              children: [
                                // Header Row: Title & Image Logo
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
                                    _buildCompanyLogo(context ,company['logoUrl'],jobData['companyId']),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Data Grid Layout
                                _buildQuickFactsGrid(jobData),
                                const SizedBox(height: 24),

                                // Required Skills Section
                                if (skills.isNotEmpty) ...[
                                  const Text(
                                    'Required Skills',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                                  ),
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

                                // Body Markdown Description Content
                                const Text(
                                  'Job Description',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                                ),
                                const SizedBox(height: 12),
                                _buildCleanDescription(jobData['description']?.toString() ?? ''),
                              ],
                            ),
                          ),

                          // Sticky Bottom Footer Call to Action (Passed context and jobId here)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildStickyActionBar(context, jobData, jobId),
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

  Widget _buildCompanyLogo(BuildContext context,String? logoUrl, String companyId) {
    Widget logoWidget;

    if (logoUrl == null || !logoUrl.contains('base64,')) {
      logoWidget = Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(6),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      } catch (e) {
        logoWidget = const Icon(Icons.broken_image, color: Colors.grey);
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_)=> CompanyProfileScreen(companyId: companyId))
        );
      },
      child: logoWidget,
    );
  }

  Widget _buildCleanDescription(String rawDescription) {
    if (rawDescription.isEmpty) return const Text('No description available.');

    final cleanText = rawDescription
        .replaceAll('###', '')
        .replaceAll('**', '')
        .replaceAll('* ', '• ');

    return Text(
      cleanText,
      style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.6),
    );
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
        _buildFactCard(Icons.location_on_outlined, 'Location', '${jobData['location']} (${jobData['locationType']})'),
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
        borderRadius: BorderRadius.circular(12),
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
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                  overflow: TextOverflow.ellipsis,
                ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A5568)),
      ),
    );
  }

  Widget _buildStickyActionBar(BuildContext context, Map<String, dynamic> jobData, String currentJobId) {
    final applicationCount = jobData['_count']?['applications'] ?? 0;

    final String? rawStatus = jobData['appliedStatus']?.toString() ?? jobData['applicationStatus']?.toString();
    final bool hasApplied = rawStatus != null && rawStatus != 'false' && rawStatus.trim().isNotEmpty && rawStatus != 'null';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${jobData['openings'] ?? 1} Openings',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
              ),
              const SizedBox(height: 2),
              Text(
                '$applicationCount applied',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (hasApplied) {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> ViewapplicationstatusScreen(applicationID: rawStatus)));
                } else {
                  // Navigates unapplied sessions out to candidate request forms
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApplyjobScreen(jobId: currentJobId),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: hasApplied ? Colors.grey.shade200 : Colors.blue.shade700,
                foregroundColor: hasApplied ? Colors.black87 : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                hasApplied ? 'View Application Details' : 'Apply Now',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
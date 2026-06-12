import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/interview/presentation/controller/viewApplication_controller.dart';

class ViewapplicationScreen extends ConsumerStatefulWidget {
  const ViewapplicationScreen({super.key});

  @override
  ConsumerState<ViewapplicationScreen> createState() {
    return _ViewApplicationState();
  }
}

class _ViewApplicationState extends ConsumerState<ViewapplicationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ApplicationsControllerProvider.notifier).fetchData();
    });
  }

  // Pure Dart runtime ISO 8601 string-to-date formatter
  String _formatIsoDate(String rawIso) {
    if (rawIso.isEmpty) return '';
    try {
      final parsed = DateTime.parse(rawIso).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
    } catch (_) {
      return rawIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ApplicationsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Applications",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: '.SF Pro Display',
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.withOpacity(0.15),
            height: 0.5,
          ),
        ),
      ),
      body: state.applicationData.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2.5,
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: Color(0xFF3A3A3C)),
          ),
        ),
        data: (response) {
          // Safeguard map response fields
          final List applications = (response['data'] as List?) ?? [];

          if (applications.isEmpty) {
            return Center(
              child: Text(
                "No applications found",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];

              // Safe-extract nested structures
              final jobDetails = app['jobDetails'] ?? {};
              final companyDetails = app['companyDetails'] ?? {};
              final resumeUsed = app['resumeUsed'] ?? {};

              final title = jobDetails['title'] ?? 'Position';
              final companyName = companyDetails['name'] ?? 'Company';
              final department = jobDetails['department'] ?? '';
              final location = jobDetails['location'] ?? '';
              final jobType = jobDetails['jobType'] ?? '';
              final compensation = jobDetails['compensationContext'] ?? '';
              final appliedDate = app['appliedAt'] ?? '';
              final liveStatus = (app['liveStatusBadge'] ?? 'applied').toString().toLowerCase();

              // Setup Apple UI Status Colors
              Color statusColor = const Color(0xFF007AFF); // iOS Blue Default
              Color statusBg = const Color(0xFFEEF7FF);

              if (liveStatus == 'offer_sent') {
                statusColor = const Color(0xFF34C759); // iOS System Green
                statusBg = const Color(0xFFEAF9EB);
              } else if (liveStatus == 'rejected' || app['isWithdrawn'] == true) {
                statusColor = const Color(0xFFFF3B30); // iOS System Red
                statusBg = const Color(0xFFFFEBEA);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE5E5EA),
                    width: 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line 1: Company + Badge Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            companyName.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              liveStatus.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Line 2: Job Title
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Line 3: Meta details (Location • Department)
                      Text(
                        "$department  •  $location ($jobType)",
                        style: const TextStyle(
                          color: Color(0xFF636366),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Color(0xFFE5E5EA), height: 1, thickness: 0.6),
                      ),

                      // Application Metrics block
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "COMPENSATION",
                                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 9, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                compensation.isNotEmpty ? compensation : "N/A",
                                style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "APPLIED ON",
                                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 9, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatIsoDate(appliedDate),
                                style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Attached Resume Element
                      if (resumeUsed['name'] != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7), // Light secondary surface fill
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined, size: 16, color: Color(0xFF636366)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  resumeUsed['name'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF2C2C2E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
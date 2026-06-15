import 'package:flutter/cupertino.dart';
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
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    await ref.read(ApplicationsControllerProvider.notifier).fetchData();
  }

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

  // Method to invoke async backend Groq metrics engine and display system sheet
  // Method to invoke async backend Groq metrics engine and display system sheet
  Future<void> _handleSalaryCompare({
    required String title,
    required String location,
    required String compensation,
  }) async {
    // 1. Instantly display standard loader context overlay
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CupertinoActivityIndicator(radius: 12)),
    );

    try {
      final result = await ref.read(ApplicationsControllerProvider.notifier).fetchSalaryComparison(
        title: title,
        location: location,
        offeredSalary: compensation,
        experience: '1-3 Years', // Fallback context baseline
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loader context cleanly

        final data = result['data'] ?? {};

        // 2. Open an elegant system dialog mapping runtime analysis data structures
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                // Give the dialog a fixed maximum height constraint so scrolling works perfectly
                height: MediaQuery.of(context).size.height * 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Market Insights',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$title • $location',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFE5E5EA), height: 1),
                    ),

                    // Fixed scroll wrapper with correct physics casing
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          data.toString().replaceAll('{', '').replaceAll('}', '').split(',').join('\n\n'),
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 13,
                            height: 1.4,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFE5E5EA), height: 1),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading context safely
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not aggregate metrics details: $e')),
        );
      }
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
      body: RefreshIndicator(
        color: Colors.black,
        backgroundColor: Colors.white,
        onRefresh: _refreshData,
        child: state.applicationData.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
          ),
          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.35),
              Center(child: Text(error.toString(), style: const TextStyle(color: Color(0xFF3A3A3C)))),
            ],
          ),
          data: (response) {
            final List applications = (response['data'] as List?) ?? [];

            if (applications.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  Center(child: Text("No applications found", style: TextStyle(color: Colors.grey.shade500, fontSize: 15))),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final app = applications[index];

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

                Color statusColor = const Color(0xFF007AFF);
                Color statusBg = const Color(0xFFEEF7FF);

                if (liveStatus == 'offer_sent') {
                  statusColor = const Color(0xFF34C759);
                  statusBg = const Color(0xFFEAF9EB);
                } else if (liveStatus == 'rejected' || app['isWithdrawn'] == true) {
                  statusColor = const Color(0xFFFF3B30);
                  statusBg = const Color(0xFFFFEBEA);
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
                        Text(
                          title,
                          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$department  •  $location ($jobType)",
                          style: const TextStyle(color: Color(0xFF636366), fontSize: 13, fontWeight: FontWeight.w400),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0xFFE5E5EA), height: 1, thickness: 0.6),
                        ),
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
                        if (resumeUsed['name'] != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
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
                                    style: const TextStyle(color: Color(0xFF2C2C2E), fontSize: 12, fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // NEW: Actions row containing the Market/Salary insights workflow hook
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Divider(color: Color(0xFFE5E5EA), height: 1, thickness: 0.6),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.analytics_outlined, size: 16),
                                label: const Text(
                                  'Compare Salary',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                                ),
                                onPressed: () => _handleSalaryCompare(
                                  title: title,
                                  location: location,
                                  compensation: compensation,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
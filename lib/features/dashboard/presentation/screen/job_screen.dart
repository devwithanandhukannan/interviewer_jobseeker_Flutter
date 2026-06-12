import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:interviewer/features/dashboard/presentation/screen/job_detail_popup.dart';
import 'package:interviewer/features/dashboard/presentation/controller/job_controller.dart'; // Ensure this matches your file setup

class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;

  // Minimalist Premium Brand Color Palette
  static const _bg = Color(0xFFFAFAFA);
  static const _surface = Colors.white;
  static const _surfaceAlt = Color(0xFFF5F5F7);
  static const _border = Color(0xFFE5E5EA);
  static const _accent = Color(0xFF000000);
  static const _textPrimary = Color(0xFF000000);
  static const _textSecondary = Color(0xFF6E6E73);
  static const _textMuted = Color(0xFF86868B);
  static const _successDim = Color(0xFFE1F5FE);
  static const _successText = Color(0xFF0288D1);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(jobControllerProvider.notifier).fetchJobs(refresh: false);
    }
  }

  void _onSearchChanged(String text) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(jobControllerProvider.notifier).updateSearchKeyword(text.trim());
    });
  }

  /// Helper to safely determine application tracking logs status
  bool _isJobApplied(dynamic job) {
    if (job == null) return false;

    // Check local field patterns standard on nested API models
    if (job['isApplied'] == true || job['hasApplied'] == true) {
      return true;
    }

    // Handle checking tracking relational mappings if available
    if (job['applications'] != null && (job['applications'] as List).isNotEmpty) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(jobControllerProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Explore Jobs',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.5),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            color: _surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border, width: 0.5),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 15, color: _textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Search title, skills, or company...',
                        hintStyle: TextStyle(fontSize: 14, color: _textMuted),
                        prefixIcon: Icon(Icons.search, size: 18, color: _textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showFilterBottomSheet(context, jobState),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: jobState.selectedFilters.isNotEmpty ? _accent : _surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border, width: 0.5),
                    ),
                    child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: jobState.selectedFilters.isNotEmpty ? Colors.white : _textPrimary
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildActiveFilterChips(jobState),
          Expanded(
            child: jobState.jobListState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
              error: (err, _) => _buildErrorWidget(err),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return _buildEmptyStateWidget();
                }
                return RefreshIndicator(
                  color: _accent,
                  onRefresh: () => ref.read(jobControllerProvider.notifier).fetchJobs(refresh: true),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length + (jobState.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == jobs.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
                        );
                      }
                      return _buildJobCard(jobs[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(JobState state) {
    if (state.selectedFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 46,
      width: double.infinity,
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...state.selectedFilters.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border, width: 0.5),
              ),
              child: Row(
                children: [
                  Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => ref.read(jobControllerProvider.notifier).updateFilter(entry.key, ''),
                    child: const Icon(Icons.close, size: 14, color: _textMuted),
                  )
                ],
              ),
            );
          }),
          TextButton(
            onPressed: () => ref.read(jobControllerProvider.notifier).clearAllFilters(),
            child: const Text('Clear All', style: TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  Widget _buildJobCard(dynamic job) {
    final applied = _isJobApplied(job);

    final title = job['title']?.toString() ?? 'Job Title';
    final company = job['company'] != null ? job['company']['name']?.toString() ?? 'Company' : 'Company';
    final location = job['location']?.toString() ?? 'Remote';
    final jobType = job['jobType']?.toString() ?? 'Full-Time';
    final workLocation = job['workLocationPreference']?.toString() ?? job['workLocation']?.toString() ?? 'Remote';
    final experience = job['experience']?.toString() ?? job['experienceLevel']?.toString() ?? 'Entry Level';
    final salary = job['expectedSalary']?.toString() ?? job['salary']?.toString() ?? 'Competitive';
    final category = job['category']?.toString() ?? job['industry']?.toString() ?? '';

    // Handle structural skill array mappings gracefully
    List<String> skills = [];
    if (job['skillsNeeded'] != null) {
      if (job['skillsNeeded'] is List) {
        skills = List<String>.from(job['skillsNeeded'].map((e) => e.toString()));
      } else if (job['skillsNeeded'] is String) {
        skills = job['skillsNeeded'].toString().split(',').map((e) => e.trim()).toList();
      }
    } else if (job['skills'] != null && job['skills'] is List) {
      skills = List<String>.from(job['skills'].map((e) => e.toString()));
    }

    return Opacity(
      opacity: applied ? 0.55 : 1.0, // DIMMED LIGHT EFFECT FOR APPLIED CARDS
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => JobDetailPopup(jobId: job['id'].toString()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Title, Company & Applied Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Text(company, style: const TextStyle(fontSize: 14, color: _textSecondary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (applied)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _successDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Applied',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _successText),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(8)),
                      child: Text(salary, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary)),
                    )
                ],
              ),
              const SizedBox(height: 12),

              // Detailed operational metric information row
              // Detailed operational metric information row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Fixed parameter here
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: _textMuted),
                  const SizedBox(width: 4),
                  Text(location, style: const TextStyle(fontSize: 13, color: _textSecondary)),
                  const SizedBox(width: 14),
                  const Icon(Icons.work_outline_rounded, size: 14, color: _textMuted),
                  const SizedBox(width: 4),
                  Text('$jobType ($workLocation)', style: const TextStyle(fontSize: 13, color: _textSecondary)),
                ],
              ),
              const SizedBox(height: 12),

              // Badges for structural classification (Experience & Category)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(6)),
                    child: Text('Exp: $experience', style: const TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w500)),
                  ),
                  if (category.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(6)),
                      child: Text(category, style: const TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w500)),
                    ),
                  ]
                ],
              ),

              // Skills Array UI representation mapping
              if (skills.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(height: 0.5, color: _border),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills.take(4).map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _border, width: 0.5),
                    ),
                    child: Text(
                        skill,
                        style: const TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w500)
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, JobState jobState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 16),
                    const Text('Filter Openings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
                    const SizedBox(height: 20),

                    _buildModalDropdown(
                      label: 'Job Arrangement Type',
                      currentValue: jobState.selectedFilters['jobType'] ?? '',
                      options: {'': 'All Types', 'full-time': 'Full-Time', 'part-time': 'Part-Time', 'contract': 'Contract', 'internship': 'Internship'},
                      onChanged: (val) {
                        ref.read(jobControllerProvider.notifier).updateFilter('jobType', val!);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildModalDropdown(
                      label: 'Work Location Setup',
                      currentValue: jobState.selectedFilters['workLocationPreference'] ?? '',
                      options: {'': 'Any Mode', 'remote': 'Remote', 'onsite': 'On-Site', 'hybrid': 'Hybrid'},
                      onChanged: (val) {
                        ref.read(jobControllerProvider.notifier).updateFilter('workLocationPreference', val!);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(backgroundColor: _surfaceAlt, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () {
                              ref.read(jobControllerProvider.notifier).clearAllFilters();
                              Navigator.pop(context);
                            },
                            child: const Text('Reset All', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)),
                          ),
                        ),
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

  Widget _buildModalDropdown({required String label, required String currentValue, required Map<String, String> options, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border, width: 0.5)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.containsKey(currentValue) ? currentValue : options.keys.first,
              isExpanded: true,
              dropdownColor: _surface,
              style: const TextStyle(fontSize: 14, color: _textPrimary),
              items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: onChanged,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildEmptyStateWidget() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: _textMuted),
          const SizedBox(height: 16),
          const Text('No jobs found matching criteria', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
          const SizedBox(height: 6),
          const Text('Try loosening your filter parameters or search vocabulary spelling words.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            onPressed: () => ref.read(jobControllerProvider.notifier).clearAllFilters(),
            child: const Text('Reset Search Filters'),
          )
        ],
      ),
    ),
  );

  Widget _buildErrorWidget(Object error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: _textMuted),
          const SizedBox(height: 16),
          const Text('Failed to load listings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            onPressed: () => ref.read(jobControllerProvider.notifier).fetchJobs(refresh: true),
            child: const Text('Try Again'),
          )
        ],
      ),
    ),
  );
}
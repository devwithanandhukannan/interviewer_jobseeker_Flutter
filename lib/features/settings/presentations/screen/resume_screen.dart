import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/settings/presentations/controller/resume_controller.dart';
import 'package:intl/intl.dart';

class ResumeListScreen extends ConsumerWidget {
  const ResumeListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeState = ref.watch(resumeControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Resumes',
          style: TextStyle(fontWeight: FontWeight.bold), // Fixed: Ensured color compatibility
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => ref.read(resumeControllerProvider.notifier).fetchResumes(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (resumeState.isLoading && resumeState.resumes.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (resumeState.listError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      resumeState.listError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(resumeControllerProvider.notifier).fetchResumes(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (resumeState.resumes.isEmpty) {
            return const Center(
              child: Text(
                'No resumes uploaded yet.',
                style: TextStyle(color: Colors.black45, fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(resumeControllerProvider.notifier).fetchResumes(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: resumeState.resumes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final resume = resumeState.resumes[index];
                return ResumeCard(
                  resume: resume,
                  onTap: () {
                    if (resume['id'] != null) {
                      ref.read(resumeControllerProvider.notifier).fetchResumeById(resume['id'].toString());
                    }
                  },
                  onDelete: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final success = await ref
                        .read(resumeControllerProvider.notifier)
                        .deleteResumeRecord(resume['id'].toString());

                    if (success) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Resume deleted successfully')),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ResumeCard extends StatelessWidget {
  final dynamic resume;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ResumeCard({
    Key? key,
    required this.resume,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  Color _getAtsColor(int score) {
    if (score >= 70) return const Color(0xFF2E7D32);
    if (score >= 40) return const Color(0xFFEF6C00);
    return const Color(0xFFC62828);
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int atsScore = resume['atsScore'] ?? 0;
    final bool isPrimary = resume['isPrimary'] ?? false;
    final String formattedDate = _formatDate(resume['createdAt']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              key: ValueKey(resume['id']),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description, color: Color(0xFF495057)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resume['name'] ?? 'Untitled Resume',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF212529),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Uploaded on $formattedDate',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF868E96),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.black45),
                        iconSize: 22, // Fixed: Named parameter changed from 'size' to 'iconSize'
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Resume'),
                              content: const Text('Are you sure you want to delete this resume?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onDelete();
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(height: 1, color: Color(0xFFE9ECEF)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Fixed: 'between' to 'spaceBetween'
                    children: [
                      Row(
                        children: [
                          if (isPrimary) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7F5FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Primary',
                                style: TextStyle(
                                  color: Color(0xFF228BE6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFE9ECEF)),
                            ),
                            child: Text(
                              (resume['source'] ?? 'uploaded').toString().toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF495057),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'ATS Score:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF495057),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getAtsColor(atsScore).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$atsScore%',
                              style: TextStyle(
                                color: _getAtsColor(atsScore),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
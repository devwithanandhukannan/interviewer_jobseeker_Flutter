import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/settings/presentations/controller/resume_controller.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart'; // Changed to file_selector

class ResumeListScreen extends ConsumerWidget {
  const ResumeListScreen({Key? key}) : super(key: key);

  // Method to handle pick action using file_selector package
  Future<void> _handleUpload(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Define explicit extensions allowed by the system
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Resumes',
        extensions: <String>['pdf', 'doc', 'docx'],
      );

      // 2. Open the file selection panel natively
      final XFile? fileResult = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (fileResult == null) {
        // User cancelled selection
        return;
      }

      final File file = File(fileResult.path);
      final String systemFileName = fileResult.name;

      // 3. Open minimal dialog to capture metadata configurations
      if (!context.mounted) return;
      final Map<String, String>? metaDetails = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _UploadMetaDataDialog(initialName: systemFileName.split('.').first),
      );

      if (metaDetails == null) return;

      // 4. Dispatch the payload parameters directly to your controller
      final bool success = await ref.read(resumeControllerProvider.notifier).uploadResumeFile(
        file: file,
        name: metaDetails['name'] ?? 'Untitled Resume',
        jobDescription: metaDetails['jd'] ?? '',
      );

      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Resume uploaded successfully!')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error choosing file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeState = ref.watch(resumeControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Resumes',
          style: TextStyle(fontWeight: FontWeight.bold),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: resumeState.isLoading ? null : () => _handleUpload(context, ref),
        backgroundColor: resumeState.isLoading ? Colors.grey : const Color(0xFF007AFF),
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text('Upload Resume', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => ref.read(resumeControllerProvider.notifier).fetchResumes(),
                child: ListView.separated(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
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
              ),
              if (resumeState.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(backgroundColor: Colors.transparent),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _UploadMetaDataDialog extends StatefulWidget {
  final String initialName;
  const _UploadMetaDataDialog({required this.initialName});

  @override
  State<_UploadMetaDataDialog> createState() => _UploadMetaDataDialogState();
}

class _UploadMetaDataDialogState extends State<_UploadMetaDataDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final TextEditingController _jdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Resume Context Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Label Name *',
                  hintText: 'e.g., Senior Software Developer',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please define an alias' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jdController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Target Job Description (Optional)',
                  hintText: 'Paste requirements to check ATS and optimize...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'jd': _jdController.text,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF)),
          child: const Text('Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
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
                        iconSize: 22,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
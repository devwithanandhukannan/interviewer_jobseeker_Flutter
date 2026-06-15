import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:interviewer/features/dashboard/presentation/controller/job_controller.dart';

// Scoped UI state controllers
final _selectedResumeIdProvider = StateProvider.autoDispose<String?>((ref) => null);
final _localResumePathProvider = StateProvider.autoDispose<String?>((ref) => null);
final _localResumeNameProvider = StateProvider.autoDispose<String?>((ref) => null);
final _isSubmittingProvider = StateProvider.autoDispose<bool>((ref) => false);
final _applicationTypeProvider = StateProvider.autoDispose<String>((ref) => 'existing');

class ApplyjobScreen extends ConsumerWidget {
  final String jobId;
  const ApplyjobScreen({super.key, required this.jobId});

  static const _bg = Color(0xFFFAFAFA);
  static const _surface = Colors.white;
  static const _surfaceAlt = Color(0xFFF5F5F7);
  static const _border = Color(0xFFE5E5EA);
  static const _accent = Color(0xFF000000);
  static const _textPrimary = Color(0xFF000000);
  static const _textSecondary = Color(0xFF6E6E73);
  static const _textMuted = Color(0xFF86868B);
  static const _accentDim = Color(0xFFF5F5F7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeState = ref.watch(jobResumeProvider);
    final selectedResumeId = ref.watch(_selectedResumeIdProvider);
    final localResumePath = ref.watch(_localResumePathProvider);
    final localResumeName = ref.watch(_localResumeNameProvider);
    final isSubmitting = ref.watch(_isSubmittingProvider);
    final applicationType = ref.watch(_applicationTypeProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Submit Application',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.3),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: _surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border, width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(_applicationTypeProvider.notifier).state = 'existing',
                      child: Container(
                        decoration: BoxDecoration(
                          color: applicationType == 'existing' ? _surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: applicationType == 'existing'
                              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Saved Resume',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: applicationType == 'existing' ? FontWeight.w600 : FontWeight.w500,
                            color: applicationType == 'existing' ? _textPrimary : _textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(_applicationTypeProvider.notifier).state = 'upload',
                      child: Container(
                        decoration: BoxDecoration(
                          color: applicationType == 'upload' ? _surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: applicationType == 'upload'
                              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Upload New',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: applicationType == 'upload' ? FontWeight.w600 : FontWeight.w500,
                            color: applicationType == 'upload' ? _textPrimary : _textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: applicationType == 'existing'
                ? resumeState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: _textSecondary))),
              data: (data) {
                final List<dynamic> resumesList = data['data'] ?? [];
                if (resumesList.isEmpty) return _buildEmptyResumesState(ref);

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: resumesList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final resume = resumesList[index];
                    final String resumeId = resume['id']?.toString() ?? '';
                    final String resumeName = resume['name'] ?? 'Unnamed Resume';
                    final String atsScore = resume['atsScore']?.toString() ?? '--';
                    final bool isSelected = selectedResumeId == resumeId;

                    return GestureDetector(
                      onTap: () => ref.read(_selectedResumeIdProvider.notifier).state = resumeId,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _accent : _border,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, color: isSelected ? _accent : _textSecondary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(resumeName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 3),
                                  Text('ATS Score: $atsScore%', style: const TextStyle(fontSize: 12, color: _textMuted)),
                                ],
                              ),
                            ),
                            Radio<String>(
                              value: resumeId,
                              groupValue: selectedResumeId,
                              activeColor: _accent,
                              onChanged: (value) => ref.read(_selectedResumeIdProvider.notifier).state = value,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border, width: 0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(color: _surfaceAlt, shape: BoxShape.circle),
                      child: const Icon(Icons.cloud_upload_outlined, size: 28, color: _textPrimary),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select your document attachment',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
                    const SizedBox(height: 6),
                    const Text('Supports PDF, DOCX formats (Max 5MB)',
                        style: TextStyle(fontSize: 12, color: _textMuted)),
                    const SizedBox(height: 24),
                    if (localResumePath != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _border, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(localResumeName ?? 'Selected Document',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            GestureDetector(
                              onTap: () {
                                ref.read(_localResumePathProvider.notifier).state = null;
                                ref.read(_localResumeNameProvider.notifier).state = null;
                              },
                              child: const Icon(Icons.cancel_rounded, size: 16, color: _textMuted),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentDim,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: _border, width: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => _pickLocalFile(ref),
                      child: Text(
                        localResumePath == null ? 'Browse File' : 'Change File',
                        style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: _surface,
              border: Border(top: BorderSide(color: _border, width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isButtonDisabled(applicationType, selectedResumeId, localResumePath) || isSubmitting)
                      ? null
                      : () => _handleSubmission(context, ref, applicationType, selectedResumeId, localResumePath),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _border,
                    disabledForegroundColor: _textMuted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Submit Application', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isButtonDisabled(String type, String? selectedId, String? path) {
    if (type == 'existing') return selectedId == null;
    return path == null;
  }

  Widget _buildEmptyResumesState(WidgetRef ref) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open_rounded, size: 40, color: _textMuted),
          const SizedBox(height: 12),
          const Text('No Saved Resumes Found',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
          const SizedBox(height: 4),
          const Text('Switch over to upload a new resume profile file directly.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _textSecondary)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(_applicationTypeProvider.notifier).state = 'upload',
            child: const Text('Go to Upload', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700)),
          )
        ],
      ),
    ),
  );

  Future<void> _pickLocalFile(WidgetRef ref) async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(label: 'resumes', extensions: <String>['pdf', 'docx']);
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      if (file != null) {
        ref.read(_localResumePathProvider.notifier).state = file.path;
        ref.read(_localResumeNameProvider.notifier).state = file.name;
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Future<void> _handleSubmission(
      BuildContext context,
      WidgetRef ref,
      String type,
      String? resumeId,
      String? localPath,
      ) async {
    ref.read(_isSubmittingProvider.notifier).state = true;

    try {
      if (type == 'upload') {
        await ref.read(
          applyJobProvider((jobPostingId: jobId, resumeId: null, localResumePath: localPath)).future,
        );
      } else {
        await ref.read(
          applyJobProvider((jobPostingId: jobId, resumeId: resumeId, localResumePath: null)).future,
        );
      }

      // Invalidate the job list so the card reflects "Applied" immediately
      ref.invalidate(jobControllerProvider);
      // Also invalidate the specific job detail cache
      ref.invalidate(jobDetailDataProvider(jobId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: _accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Pop apply screen, then pop the job detail bottom sheet
        // Returning true signals JobDetailPopup to also close itself
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit application: $error'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        ref.read(_isSubmittingProvider.notifier).state = false;
      }
    }
  }
}
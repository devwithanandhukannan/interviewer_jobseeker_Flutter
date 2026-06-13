import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';
import 'dart:developer' as dev;

class ResumeState {
  final List<dynamic> resumes;
  final bool isLoading;
  final String? listError;        // error for the list screen only
  final String? detailError;      // error for the detail screen only
  final dynamic activeResumeDetail;

  ResumeState({
    required this.resumes,
    this.isLoading = false,
    this.listError,
    this.detailError,
    this.activeResumeDetail,
  });

  ResumeState copyWith({
    List<dynamic>? resumes,
    bool? isLoading,
    String? listError,
    String? detailError,
    dynamic activeResumeDetail,
    bool clearListError = false,
    bool clearDetailError = false,
    bool clearActiveResume = false,
  }) {
    return ResumeState(
      resumes: resumes ?? this.resumes,
      isLoading: isLoading ?? this.isLoading,
      listError: clearListError ? null : (listError ?? this.listError),
      detailError: clearDetailError ? null : (detailError ?? this.detailError),
      activeResumeDetail: clearActiveResume
          ? null
          : (activeResumeDetail ?? this.activeResumeDetail),
    );
  }
}

final resumeControllerProvider =
StateNotifierProvider<ResumeController, ResumeState>((ref) {
  return ResumeController(ref);
});

class ResumeController extends StateNotifier<ResumeState> {
  final Ref _ref;

  ResumeController(this._ref) : super(ResumeState(resumes: [])) {
    Future.microtask(() => fetchResumes());
  }

  Future<Dio> _getAuthenticatedClient() async {
    return await _ref.read(dioProvider.future);
  }

  /// GET /resumes — populates list screen
  Future<void> fetchResumes() async {
    dev.log('fetchResumes: started');
    state = state.copyWith(isLoading: true, clearListError: true);
    try {
      final dio = await _getAuthenticatedClient();
      final response = await dio.get('jobseeker/resumes');

      dev.log('fetchResumes raw response: ${response.data}');

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : null;

      if (responseData == null) {
        state = state.copyWith(
            isLoading: false, listError: 'Invalid response from server');
        return;
      }

      if (responseData['success'] == true) {
        final List<dynamic> rawList =
        responseData['data'] is List ? responseData['data'] : [];
        dev.log('fetchResumes: loaded ${rawList.length} resumes');
        state = state.copyWith(
            resumes: rawList, isLoading: false, clearListError: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          listError: responseData['message']?.toString() ?? 'Failed to load resumes',
        );
      }
    } catch (e, stack) {
      dev.log('fetchResumes error: $e', stackTrace: stack);
      state = state.copyWith(isLoading: false, listError: e.toString());
    }
  }

  /// Fetch single resume by ID — populates detail screen only
  Future<void> fetchResumeById(String id) async {
    final String targetId = id.toString().trim().toLowerCase();

    // Wait if list is still loading (race condition guard)
    if (state.isLoading && state.resumes.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
    }

    // Search local cache
    dynamic localMatch;
    try {
      localMatch = state.resumes.firstWhere(
            (e) => e['id'].toString().trim().toLowerCase() == targetId,
      );
    } catch (_) {
      localMatch = null;
    }

    if (localMatch != null) {
      state = state.copyWith(
        activeResumeDetail: localMatch,
        clearDetailError: true,
      );
      return;
    }

    // Not cached — fetch from network (detail error only, never touches listError)
    state = state.copyWith(isLoading: true, clearDetailError: true);

    try {
      final dio = await _getAuthenticatedClient();
      final response = await dio.get('jobseeker/resumes');

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : null;

      if (responseData == null || responseData['success'] != true) {
        state = state.copyWith(
          isLoading: false,
          detailError: responseData?['message']?.toString() ?? 'Failed to load resume',
        );
        return;
      }

      final List<dynamic> rawList =
      responseData['data'] is List ? responseData['data'] : [];

      dynamic freshMatch;
      try {
        freshMatch = rawList.firstWhere(
              (e) => e['id'].toString().trim().toLowerCase() == targetId,
        );
      } catch (_) {
        freshMatch = null;
      }

      if (freshMatch != null) {
        state = state.copyWith(
          resumes: rawList,
          activeResumeDetail: freshMatch,
          isLoading: false,
          clearDetailError: true,
        );
      } else {
        state = state.copyWith(
          resumes: rawList,
          isLoading: false,
          detailError: 'Resume not found.',
        );
      }
    } catch (e, stack) {
      dev.log('fetchResumeById error: $e', stackTrace: stack);
      if (state.activeResumeDetail != null) {
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, detailError: e.toString());
      }
    }
  }

  /// POST /resumes/upload
  Future<bool> uploadResumeFile({
    required File file,
    required String name,
    String jobDescription = '',
  }) async {
    state = state.copyWith(isLoading: true, clearListError: true);
    try {
      final dio = await _getAuthenticatedClient();
      final String fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'name': name.trim(),
        'jobDescription': jobDescription.trim(),
        'resume': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await dio.post(
        'jobseeker/resumes/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.data['success'] == true) {
        await fetchResumes();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          listError: response.data['message']?.toString() ?? 'Upload failed',
        );
        return false;
      }
    } catch (e, stack) {
      dev.log('uploadResumeFile error: $e', stackTrace: stack);
      state = state.copyWith(isLoading: false, listError: e.toString());
      return false;
    }
  }

  /// PUT /resumes/:id
  Future<bool> updateResumeMeta(String id,
      {String? name, bool? isPrimary}) async {
    try {
      final dio = await _getAuthenticatedClient();
      final Map<String, dynamic> payload = {};
      if (name != null) payload['name'] = name;
      if (isPrimary != null) payload['isPrimary'] = isPrimary;

      final response = await dio.put('jobseeker/resumes/$id', data: payload);
      if (response.data['success'] == true) {
        await fetchResumes();
        if (state.activeResumeDetail != null &&
            state.activeResumeDetail['id'].toString() == id) {
          await fetchResumeById(id);
        }
        return true;
      }
      return false;
    } catch (e, stack) {
      dev.log('updateResumeMeta error: $e', stackTrace: stack);
      return false;
    }
  }

  /// DELETE /resumes/:id
  Future<bool> deleteResumeRecord(String id) async {
    state = state.copyWith(isLoading: true, clearListError: true);
    try {
      final dio = await _getAuthenticatedClient();
      final response = await dio.delete('jobseeker/resumes/$id');

      if (response.data['success'] == true) {
        final updatedList =
        state.resumes.where((r) => r['id'].toString() != id).toList();

        dynamic nextActive = state.activeResumeDetail;
        final bool wasActive =
            nextActive != null && nextActive['id'].toString() == id;

        state = state.copyWith(
          resumes: updatedList,
          isLoading: false,
          clearListError: true,
          clearActiveResume: wasActive,
          activeResumeDetail: wasActive ? null : nextActive,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          listError: response.data['message']?.toString() ?? 'Deletion failed',
        );
        return false;
      }
    } catch (e, stack) {
      dev.log('deleteResumeRecord error: $e', stackTrace: stack);
      state = state.copyWith(isLoading: false, listError: e.toString());
      return false;
    }
  }

  /// GET /resumes/:id/download
  Future<String?> downloadSystemFile(
      String id, String directorySavePath, String fileName) async {
    try {
      final dio = await _getAuthenticatedClient();
      final String cleanPath = '$directorySavePath/$fileName';
      final response =
      await dio.download('jobseeker/resumes/$id/download', cleanPath);
      if (response.statusCode == 200) return cleanPath;
      return null;
    } catch (e, stack) {
      dev.log('downloadSystemFile error: $e', stackTrace: stack);
      return null;
    }
  }
}
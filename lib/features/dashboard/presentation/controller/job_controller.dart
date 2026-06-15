import 'dart:io'; // Essential for handling direct File paths
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';

class JobState {
  final AsyncValue<List<dynamic>> jobListState; // Stores accumulated list data
  final AsyncValue<dynamic> jobDetailState;
  final AsyncValue<dynamic> appliedJobState;

  // Pagination & Filtering Metadata fields
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchKeyword;
  final Map<String, String> selectedFilters;

  const JobState({
    required this.jobDetailState,
    required this.jobListState,
    required this.appliedJobState,
    required this.currentPage,
    required this.hasMore,
    required this.isLoadingMore,
    required this.searchKeyword,
    required this.selectedFilters,
  });

  JobState copyWith({
    AsyncValue<List<dynamic>>? jobListState,
    AsyncValue<dynamic>? jobDetailState,
    AsyncValue<dynamic>? appliedJobState,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchKeyword,
    Map<String, String>? selectedFilters,
  }) {
    return JobState(
      jobDetailState: jobDetailState ?? this.jobDetailState,
      jobListState: jobListState ?? this.jobListState,
      appliedJobState: appliedJobState ?? this.appliedJobState,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      selectedFilters: selectedFilters ?? this.selectedFilters,
    );
  }
}

class JobController extends StateNotifier<JobState> {
  final Ref _ref;

  JobController(this._ref) : super(const JobState(
    jobDetailState: AsyncValue.loading(),
    jobListState: AsyncValue.data([]),
    appliedJobState: AsyncValue.loading(),
    currentPage: 1,
    hasMore: true,
    isLoadingMore: false,
    searchKeyword: '',
    selectedFilters: {},
  )) {
    fetchJobs(refresh: true);
  }

  /// Helper method to safely read the async Dio instance
  Future<Dio> _getDio() async {
    return await _ref.read(dioProvider.future);
  }

  /// Master fetch method supporting text query search and explicit filter sets
  Future<void> fetchJobs({bool refresh = false}) async {
    if (!mounted) return;

    if (!refresh && (state.isLoadingMore || !state.hasMore)) return;

    final targetPage = refresh ? 1 : state.currentPage + 1;

    if (refresh) {
      state = state.copyWith(
        jobListState: const AsyncValue.loading(),
        currentPage: 1,
        hasMore: true,
        isLoadingMore: false,
      );
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final Map<String, dynamic> queryParameters = {
        'page': targetPage,
        'limit': 20,
      };

      if (state.searchKeyword.isNotEmpty) {
        queryParameters['search'] = state.searchKeyword;
      }

      state.selectedFilters.forEach((key, value) {
        if (value.isNotEmpty) {
          queryParameters[key] = value;
        }
      });

      final dio = await _getDio();
      final response = await dio.get('public/search', queryParameters: queryParameters);

      if (mounted) {
        final rawData = response.data;
        List<dynamic> parsedJobs = [];

        if (rawData is Map && rawData.containsKey('data')) {
          parsedJobs = rawData['data'] is List ? rawData['data'] : [];
        } else if (rawData is List) {
          parsedJobs = rawData;
        }

        final List<dynamic> previousList = refresh ? [] : (state.jobListState.value ?? []);
        final updatedList = [...previousList, ...parsedJobs];

        state = state.copyWith(
          jobListState: AsyncValue.data(updatedList),
          currentPage: targetPage,
          hasMore: parsedJobs.length >= 20,
          isLoadingMore: false,
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        state = state.copyWith(
          jobListState: AsyncValue.error(e, stackTrace),
          isLoadingMore: false,
        );
      }
    }
  }

  void updateSearchKeyword(String value) {
    state = state.copyWith(searchKeyword: value);
    fetchJobs(refresh: true);
  }

  void updateFilter(String filterKey, String value) {
    final updatedFilters = Map<String, String>.from(state.selectedFilters);
    if (value.isEmpty) {
      updatedFilters.remove(filterKey);
    } else {
      updatedFilters[filterKey] = value;
    }
    state = state.copyWith(selectedFilters: updatedFilters);
    fetchJobs(refresh: true);
  }

  void clearAllFilters() {
    state = state.copyWith(selectedFilters: {}, searchKeyword: '');
    fetchJobs(refresh: true);
  }

  Future<void> fetchJobDetail(dynamic jobId) async {
    try {
      state = state.copyWith(jobDetailState: const AsyncValue.loading());
      final dio = await _getDio();
      final response = await dio.get('public/$jobId');
      if (mounted) {
        state = state.copyWith(jobDetailState: AsyncValue.data(response.data));
      }
    } catch (e, stackTrace) {
      if (mounted) {
        state = state.copyWith(jobDetailState: AsyncValue.error(e, stackTrace));
      }
    }
  }
}

final jobControllerProvider = StateNotifierProvider.autoDispose<JobController, JobState>(
      (ref) => JobController(ref),
);

final jobDetailDataProvider = FutureProvider.autoDispose.family<dynamic, String>((ref, jobId) async {
  final dio = await ref.read(dioProvider.future);
  final response = await dio.get('public/$jobId');
  return response.data;
});

final jobResumeProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  final dio = await ref.read(dioProvider.future);
  final response = await dio.get('jobseeker/resumes');
  return response.data;
});

// UPDATED ARGUMENTS CONFIGURATION: Supports passing an optional local system file path
typedef ApplyJobArgs = ({String jobPostingId, String? resumeId, String? localResumePath});

// UPDATED PROVIDER: Handles dynamic switching between standard json and multipart form data
final applyJobProvider = FutureProvider.autoDispose.family<dynamic, ApplyJobArgs>((ref, args) async {
  final dio = await ref.read(dioProvider.future);

  // If a local file path is provided, construct a multipart request mapping to 'newResume'
  if (args.localResumePath != null && args.localResumePath!.isNotEmpty) {
    final File resumeFile = File(args.localResumePath!);
    final String filename = resumeFile.path.split('/').last;

    final FormData formData = FormData.fromMap({
      'jobPostingId': args.jobPostingId,
      'applyWithNew': 'true',
      'newResume': await MultipartFile.fromFile(
        resumeFile.path,
        filename: filename,
      ),
    });

    final response = await dio.post(
      'jobseeker/applications/apply',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
    return response.data;
  } else {
    // Fallback to traditional handling using pre-existing loaded system profile maps
    final response = await dio.post(
      'jobseeker/applications/apply',
      data: {
        'jobPostingId': args.jobPostingId,
        'resumeId': args.resumeId,
        'applyWithNew': false,
      },
    );
    return response.data;
  }
});

class JobApplicationState {
  final AsyncValue<dynamic> applicationState;
  const JobApplicationState({required this.applicationState});

  JobApplicationState copyWith({AsyncValue<dynamic>? applicationState}) {
    return JobApplicationState(applicationState: applicationState ?? this.applicationState);
  }
}

class JobApplicationController extends StateNotifier<JobApplicationState> {
  final Ref _ref;
  JobApplicationController(this._ref) : super(const JobApplicationState(applicationState: AsyncValue.loading()));

  Future<Dio> _getDio() async {
    return await _ref.read(dioProvider.future);
  }

  Future<void> fetchApplicationLogs(dynamic applicationId) async {
    try {
      final dio = await _getDio();
      final response = await dio.get('jobseeker/tracker/$applicationId');
      if (mounted) {
        state = state.copyWith(applicationState: AsyncValue.data(response.data));
      }
    } catch (e, s) {
      if (mounted) {
        state = state.copyWith(applicationState: AsyncValue.error(e, s));
      }
    }
  }
}

final jobApplicationProvider = StateNotifierProvider.autoDispose<JobApplicationController, JobApplicationState>((ref) {
  return JobApplicationController(ref);
});



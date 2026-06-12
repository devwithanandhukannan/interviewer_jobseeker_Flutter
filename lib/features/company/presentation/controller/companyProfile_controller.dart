import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';

class CompanyState {
  final AsyncValue<dynamic> companyData;
  const CompanyState({required this.companyData});

  CompanyState copyWith({AsyncValue<dynamic>? companyData}){
    return CompanyState(companyData: companyData ?? this.companyData);
  }
}

class CompanyProfileController extends StateNotifier<CompanyState>{
  final Ref _ref;

  CompanyProfileController(this._ref) : super(const CompanyState(companyData: AsyncValue.loading()));

  /// Helper method to safely read the async Dio instance
  Future<Dio> _getDio() async {
    return await _ref.read(dioProvider.future);
  }

  // Note: Followed Dart naming conventions by lowering the first letter (fetchCompanyData)
  Future<void> fetchCompanyData(dynamic companyId) async {
    // Set state back to loading if it's called multiple times with different IDs
    state = state.copyWith(companyData: const AsyncValue.loading());

    try {
      print('Fetching data for companyId: $companyId');
      final dio = await _getDio();

      // Fix: Removed the leading slash '/' because your base URL likely ends with 'api/'
      // combining 'api/' + '/public/companies' creates a broken link 'api//public/companies'
      final response = await dio.get('public/companies/$companyId');

      if (mounted) {
        state = state.copyWith(companyData: AsyncValue.data(response.data['data']));
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = state.copyWith(companyData: AsyncValue.error(error, stackTrace));
      }
    }
  }
}

final companyProfileControllerProvider = StateNotifierProvider.autoDispose<CompanyProfileController, CompanyState>((ref){
  return CompanyProfileController(ref);
});
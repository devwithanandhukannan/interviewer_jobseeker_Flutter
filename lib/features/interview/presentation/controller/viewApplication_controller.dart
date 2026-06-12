
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';
import 'package:dio/dio.dart';
import 'package:interviewer/features/dashboard/presentation/controller/job_controller.dart';

class ApplicationState {
  final AsyncValue<dynamic> applicationData;
  const ApplicationState({required this.applicationData});
  ApplicationState copyWith({AsyncValue<dynamic>? applicationData}){
    return ApplicationState(applicationData: applicationData?? this.applicationData);
  }
}
class ApplicationController extends StateNotifier<ApplicationState>{
  final Ref _ref;

  Future<Dio> _getDio() async{
    return await _ref.read(dioProvider.future);
  }

  ApplicationController(this._ref):super(const ApplicationState(applicationData: AsyncValue.loading()));

  Future<void> fetchData() async{
    try{
      final _dio = await _getDio();
      final response = await _dio.get('/jobseeker/applications/tracker/timeline');
      if(mounted){
        state = state.copyWith(applicationData: AsyncValue.data(response.data));
      }
    }catch(error, stackTrace){
      state = state.copyWith(applicationData: AsyncValue.error(error, stackTrace));
    }
  }
}

final ApplicationsControllerProvider = StateNotifierProvider<ApplicationController, ApplicationState>((ref){
  return ApplicationController(ref);
});


import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';

class ResumeState {
  final AsyncValue<dynamic> resumeData;

  const ResumeState({required this.resumeData});
  ResumeState copyWith({
    AsyncValue<dynamic>? resumeData,
  }) {
    return ResumeState(
      resumeData: resumeData ?? this.resumeData,
    );
  }
}

class ResumeController extends StateNotifier<ResumeState>{
  final Ref _ref;
  ResumeController(this._ref):super(const ResumeState(resumeData: AsyncValue.loading()));
  Future<Dio> _getDio() async {
    return await _ref.read(dioProvider.future);
  }

  Future<void> FetchResumes() async{
    try{
      final _dio = await _getDio();
      final response = await _dio.post('/jobseeker/resumes');
      if(mounted){
        state = state.copyWith(resumeData: AsyncValue.data(response.data));
        print(response.data);
      }
    }catch(error, stackTrace){
      state = state.copyWith(resumeData: AsyncValue.error(error, stackTrace));
    }
  }

}
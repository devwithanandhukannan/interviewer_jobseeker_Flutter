import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';

class ProfileState {
  final AsyncValue<dynamic> profileState;
  const ProfileState({required this.profileState});

  ProfileState copyWith({AsyncValue<dynamic>? profileState}){
    return ProfileState(profileState: profileState ?? this.profileState);
  }
}

class ProfileController extends StateNotifier<ProfileState>{
  final Ref _ref;

  ProfileController(this._ref): super(const ProfileState(profileState: AsyncValue.loading())) {
    FetchUserProfile();
  }

  Future<Dio> _getDio() async{
    // Fix: Use ref.read for the future configuration mapping inside an action method
    return await _ref.read(dioProvider.future);
  }

  Future<void> FetchUserProfile() async{
    try{
      final dioInstance = await _getDio();
      // Fix: Cleaned leading slash to respect base URL boundaries
      final response = await dioInstance.get('jobseeker/profile');

      if(mounted){
        // Safely extract the inner 'data' object from {"success": true, "data": {...}}
        final profileData = response.data != null ? response.data['data'] : null;
        state = state.copyWith(profileState: AsyncValue.data(profileData));
      }
    }catch(e,s){
      if(mounted){
        state = state.copyWith(profileState: AsyncValue.error(e, s));
      }
    }
  }

  Future<void> UpdateUserProfile(dynamic profileData) async{
    try{
      // Clean the data
      final cleanedData = _cleanProfileData(profileData);

      print('Cleaned profile data: $cleanedData'); // Debug log

      dynamic requestBody;
      Options requestOptions;

      // Extract profile picture data reference
      final profilePicPath = cleanedData['profilePic']?.toString();

      // Determine if profilePic points to a fresh local file path rather than a URL or raw base64 string
      final isLocalFile = profilePicPath != null &&
          !profilePicPath.startsWith('http') &&
          !profilePicPath.startsWith('data:');

      if (isLocalFile) {
        // Clear the profilePic key inside the metadata JSON string so it doesn't cause formatting string syntax exceptions
        cleanedData['profilePic'] = null;

        // Use FormData multipart parameters for multi-part requests as expected by the backend
        requestBody = FormData.fromMap({
          'profileData': jsonEncode(cleanedData), // Keep everything tightly formatted inside the profileData wrapper string
          'file': await MultipartFile.fromFile(
            profilePicPath,
            filename: profilePicPath.split('/').last,
          ),
        });

        requestOptions = Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        );
      } else {
        // Traditional raw application/json fallback structure
        requestBody = {
          'profileData': jsonEncode(cleanedData),
        };

        requestOptions = Options(
          headers: {
            'Content-Type': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        );
      }

      print('Sending to backend: $requestBody'); // Debug log

      // Fix: Fetch and assign the correct localized dio variable instead of calling unallocated target '_dio'
      final dioInstance = await _getDio();
      final response = await dioInstance.put(
        'jobseeker/profile',
        data: requestBody,
        options: requestOptions,
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response data: ${response.data}'); // Debug log

      if(response.statusCode == 200 || response.statusCode == 201){
        if(mounted){
          // Backend returns {success: true, message: "..."} on update
          // We need to fetch the updated profile to get the full data
          await FetchUserProfile();
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: response.data['error'] ?? response.data['message'] ?? 'Failed to update profile',
        );
      }
    } on DioException catch(e, s){
      print('DioException: ${e.message}'); // Debug log
      print('Response data: ${e.response?.data}'); // Debug log
      print('Status code: ${e.response?.statusCode}'); // Debug log

      if(mounted){
        state = state.copyWith(profileState: AsyncValue.error(e, s));
      }
      rethrow;
    } catch(e, s){
      print('General error: $e'); // Debug log
      if(mounted){
        state = state.copyWith(profileState: AsyncValue.error(e, s));
      }
      rethrow;
    }
  }

  // Clean the profile data to match backend expectations
  Map<String, dynamic> _cleanProfileData(dynamic profileData) {
    if (profileData is! Map<String, dynamic>) {
      throw ArgumentError('Profile data must be a Map');
    }

    final cleaned = Map<String, dynamic>.from(profileData);

    // Clean basic fields - keep empty strings as they might be intentional clears
    cleaned['fullName'] = cleaned['fullName']?.toString().trim() ?? '';
    cleaned['email'] = cleaned['email']?.toString().trim() ?? '';
    cleaned['phone'] = cleaned['phone']?.toString().trim() ?? '';
    cleaned['location'] = cleaned['location']?.toString().trim() ?? '';
    cleaned['linkedin'] = cleaned['linkedin']?.toString().trim() ?? '';
    cleaned['github'] = cleaned['github']?.toString().trim() ?? '';
    cleaned['portfolio'] = cleaned['portfolio']?.toString().trim() ?? '';
    cleaned['bio'] = cleaned['bio']?.toString().trim() ?? '';

    // Keep profilePic as is
    if (!cleaned.containsKey('profilePic')) {
      cleaned['profilePic'] = null;
    }

    // Clean preferences
    if (cleaned['preferences'] is Map) {
      final prefs = Map<String, dynamic>.from(cleaned['preferences']);
      cleaned['preferences'] = {
        'roles': (prefs['roles'] as List?)?.where((e) => e != null && e.toString().trim().isNotEmpty).toList() ?? [],
        'industries': (prefs['industries'] as List?)?.where((e) => e != null && e.toString().trim().isNotEmpty).toList() ?? [],
        'jobType': prefs['jobType']?.toString().trim() ?? '',
        'experience': prefs['experience']?.toString().trim() ?? '',
        'expectedSalary': prefs['expectedSalary']?.toString().trim() ?? '',
        'workLocationPreference': prefs['workLocationPreference']?.toString().trim() ?? '',
      };
    } else {
      cleaned['preferences'] = {
        'roles': [],
        'industries': [],
        'jobType': '',
        'experience': '',
        'expectedSalary': '',
        'workLocationPreference': '',
      };
    }

    // Clean skills
    cleaned['skills'] = (cleaned['skills'] as List?)
        ?.where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString().trim())
        .toList() ?? [];

    // Clean education - filter out empty entries
    cleaned['education'] = ((cleaned['education'] as List?) ?? [])
        .map((e) => _cleanEducation(e))
        .where((e) => e != null && e['institution']?.toString().trim().isNotEmpty == true)
        .toList();

    // Clean experience - filter out empty entries
    cleaned['experience'] = ((cleaned['experience'] as List?) ?? [])
        .map((e) => _cleanExperience(e))
        .where((e) => e != null && e['company']?.toString().trim().isNotEmpty == true)
        .toList();

    // Clean projects - filter out empty entries
    cleaned['projects'] = ((cleaned['projects'] as List?) ?? [])
        .map((e) => _cleanProject(e))
        .where((e) => e != null && e['name']?.toString().trim().isNotEmpty == true)
        .toList();

    // Clean certifications - filter out empty entries
    cleaned['certifications'] = ((cleaned['certifications'] as List?) ?? [])
        .map((e) => _cleanCertification(e))
        .where((e) => e != null && e['name']?.toString().trim().isNotEmpty == true)
        .toList();

    // Clean languages - filter out empty entries
    cleaned['languages'] = ((cleaned['languages'] as List?) ?? [])
        .map((e) => _cleanLanguage(e))
        .where((e) => e != null && e['language']?.toString().trim().isNotEmpty == true)
        .toList();

    // Clean achievements - filter out empty entries
    cleaned['achievements'] = ((cleaned['achievements'] as List?) ?? [])
        .map((e) => _cleanAchievement(e))
        .where((e) => e != null && e['title']?.toString().trim().isNotEmpty == true)
        .toList();

    return cleaned;
  }

  Map<String, dynamic>? _cleanEducation(dynamic item) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);
    map.remove('id'); // Remove UI-only field
    return {
      'institution': map['institution']?.toString().trim() ?? '',
      'degree': map['degree']?.toString().trim() ?? '',
      'field': map['field']?.toString().trim() ?? '',
      'location': map['location']?.toString().trim() ?? '',
      'startMonth': map['startMonth']?.toString().trim() ?? '',
      'startYear': map['startYear']?.toString().trim() ?? '',
      'endMonth': map['endMonth']?.toString().trim() ?? '',
      'endYear': map['endYear']?.toString().trim() ?? '',
      'cgpa': map['cgpa']?.toString().trim() ?? '',
      'description': map['description']?.toString().trim() ?? '',
    };
  }

  Map<String, dynamic>? _cleanExperience(dynamic item) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);
    map.remove('id'); // Remove UI-only field
    return {
      'company': map['company']?.toString().trim() ?? '',
      'role': map['role']?.toString().trim() ?? '',
      'location': map['location']?.toString().trim() ?? '',
      'startMonth': map['startMonth']?.toString().trim() ?? '',
      'startYear': map['startYear']?.toString().trim() ?? '',
      'endMonth': map['endMonth']?.toString().trim() ?? '',
      'endYear': map['endYear']?.toString().trim() ?? '',
      'current': map['current'] == true,
      'description': map['description']?.toString().trim() ?? '',
      'skills': (map['skills'] as List?)?.where((e) => e != null && e.toString().trim().isNotEmpty).toList() ?? [],
    };
  }

  Map<String, dynamic>? _cleanProject(dynamic item) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);
    map.remove('id'); // Remove UI-only field
    return {
      'name': map['name']?.toString().trim() ?? '',
      'description': map['description']?.toString().trim() ?? '',
      'technologies': (map['technologies'] as List?)?.where((e) => e != null && e.toString().trim().isNotEmpty).toList() ?? [],
      'githubLink': map['githubLink']?.toString().trim() ?? '',
      'liveLink': map['liveLink']?.toString().trim() ?? '',
    };
  }

  Map<String, dynamic>? _cleanCertification(dynamic item) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);
    map.remove('id'); // Remove UI-only field
    return {
      'name': map['name']?.toString().trim() ?? '',
      'organization': map['organization']?.toString().trim() ?? '',
      'issueDate': map['issueDate']?.toString().trim() ?? '',
      'credentialUrl': map['credentialUrl']?.toString().trim() ?? '',
    };
  }

  Map<String, dynamic>? _cleanLanguage(dynamic item) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);
    map.remove('id'); // Remove UI-only field
    return {
      'language': map['language']?.toString().trim() ?? '',
      'proficiency': map['proficiency']?.toString().trim() ?? 'Beginner',
    };
  }

  Map<String, dynamic>? _cleanAchievement(dynamic item) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);
    map.remove('id'); // Remove UI-only field
    return {
      'title': map['title']?.toString().trim() ?? '',
      'description': map['description']?.toString().trim() ?? '',
      'year': map['year']?.toString().trim() ?? '',
    };
  }
}

final profileControllerProvider = StateNotifierProvider.autoDispose<ProfileController, ProfileState>((ref){
  return ProfileController(ref);
});
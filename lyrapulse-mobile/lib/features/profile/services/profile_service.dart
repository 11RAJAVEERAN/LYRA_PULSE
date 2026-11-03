
import 'package:dio/dio.dart';

import '../models/profile_model.dart';

class ProfileService {
  final Dio dio;

  ProfileService({required this.dio});

  // Update this endpoint when the backend API is confirmed.
  static const String profileEndpoint = '/employee/profile';

  Future<ProfileModel> getProfile() async {
    try {
      final response = await dio.get(profileEndpoint);

      final data = response.data;

      if (data is! Map) {
        throw Exception('Invalid profile response');
      }

      final responseData = data['data'] ?? data;

      if (responseData is! Map) {
        throw Exception('Profile data not found');
      }

      return ProfileModel.fromJson(
        Map<String, dynamic>.from(responseData),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Unable to fetch profile',
      );
    }
  }

  Future<ProfileModel> updateProfile(
    ProfileModel profile,
  ) async {
    try {
      final response = await dio.put(
        profileEndpoint,
        data: profile.toUpdateJson(),
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception('Invalid update response');
      }

      final responseData = data['data'] ?? data;

      if (responseData is! Map) {
        throw Exception('Updated profile not found');
      }

      return ProfileModel.fromJson(
        Map<String, dynamic>.from(responseData),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Unable to update profile',
      );
    }
  }
}

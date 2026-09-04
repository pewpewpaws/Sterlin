import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Pure HTTP network client for communicating with Etlab endpoints.
/// Does not depend on Flutter state, storage, or UI.
class EtlabApiClient {
  final http.Client _httpClient;

  EtlabApiClient({http.Client? client}) : _httpClient = client ?? http.Client();

  /// Constructs the base URL for the given college subdomain.
  static String buildBaseUrl(String subdomain) {
    final cleanSub = subdomain.trim().isEmpty ? 'sctce' : subdomain.trim();
    final url = 'https://$cleanSub.etlab.in/androidapp';
    if (!url.startsWith('https://')) {
      throw Exception('Insecure URL blocked: $url');
    }
    return url;
  }

  /// Builds authorization headers.
  static Map<String, String> buildAuthHeaders(String? accessToken) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      final token = accessToken.startsWith('Bearer ')
          ? accessToken
          : 'Bearer $accessToken';
      headers['Authorization'] = token;
    }
    return headers;
  }

  /// Authenticates user credentials via Etlab login API.
  Future<Map<String, dynamic>?> login({
    required String baseUrl,
    required String username,
    required String password,
    String hostelId = '0',
  }) async {
    final url = Uri.parse('$baseUrl/app/login');
    final payload = {
      'username': username.trim(),
      'password': password,
      'hostel': hostelId.trim().isEmpty ? '0' : hostelId.trim(),
    };

    try {
      // 1. Try JSON POST request
      var response = await _httpClient
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic>? data;
      try {
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body) as Map<String, dynamic>?;
        }
      } catch (_) {}

      // 2. Fallback to form-urlencoded if JSON fails or returns login=false
      if (response.statusCode != 200 ||
          data == null ||
          data['login'] == false) {
        final formResponse = await _httpClient
            .post(
              url,
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
              },
              body: payload,
            )
            .timeout(const Duration(seconds: 15));

        if (formResponse.statusCode == 200 && formResponse.body.isNotEmpty) {
          try {
            final formData =
                jsonDecode(formResponse.body) as Map<String, dynamic>?;
            if (formData != null && formData['login'] != false) {
              response = formResponse;
              data = formData;
            }
          } catch (_) {}
        }
      }

      if (data != null && (data['login'] != false && data['status'] != '0')) {
        return data;
      }
      return null;
    } on TimeoutException {
      debugPrint('[EtlabApiClient] login timeout for user ${username.trim()}');
      throw Exception('Connection timed out. Please try again.');
    } catch (e) {
      debugPrint('[EtlabApiClient] login error: $e');
      throw Exception('Login failed. Check connection.');
    }
  }

  /// Fetches student profile data.
  Future<Map<String, dynamic>?> fetchProfile({
    required String baseUrl,
    required String? token,
  }) async {
    final url = Uri.parse('$baseUrl/app/profile');
    final response = await _httpClient
        .post(url, headers: buildAuthHeaders(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    return null;
  }

  /// Fetches subject-wise attendance.
  Future<Map<String, dynamic>?> fetchAttendanceBySubject({
    required String baseUrl,
    required String? token,
    String? semester,
  }) async {
    final url = Uri.parse('$baseUrl/app/attendancebysubject');
    final bodyMap = (semester != null && semester.isNotEmpty)
        ? {'sem_id': semester, 'semester': semester}
        : <String, String>{};

    final response = await _httpClient
        .post(
          url,
          headers: buildAuthHeaders(token),
          body: jsonEncode(bodyMap),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    return null;
  }

  /// Fetches faculty/teachers directory.
  Future<Map<String, dynamic>?> fetchTeachers({
    required String baseUrl,
    required String? token,
  }) async {
    final url = Uri.parse('$baseUrl/app/teachers');
    final response = await _httpClient
        .post(url, headers: buildAuthHeaders(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    return null;
  }

  /// Fetches semester list for student.
  Future<List<dynamic>?> fetchSemesterList({
    required String baseUrl,
    required String? token,
  }) async {
    final url = Uri.parse('$baseUrl/app/semesterlist');
    final response = await _httpClient
        .post(url, headers: buildAuthHeaders(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List<dynamic>) {
        return data;
      } else if (data is Map<String, dynamic>) {
        final semList =
            data['semesters'] ??
            data['data'] ??
            data['semesterlist'] ??
            data['semesters_list'];
        if (semList is List<dynamic>) {
          return semList;
        }
      }
    }
    return null;
  }

  /// Fetches day-period attendance for a given month/year and semester.
  Future<Map<String, dynamic>?> fetchAttendanceByDayPeriod({
    required String baseUrl,
    required String? token,
    required int month,
    required int year,
    required String semester,
  }) async {
    final url = Uri.parse('$baseUrl/app/attendancebydayperiod');
    final payload = {
      'month': month.toString(),
      'semester': semester,
      'year': year.toString(),
    };

    final response = await _httpClient
        .post(
          url,
          headers: buildAuthHeaders(token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    return null;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Map<String, String> _buildHeaders() {
    final headers = Map<String, String>.from(ApiConstants.defaultHeaders);
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConstants.baseUrl}$cleanPath').replace(
      queryParameters: queryParameters?.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Future<ApiResponse<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await http.get(uri, headers: _buildHeaders()).timeout(const Duration(seconds: 20));
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Lỗi kết nối máy chủ: $e', statusCode: 500);
    }
  }

  Future<ApiResponse<dynamic>> post(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await http.post(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 20));
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Lỗi kết nối máy chủ: $e', statusCode: 500);
    }
  }

  Future<ApiResponse<dynamic>> put(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await http.put(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 20));
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Lỗi kết nối máy chủ: $e', statusCode: 500);
    }
  }

  Future<ApiResponse<dynamic>> delete(String path) async {
    try {
      final uri = _buildUri(path);
      final response = await http.delete(uri, headers: _buildHeaders()).timeout(const Duration(seconds: 20));
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Lỗi kết nối máy chủ: $e', statusCode: 500);
    }
  }

  Future<ApiResponse<dynamic>> uploadFile(String path, File file, {String fieldName = 'file'}) async {
    try {
      final uri = _buildUri(path);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      });
      request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Lỗi upload ảnh: $e', statusCode: 500);
    }
  }

  ApiResponse<dynamic> _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        success: true,
        data: decoded,
        statusCode: response.statusCode,
      );
    } else {
      String errMsg = 'Yêu cầu không thành công (${response.statusCode})';
      if (decoded is Map && decoded['message'] != null) {
        errMsg = decoded['message'].toString();
      } else if (decoded is Map && decoded['thongBao'] != null) {
        errMsg = decoded['thongBao'].toString();
      } else if (decoded is String && decoded.isNotEmpty && !decoded.contains('<!DOCTYPE')) {
        errMsg = decoded;
      }
      return ApiResponse(
        success: false,
        data: decoded,
        message: errMsg,
        statusCode: response.statusCode,
      );
    }
  }
}

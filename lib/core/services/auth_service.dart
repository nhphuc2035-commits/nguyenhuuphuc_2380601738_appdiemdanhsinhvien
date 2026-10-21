import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<ApiResponse<dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String maSV,
    required String hoTen,
    String lop = '21DTH01',
    String khoa = 'Công nghệ thông tin',
    String soDienThoai = '',
    String role = 'SinhVien',
  }) async {
    final body = {
      'username': username,
      'email': email,
      'password': password,
      'maSV': maSV,
      'hoTen': hoTen,
      'lop': lop,
      'khoa': khoa,
      'soDienThoai': soDienThoai,
      'role': role,
    };
    return await _api.post(ApiConstants.register, body: body);
  }

  Future<ApiResponse<dynamic>> requestOtp({
    required String username,
    required String password,
  }) async {
    final body = {
      'username': username,
      'password': password,
    };
    return await _api.post(ApiConstants.requestOtp, body: body);
  }

  Future<ApiResponse<dynamic>> verifyOtp({
    required String username,
    required String otp,
  }) async {
    final body = {
      'username': username,
      'otp': otp,
    };
    final response = await _api.post(ApiConstants.verifyOtp, body: body);
    if (response.success && response.data is Map) {
      final token = response.data['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await saveToken(token);
      }
    }
    return response;
  }

  Future<UserModel?> getMe() async {
    final response = await _api.get(ApiConstants.me);
    if (response.success && response.data is Map<String, dynamic>) {
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> saveToken(String token) async {
    _api.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    _api.setToken(token);
    return token;
  }

  Future<void> logout() async {
    _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_info');
  }
}

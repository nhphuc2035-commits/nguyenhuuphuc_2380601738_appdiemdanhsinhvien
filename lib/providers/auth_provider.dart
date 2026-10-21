import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;
  String? _token;
  String? _pendingUsername;
  String? _demoOtp;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  String? get pendingUsername => _pendingUsername;
  String? get demoOtp => _demoOtp;

  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSinhVien => _currentUser?.isSinhVien ?? false;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Initial load when app starts
  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedToken = await _authService.getToken();
      if (savedToken == null || savedToken.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _token = savedToken;
      final user = await _authService.getMe();
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        await _authService.logout();
        _token = null;
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Step 1 of Login: Request OTP
  Future<bool> requestOtp(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _pendingUsername = username;
    _demoOtp = null;
    notifyListeners();

    final response = await _authService.requestOtp(
      username: username,
      password: password,
    );

    _isLoading = false;
    if (response.success) {
      if (response.data is Map) {
        _demoOtp = response.data['demoOtp']?.toString();
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Đăng nhập không thành công';
      notifyListeners();
      return false;
    }
  }

  /// Step 2 of Login: Verify OTP
  Future<bool> verifyOtp(String otp) async {
    if (_pendingUsername == null) {
      _errorMessage = 'Vui lòng thực hiện bước đăng nhập trước';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.verifyOtp(
      username: _pendingUsername!,
      otp: otp,
    );

    if (response.success && response.data is Map) {
      _token = response.data['token']?.toString();
      // Fetch full profile via /me
      final user = await _authService.getMe();
      if (user != null) {
        _currentUser = user;
      } else if (response.data['user'] != null) {
        _currentUser = UserModel.fromJson(response.data['user']);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      _errorMessage = response.message ?? 'Mã OTP không chính xác hoặc đã hết hạn';
      notifyListeners();
      return false;
    }
  }

  /// Register new student account
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String maSV,
    required String hoTen,
    String lop = '21DTH01',
    String khoa = 'Công nghệ thông tin',
    String soDienThoai = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.register(
      username: username,
      email: email,
      password: password,
      maSV: maSV,
      hoTen: hoTen,
      lop: lop,
      khoa: khoa,
      soDienThoai: soDienThoai,
      role: 'SinhVien',
    );

    _isLoading = false;
    if (response.success) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Đăng ký tài khoản thất bại';
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    _token = null;
    _currentUser = null;
    _pendingUsername = null;
    _demoOtp = null;
    _isLoading = false;
    notifyListeners();
  }
}

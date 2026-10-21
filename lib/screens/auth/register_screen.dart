import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _maSvController = TextEditingController();
  final _hoTenController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _lopController = TextEditingController(text: '21DTH01');
  final _khoaController = TextEditingController(text: 'Công nghệ thông tin');
  final _soDienThoaiController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _maSvController.dispose();
    _hoTenController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _lopController.dispose();
    _khoaController.dispose();
    _soDienThoaiController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim().isNotEmpty
        ? _usernameController.text.trim()
        : _maSvController.text.trim();
    final lop = _lopController.text.trim().isNotEmpty ? _lopController.text.trim() : '21DTH01';
    final khoa = _khoaController.text.trim().isNotEmpty ? _khoaController.text.trim() : 'Công nghệ thông tin';

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      username: username,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      maSV: _maSvController.text.trim(),
      hoTen: _hoTenController.text.trim(),
      lop: lop,
      khoa: khoa,
      soDienThoai: _soDienThoaiController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 54),
          title: const Text('Đăng Ký Thành Công!'),
          content: Text(
            'Tài khoản sinh viên ${_hoTenController.text} (MSSV: ${_maSvController.text}) đã được khởi tạo thành công trên hệ thống.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // back to Login
              },
              child: const Text('Đến trang Đăng Nhập'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng ký không thành công'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản Sinh Viên'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin sinh viên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // MSSV
                      TextFormField(
                        controller: _maSvController,
                        decoration: const InputDecoration(
                          labelText: 'Mã số sinh viên (MSSV) *',
                          prefixIcon: Icon(Icons.badge_outlined),
                          hintText: 'VD: 2380601738',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Vui lòng nhập MSSV';
                          return null;
                        },
                        onChanged: (val) {
                          if (_usernameController.text.isEmpty ||
                              _usernameController.text == val.substring(0, val.length > 1 ? val.length - 1 : 0)) {
                            _usernameController.text = val;
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Họ tên
                      TextFormField(
                        controller: _hoTenController,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên *',
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: 'VD: Nguyễn Hữu Phúc',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Vui lòng nhập họ tên';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email sinh viên *',
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'VD: sinhvien@nhom2.edu.vn',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Vui lòng nhập email';
                          if (!val.contains('@')) return 'Email không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Lớp & Khoa
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lopController,
                              decoration: const InputDecoration(
                                labelText: 'Lớp',
                                prefixIcon: Icon(Icons.group_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _khoaController,
                              decoration: const InputDecoration(
                                labelText: 'Khoa',
                                prefixIcon: Icon(Icons.domain_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Số điện thoại
                      TextFormField(
                        controller: _soDienThoaiController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '0901234567',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin đăng nhập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên đăng nhập (để trống sẽ tự lấy MSSV)',
                          prefixIcon: Icon(Icons.account_circle_outlined),
                          hintText: 'Mặc định dùng MSSV',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
                          if (val.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu *',
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (val) {
                          if (val != _passwordController.text) return 'Mật khẩu xác nhận không khớp';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: auth.isLoading ? null : _submitRegister,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Đăng Ký Tài Khoản',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

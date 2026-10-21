import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nguyenhuuphuc_2380601738_appdiemdanhsinhvien/core/theme/app_theme.dart';
import 'package:nguyenhuuphuc_2380601738_appdiemdanhsinhvien/providers/auth_provider.dart';
import 'package:nguyenhuuphuc_2380601738_appdiemdanhsinhvien/screens/auth/login_screen.dart';

void main() {
  testWidgets('Login screen loads properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    expect(find.text('HỆ THỐNG ĐIỂM DANH SINH VIÊN'), findsOneWidget);
    expect(find.text('Đăng Nhập Hệ Thống'), findsOneWidget);
  });
}

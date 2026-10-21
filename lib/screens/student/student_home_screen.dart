import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/attendance_detail_modal.dart';
import '../auth/login_screen.dart';
import 'checkin_screen.dart';
import 'student_leave_request_screen.dart';
import 'student_attendance_history_screen.dart';
import 'student_risk_warning_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final svId = auth.currentUser?.sinhVien?.id;
      if (svId != null && svId > 0) {
        Provider.of<StudentProvider>(context, listen: false).fetchStudentData(svId);
      }
    });
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final student = Provider.of<StudentProvider>(context);
    final sv = auth.currentUser?.sinhVien;

    final myHistory = student.myDiemDanhs;
    // Môn học LTDD quy định 9 buổi
    final totalCourseSessions = student.myLopHocPhans.isNotEmpty
        ? (student.myLopHocPhans.first.soBuoi > 0 ? student.myLopHocPhans.first.soBuoi : 9)
        : 9;
    final presentCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'comat').length;
    final lateCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'ditre').length;
    final unexcusedAbsentCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'vangkhongphep').length;
    final excusedAbsentCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'vangcophep').length;

    // CHỈ VẮNG KHÔNG PHÉP MỚI TÍNH VÀO TỶ LỆ CẤM THI!
    final banRate = totalCourseSessions > 0 ? (unexcusedAbsentCount / totalCourseSessions * 100.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm Danh Sinh Viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới dữ liệu',
            onPressed: () {
              if (sv?.id != null) {
                student.fetchStudentData(sv!.id);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (sv?.id != null) {
            await student.fetchStudentData(sv!.id);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Student Profile Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), AppTheme.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          (sv?.hoTen ?? auth.currentUser?.hoTen ?? 'P').isNotEmpty
                              ? (sv?.hoTen ?? auth.currentUser?.hoTen ?? 'P')[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sv?.hoTen ?? auth.currentUser?.hoTen ?? 'Nguyễn Hữu Phúc',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'MSSV: ${sv?.maSV ?? auth.currentUser?.maSV ?? "2380601738"}  •  Lớp: ${sv?.lop ?? "21DTH01"}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Khoa: ${sv?.khoa ?? "Công nghệ thông tin"}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. EXAM BAN RADAR ALERT CARD
              _buildExamBanWarningCard(
                unexcusedAbsentCount: unexcusedAbsentCount,
                excusedAbsentCount: excusedAbsentCount,
                lateCount: lateCount,
                totalCourseSessions: totalCourseSessions,
                banRate: banRate,
              ),

              const SizedBox(height: 14),

              // 3. BIG ATTENDANCE ACTION BUTTON (GPS + Biometrics)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckInScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 34),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ĐIỂM DANH NGAY',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'GPS phòng học + Sinh trắc vân tay',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF1E40AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryColor, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. Detailed Statistics Counters (Fix Overflow)
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Đúng giờ',
                      value: '$presentCount',
                      color: AppTheme.successColor,
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatBox(
                      label: 'Đi trễ',
                      value: '$lateCount',
                      color: AppTheme.warningColor,
                      icon: Icons.access_time_filled_rounded,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatBox(
                      label: 'Vắng KP',
                      value: '$unexcusedAbsentCount',
                      color: AppTheme.dangerColor,
                      icon: Icons.cancel_rounded,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatBox(
                      label: 'Có phép',
                      value: '$excusedAbsentCount',
                      color: const Color(0xFF0D9488),
                      icon: Icons.verified_user_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Quick Action Cards (OCR 5f & Full History)
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Nộp Đơn Nghỉ Phép',
                      subtitle: 'Chụp ảnh & Dịch OCR',
                      icon: Icons.document_scanner_rounded,
                      color: const Color(0xFF0D9488),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentLeaveRequestScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Lịch Sử Điểm Danh',
                      subtitle: 'Chi tiết từng buổi (Giờ VN)',
                      icon: Icons.history_edu_rounded,
                      color: const Color(0xFF7C3AED),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentAttendanceHistoryScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 6. Recent Attendance Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Lịch Sử Điểm Danh Gần Đây',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('Xem tất cả', style: TextStyle(fontSize: 12.5)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentAttendanceHistoryScreen()),
                      );
                    },
                  ),
                ],
              ),

              if (student.isLoading && myHistory.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (myHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_busy_rounded, color: AppTheme.textSecondary, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'Bạn chưa có dữ liệu điểm danh nào.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myHistory.length > 3 ? 3 : myHistory.length,
                  itemBuilder: (context, index) {
                    final dd = myHistory[index];
                    final statusColor = AppFormatters.getStatusColor(dd.trangThai);
                    final statusLabel = AppFormatters.getStatusLabel(dd.trangThai);
                    final methodIcon = AppFormatters.getMethodIcon(dd.phuongThuc);
                    final timeVN = AppFormatters.formatVietnamDateTime(dd.thoiGianDiemDanh);
                    final shiftName = AppFormatters.getShiftName(dd.buoiDiemDanh?.gioBatDau);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: statusColor.withOpacity(0.25), width: 1.2),
                      ),
                      child: InkWell(
                        onTap: () => AttendanceDetailModal.show(context, dd),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(methodIcon, color: statusColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Buổi ${dd.buoiDiemDanh?.soThuTuBuoi ?? "1"} • $shiftName',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeVN,
                                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withOpacity(0.35)),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Interactive Exam Ban Warning Card
  Widget _buildExamBanWarningCard({
    required int unexcusedAbsentCount,
    required int excusedAbsentCount,
    required int lateCount,
    required int totalCourseSessions,
    required double banRate,
  }) {
    Color cardBg;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;
    String advice;

    if (banRate >= 20.0) {
      // CẤM THI CHÍNH THỨC (>= 2 buổi không phép / 9 buổi = 22.2%)
      cardBg = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFCA5A5);
      textColor = const Color(0xFF991B1B);
      icon = Icons.block_rounded;
      title = 'CẤM THI CHÍNH THỨC! (Vắng không phép ${banRate.toStringAsFixed(1)}% >= 20%)';
      subtitle = 'Đã vắng $unexcusedAbsentCount/$totalCourseSessions buổi không phép.';
      advice = 'Không đủ điều kiện dự thi kết thúc học phần theo Quy chế tín chỉ HUTECH.';
    } else if (unexcusedAbsentCount >= 1) {
      // BÁO ĐỘNG NGUY CƠ (Vắng 1 buổi không phép / 9 buổi = 11.1%)
      cardBg = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFCD34D);
      textColor = const Color(0xFF92400E);
      icon = Icons.warning_amber_rounded;
      title = 'BÁO ĐỘNG NGUY CƠ CẤM THI! (Vắng KP ${banRate.toStringAsFixed(1)}%)';
      subtitle = 'Đã vắng $unexcusedAbsentCount/$totalCourseSessions buổi không phép${excusedAbsentCount > 0 ? " (Có $excusedAbsentCount buổi nghỉ có phép đã duyệt)" : ""}.';
      advice = 'CHỈ CÒN ĐƯỢC VẮNG 0 BUỔI! Học phần 9 buổi nếu vắng thêm 1 buổi không phép (tổng 2 buổi = 22.2%) sẽ bị CẤM THI.';
    } else if (lateCount > 0) {
      // ĐI TRỄ
      cardBg = const Color(0xFFFEFCE8);
      borderColor = const Color(0xFFFDE047);
      textColor = const Color(0xFF854D0E);
      icon = Icons.access_time_rounded;
      title = 'Cần Lưu Ý: Đã Có $lateCount Buổi Đi Trễ';
      subtitle = 'Điểm danh sau 07:30 ca sáng / sau 12:30 ca chiều.';
      advice = 'Hãy sắp xếp đi học đúng giờ để bảo đảm điểm rèn luyện và chuyên cần.';
    } else {
      // 100% ĐÚNG GIỜ
      cardBg = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFF86EFAC);
      textColor = const Color(0xFF166534);
      icon = Icons.verified_rounded;
      title = 'Chuyên Cần Xuất Sắc: 100% Đúng Giờ';
      subtitle = 'Chưa có buổi nào vắng hoặc đi trễ.';
      advice = 'Đủ 100% điều kiện tham gia kỳ thi kết thúc học phần.';
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentRiskWarningScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: textColor, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Khuyến nghị: $advice',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: textColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

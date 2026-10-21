import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../core/theme/app_theme.dart';

class StudentRiskWarningScreen extends StatelessWidget {
  const StudentRiskWarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final student = Provider.of<StudentProvider>(context);
    final sv = auth.currentUser?.sinhVien;

    final myHistory = student.myDiemDanhs;
    final unexcusedAbsentCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'vangkhongphep').length;
    final excusedAbsentCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'vangcophep').length;
    final lateCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'ditre').length;
    final presentCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'comat').length;

    // Quy định học phần LTDD: 9 buổi
    const constTotalBuoi = 9;
    // CHỈ VẮNG KHÔNG PHÉP MỚI TÍNH VÀO TỶ LỆ CẤM THI (VẮNG CÓ PHÉP KHÔNG BỊ TRỪ)
    final absencePercent = (unexcusedAbsentCount / constTotalBuoi * 100.0);
    final isBanned = absencePercent >= 20.0;
    final isDanger = !isBanned && unexcusedAbsentCount >= 1;
    final isLateOnly = !isBanned && !isDanger && unexcusedAbsentCount == 0 && lateCount > 0;

    final riskColor = isBanned
        ? AppTheme.dangerColor
        : (isDanger
            ? const Color(0xFFD97706)
            : (isLateOnly ? const Color(0xFFCA8A04) : AppTheme.successColor));

    final statusText = isBanned
        ? 'CẤM THI HỌC PHẦN (>= 20%)'
        : (isDanger
            ? 'BÁO ĐỘNG NGUY CƠ (11.1%)'
            : (isLateOnly ? 'LƯU Ý CÁC BUỔI ĐI TRỄ' : 'CHUYÊN CẦN XUẤT SẮC'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cảnh Báo Cấm Thi Cá Nhân'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            // Student Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: riskColor.withOpacity(0.3), width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: riskColor.withOpacity(0.12),
                      child: Icon(
                        isBanned
                            ? Icons.gpp_bad_rounded
                            : (isDanger
                                ? Icons.warning_amber_rounded
                                : (isLateOnly ? Icons.access_time_filled_rounded : Icons.verified_user_rounded)),
                        color: riskColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sv?.hoTen ?? auth.currentUser?.hoTen ?? 'Nguyễn Hữu Phúc',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'MSSV: ${sv?.maSV ?? "2380601738"}  •  Lớp: ${sv?.lop ?? "21DTH01"}',
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: riskColor.withOpacity(0.35)),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: riskColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Risk Gauge Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text(
                      'Tỷ Lệ Vắng Học Phần (Quy chế: 9 buổi)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: CircularProgressIndicator(
                            value: (absencePercent / 100.0).clamp(0.0, 1.0),
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${absencePercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                              ),
                            ),
                            Text(
                              'Tỷ lệ vắng',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildCounter('Đúng giờ', '$presentCount', AppTheme.successColor),
                        _buildCounter('Đi trễ', '$lateCount', AppTheme.warningColor),
                        _buildCounter('Vắng KP (Cấm thi)', '$unexcusedAbsentCount', AppTheme.dangerColor),
                        _buildCounter('Có phép (Đã duyệt)', '$excusedAbsentCount', const Color(0xFF0D9488)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Academic Rules & Advisory Card
            Card(
              color: const Color(0xFFF8FAFC),
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.gavel_rounded, color: AppTheme.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Quy Chế Tín Chỉ & Khuyến Nghị Học Vụ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    _buildRuleItem('≥ 20% (≥ 2 buổi):', 'Bị CẤM THI học phần theo Quy chế đào tạo tín chỉ HUTECH.'),
                    const SizedBox(height: 8),
                    _buildRuleItem('11.1% (1 buổi):', 'BÁO ĐỘNG NGUY CƠ, sinh viên chỉ còn được phép vắng thêm tối đa 0 buổi.'),
                    const SizedBox(height: 8),
                    _buildRuleItem('0 buổi vắng:', 'ĐỦ ĐIỀU KIỆN 100% tham gia kỳ thi kết thúc học phần.'),
                    const SizedBox(height: 8),
                    _buildRuleItem('Điểm danh đúng giờ:', 'Ca sáng trước 07:30 • Ca chiều trước 12:30. Sau giờ đó là đi trễ.'),
                    const SizedBox(height: 8),
                    _buildRuleItem('Vị trí phòng học:', 'Có mặt tại cơ sở HUTECH Thủ Đức (E1-04.05). Điểm danh sai vị trí sẽ bị ghi nhận Vắng.'),
                    const Divider(height: 18),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_rounded, color: AppTheme.warningColor, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lưu ý: Nếu ốm đau hoặc việc đột xuất, hãy nộp ngay "Đơn xin nghỉ phép" kèm ảnh chụp giấy khám bệnh để giảng viên duyệt và không bị tính vào tỷ lệ cấm thi!',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildRuleItem(String threshold, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(threshold, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
        const SizedBox(width: 6),
        Expanded(child: Text(desc, style: const TextStyle(fontSize: 12.5))),
      ],
    );
  }
}

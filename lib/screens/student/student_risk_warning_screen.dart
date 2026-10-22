import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/lop_hoc_phan_model.dart';
import '../../core/theme/app_theme.dart';

class StudentRiskWarningScreen extends StatefulWidget {
  final int? initialLopId;

  const StudentRiskWarningScreen({super.key, this.initialLopId});

  @override
  State<StudentRiskWarningScreen> createState() => _StudentRiskWarningScreenState();
}

class _StudentRiskWarningScreenState extends State<StudentRiskWarningScreen> {
  int? _selectedLopId;

  @override
  void initState() {
    super.initState();
    _selectedLopId = widget.initialLopId;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final student = Provider.of<StudentProvider>(context);
    final sv = auth.currentUser?.sinhVien;

    // Tự động gán môn học đầu tiên nếu chưa chọn
    if (_selectedLopId == null && student.myLopHocPhans.isNotEmpty) {
      _selectedLopId = student.myLopHocPhans.first.id;
    }

    final LopHocPhan? selectedLop = _selectedLopId != null && student.myLopHocPhans.any((l) => l.id == _selectedLopId)
        ? student.myLopHocPhans.firstWhere((l) => l.id == _selectedLopId)
        : (student.myLopHocPhans.isNotEmpty ? student.myLopHocPhans.first : null);

    final allHistory = student.myDiemDanhs;

    // Lọc lịch sử điểm danh theo đúng môn học đã chọn (tách biệt từng môn, không gộp chung)
    final myHistory = selectedLop != null
        ? allHistory.where((d) => (d.buoiDiemDanh?.lopHocPhanId == selectedLop.id || d.buoiDiemDanh?.lopHocPhan?.id == selectedLop.id)).toList()
        : allHistory;

    final unexcusedAbsentCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'vangkhongphep').length;
    final excusedAbsentCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'vangcophep').length;
    final lateCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'ditre').length;
    final presentCount = myHistory.where((d) => d.trangThai.toLowerCase() == 'comat').length;

    // Quy định số buổi theo môn học (LTDD: 9 buổi, môn khác: theo số buổi cấu hình)
    final constTotalBuoi = selectedLop != null ? (selectedLop.soBuoi > 0 ? selectedLop.soBuoi : 9) : 9;

    // CHỈ VẮNG KHÔNG PHÉP MỚI TÍNH VÀO TỶ LỆ CẤM THI CỦA MÔN NÀY (VẮNG CÓ PHÉP KHÔNG BỊ TRỪ)
    final absencePercent = constTotalBuoi > 0 ? (unexcusedAbsentCount / constTotalBuoi * 100.0) : 0.0;
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
            ? 'BÁO ĐỘNG NGUY CƠ (${absencePercent.toStringAsFixed(1)}%)'
            : (isLateOnly ? 'LƯU Ý CÁC BUỔI ĐI TRỄ' : 'CHUYÊN CẦN XUẤT SẮC'));

    final courseName = selectedLop?.monHoc?.tenMon ?? selectedLop?.maLopHocPhan ?? 'Học phần';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cảnh Báo Cấm Thi Cá Nhân'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            // 1. Student Info Card
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

            const SizedBox(height: 12),

            // 2. Course Selector Dropdown Card (Phân ra từng môn)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.school_rounded, color: AppTheme.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Chọn Môn Học Cần Khảo Sát:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (student.myLopHocPhans.isEmpty)
                      const Text('Chưa có danh sách lớp học phần.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedLopId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.class_rounded, color: AppTheme.primaryColor),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: student.myLopHocPhans.map((lop) {
                          return DropdownMenuItem<int>(
                            value: lop.id,
                            child: Text(
                              '${lop.maLopHocPhan} - ${lop.monHoc?.tenMon ?? lop.maLopHocPhan} (${lop.soBuoi} buổi)',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLopId = val);
                          }
                        },
                      ),
                    if (selectedLop != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'GV: ${selectedLop.giangVien ?? "Chưa phân công"}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Phòng: ${selectedLop.phongHoc ?? "E1-04.05"}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF)),
                            ),
                            Text(
                              'Quy định: $constTotalBuoi buổi',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. Risk Gauge Card for Selected Course
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      'Tỷ Lệ Vắng Môn: $courseName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quy định học phần: $constTotalBuoi buổi (Cấm thi khi vắng KP ≥ 20%)',
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
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
                              'Tỷ lệ vắng KP',
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

            // 4. Breakdown Table of ALL courses ("Môn nào cấm, môn nào không")
            if (student.myLopHocPhans.length > 1) ...[
              const SizedBox(height: 14),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assessment_rounded, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Phân Loại Cấm Thi Từng Môn Học (${student.myLopHocPhans.length} Môn):',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: student.myLopHocPhans.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, index) {
                          final lop = student.myLopHocPhans[index];
                          final isCurrent = lop.id == _selectedLopId;
                          final lopHistory = allHistory.where((d) => (d.buoiDiemDanh?.lopHocPhanId == lop.id || d.buoiDiemDanh?.lopHocPhan?.id == lop.id)).toList();
                          final lopVang = lopHistory.where((d) => d.trangThai.toLowerCase() == 'vangkhongphep').length;
                          final lopTotal = lop.soBuoi > 0 ? lop.soBuoi : 9;
                          final lopRate = lopTotal > 0 ? (lopVang / lopTotal * 100.0) : 0.0;
                          final isLopBanned = lopRate >= 20.0;
                          final isLopDanger = !isLopBanned && lopVang >= 1;
                          final lopBadgeColor = isLopBanned
                              ? AppTheme.dangerColor
                              : (isLopDanger ? const Color(0xFFD97706) : AppTheme.successColor);
                          final lopBadgeText = isLopBanned ? 'CẤM THI' : (isLopDanger ? 'BÁO ĐỘNG' : 'AN TOÀN');

                          return InkWell(
                            onTap: () {
                              setState(() => _selectedLopId = lop.id);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isCurrent ? AppTheme.primaryColor.withOpacity(0.06) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isCurrent ? Border.all(color: AppTheme.primaryColor.withOpacity(0.35)) : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isLopBanned ? Icons.block_rounded : (isLopDanger ? Icons.warning_amber_rounded : Icons.check_circle_rounded),
                                    color: lopBadgeColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${lop.maLopHocPhan} - ${lop.monHoc?.tenMon ?? "Môn học"}',
                                          style: TextStyle(
                                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 12.5,
                                            color: isCurrent ? AppTheme.primaryColor : AppTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Vắng KP: $lopVang/$lopTotal buổi (${lopRate.toStringAsFixed(1)}%) • GV: ${lop.giangVien ?? "N/A"}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: lopBadgeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: lopBadgeColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      lopBadgeText,
                                      style: TextStyle(
                                        color: lopBadgeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // 5. Academic Rules & Advisory Card
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
                    _buildRuleItem('≥ 20% số buổi:', 'Bị CẤM THI học phần theo Quy chế đào tạo tín chỉ HUTECH.'),
                    const SizedBox(height: 8),
                    _buildRuleItem('Báo động nguy cơ:', 'Đã vắng 1 buổi không phép, chỉ còn được vắng tối đa 0 buổi.'),
                    const SizedBox(height: 8),
                    _buildRuleItem('0 buổi vắng:', 'ĐỦ ĐIỀU KIỆN 100% tham gia kỳ thi kết thúc học phần.'),
                    const SizedBox(height: 8),
                    _buildRuleItem('Điểm danh đúng giờ:', 'Ca sáng trước 07:30 • Ca chiều trước 12:30. Sau giờ đó là đi trễ.'),
                    const SizedBox(height: 8),
                    _buildRuleItem('Vị trí phòng học:', 'Có mặt tại cơ sở HUTECH (E1-04.05). Điểm danh sai vị trí sẽ bị ghi nhận Vắng.'),
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
                              'Lưu ý: Nếu ốm đau hoặc có việc đột xuất, hãy nộp ngay "Đơn xin nghỉ phép" kèm ảnh chụp giấy khám bệnh để giảng viên duyệt và không bị tính vào tỷ lệ cấm thi!',
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

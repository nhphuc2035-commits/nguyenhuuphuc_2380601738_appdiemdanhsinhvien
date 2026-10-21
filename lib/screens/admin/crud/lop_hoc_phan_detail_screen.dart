import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/lop_hoc_phan_model.dart';
import '../../../models/sinh_vien_model.dart';
import '../../../core/theme/app_theme.dart';
import 'buoi_diem_danh_list_screen.dart';
import 'canh_bao_cam_thi_screen.dart';

class LopHocPhanDetailScreen extends StatefulWidget {
  final LopHocPhan lopHocPhan;

  const LopHocPhanDetailScreen({super.key, required this.lopHocPhan});

  @override
  State<LopHocPhanDetailScreen> createState() => _LopHocPhanDetailScreenState();
}

class _LopHocPhanDetailScreenState extends State<LopHocPhanDetailScreen> {
  List<SinhVien> _sinhViensInLop = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSinhViens();
  }

  Future<void> _loadSinhViens() async {
    setState(() => _isLoading = true);
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final list = await admin.fetchSinhViensInLop(widget.lopHocPhan.id);
    if (mounted) {
      setState(() {
        _sinhViensInLop = list;
        _isLoading = false;
      });
    }
  }

  void _showAddStudentModal() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    if (admin.sinhViens.isEmpty) {
      await admin.fetchSinhViens();
    }

    final currentIds = _sinhViensInLop.map((s) => s.id).toSet();
    final availableStudents = admin.sinhViens.where((s) => !currentIds.contains(s.id)).toList();

    if (!mounted) return;

    if (availableStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tất cả sinh viên đã có trong lớp hoặc chưa có thêm sinh viên')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thêm sinh viên vào lớp học phần',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Lớp: ${widget.lopHocPhan.maLopHocPhan}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: availableStudents.length,
                itemBuilder: (context, index) {
                  final sv = availableStudents[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(sv.hoTen.isNotEmpty ? sv.hoTen[0] : 'S')),
                    title: Text(sv.hoTen),
                    subtitle: Text('MSSV: ${sv.maSV} - Lớp: ${sv.lop ?? "N/A"}'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final ok = await admin.themSinhVienVaoLop(widget.lopHocPhan.id, sv.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Đã thêm ${sv.hoTen} vào lớp!'
                                  : (admin.errorMessage ?? 'Thêm thất bại')),
                              backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
                            ),
                          );
                          _loadSinhViens();
                        }
                      },
                      child: const Text('Thêm'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveStudent(SinhVien sv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa khỏi lớp'),
        content: Text('Xóa sinh viên ${sv.hoTen} khỏi lớp học phần ${widget.lopHocPhan.maLopHocPhan}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa khỏi lớp'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      final ok = await admin.xoaSinhVienKhoiLop(widget.lopHocPhan.id, sv.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã xóa ${sv.hoTen} khỏi lớp' : (admin.errorMessage ?? 'Xóa thất bại')),
            backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
          ),
        );
        _loadSinhViens();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lhp = widget.lopHocPhan;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết LHP: ${lhp.maLopHocPhan}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Info Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school_rounded, color: Color(0xFF7C3AED), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lhp.monHoc?.tenMon ?? 'Lớp học phần',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Mã LHP: ${lhp.maLopHocPhan}  •  ${lhp.soBuoi} buổi học',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DetailItem(label: 'Giảng viên', value: lhp.giangVien ?? 'N/A', icon: Icons.person_outline),
                      _DetailItem(label: 'Phòng học', value: lhp.phongHoc ?? 'N/A', icon: Icons.meeting_room_outlined),
                      _DetailItem(label: 'Học kỳ', value: '${lhp.hocKy ?? "HK1"} (${lhp.namHoc ?? "2026"})', icon: Icons.calendar_today_outlined),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                          label: const Text('Buổi điểm danh'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BuoiDiemDanhListScreen(lopHocPhanId: lhp.id),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
                          icon: const Icon(Icons.crisis_alert_rounded, size: 18),
                          label: const Text('Cảnh báo cấm thi'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CanhBaoCamThiScreen(initialLopId: lhp.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Students in Class Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sinh Viên Trong Lớp (${_sinhViensInLop.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Thêm SV'),
                    onPressed: _showAddStudentModal,
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_sinhViensInLop.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Chưa có sinh viên nào trong lớp học phần này.\nNhấn "Thêm SV" để thêm sinh viên vào lớp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sinhViensInLop.length,
                itemBuilder: (context, index) {
                  final sv = _sinhViensInLop[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      title: Text(sv.hoTen, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('MSSV: ${sv.maSV}  |  Lớp: ${sv.lop ?? "N/A"}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.dangerColor),
                        tooltip: 'Xóa khỏi lớp',
                        onPressed: () => _confirmRemoveStudent(sv),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

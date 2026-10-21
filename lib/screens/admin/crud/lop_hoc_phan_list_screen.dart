import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/lop_hoc_phan_model.dart';
import '../../../core/theme/app_theme.dart';
import 'lop_hoc_phan_detail_screen.dart';

class LopHocPhanListScreen extends StatefulWidget {
  const LopHocPhanListScreen({super.key});

  @override
  State<LopHocPhanListScreen> createState() => _LopHocPhanListScreenState();
}

class _LopHocPhanListScreenState extends State<LopHocPhanListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      admin.fetchLopHocPhans();
      admin.fetchMonHocs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([LopHocPhan? lhp]) {
    final isEdit = lhp != null;
    final admin = Provider.of<AdminProvider>(context, listen: false);

    final maLhpController = TextEditingController(text: lhp?.maLopHocPhan ?? '');
    final giangVienController = TextEditingController(text: lhp?.giangVien ?? 'ThS. Nguyễn Hữu Trung');
    final phongHocController = TextEditingController(text: lhp?.phongHoc ?? 'A-04.05');
    final hocKyController = TextEditingController(text: lhp?.hocKy ?? 'HK1');
    final namHocController = TextEditingController(text: lhp?.namHoc ?? '2026-2027');
    final soBuoiController = TextEditingController(text: (lhp?.soBuoi ?? 15).toString());

    int? selectedMonHocId = lhp?.monHocId ?? (admin.monHocs.isNotEmpty ? admin.monHocs.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Sửa lớp học phần' : 'Thêm lớp học phần mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: maLhpController,
                  decoration: const InputDecoration(labelText: 'Mã lớp HP *', hintText: 'VD: 24DTH01_LTDD'),
                ),
                const SizedBox(height: 10),

                // Mon Hoc Dropdown
                DropdownButtonFormField<int>(
                  value: selectedMonHocId,
                  decoration: const InputDecoration(labelText: 'Môn học *'),
                  items: admin.monHocs.map((m) {
                    return DropdownMenuItem<int>(
                      value: m.id,
                      child: Text('${m.maMon} - ${m.tenMon}', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedMonHocId = val;
                    });
                  },
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: giangVienController,
                  decoration: const InputDecoration(labelText: 'Giảng viên'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phongHocController,
                  decoration: const InputDecoration(labelText: 'Phòng học', hintText: 'A-04.05'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hocKyController,
                        decoration: const InputDecoration(labelText: 'Học kỳ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: soBuoiController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Số buổi'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: namHocController,
                  decoration: const InputDecoration(labelText: 'Năm học'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (maLhpController.text.trim().isEmpty || selectedMonHocId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập Mã lớp HP và chọn Môn học')),
                  );
                  return;
                }

                final item = LopHocPhan(
                  id: lhp?.id ?? 0,
                  maLopHocPhan: maLhpController.text.trim(),
                  monHocId: selectedMonHocId!,
                  giangVien: giangVienController.text.trim(),
                  phongHoc: phongHocController.text.trim(),
                  hocKy: hocKyController.text.trim(),
                  namHoc: namHocController.text.trim(),
                  soBuoi: int.tryParse(soBuoiController.text.trim()) ?? 15,
                );

                Navigator.pop(ctx);
                bool ok;
                if (isEdit) {
                  ok = await admin.updateLopHocPhan(lhp.id, item);
                } else {
                  ok = await admin.addLopHocPhan(item);
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? (isEdit ? 'Cập nhật thành công!' : 'Thêm lớp học phần thành công!')
                          : (admin.errorMessage ?? 'Thao tác thất bại')),
                      backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
                    ),
                  );
                }
              },
              child: Text(isEdit ? 'Lưu' : 'Thêm mới'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(LopHocPhan lhp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa lớp học phần'),
        content: Text('Bạn có chắc chắn muốn xóa lớp học phần ${lhp.maLopHocPhan}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      final ok = await admin.deleteLopHocPhan(lhp.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã xóa lớp học phần ${lhp.maLopHocPhan}' : (admin.errorMessage ?? 'Xóa thất bại')),
            backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final filtered = admin.lopHocPhans.where((l) {
      final q = _searchQuery.toLowerCase();
      return l.maLopHocPhan.toLowerCase().contains(q) ||
          (l.monHoc?.tenMon.toLowerCase().contains(q) ?? false) ||
          (l.giangVien?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Lớp Học Phần (CRUD)'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        tooltip: 'Thêm lớp học phần',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo mã lớp HP, tên môn, giảng viên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Tổng số: ${filtered.length} lớp học phần (Nhấn để xem SV trong lớp)',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: admin.isLoading && admin.lopHocPhans.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'Chưa có lớp học phần nào' : 'Không tìm thấy lớp học phần phù hợp',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final lhp = filtered[index];
                          return Card(
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LopHocPhanDetailScreen(lopHocPhan: lhp),
                                  ),
                                );
                              },
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.class_rounded, color: Color(0xFF7C3AED)),
                              ),
                              title: Text(
                                lhp.maLopHocPhan,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${lhp.monHoc?.tenMon ?? "Môn học"}\nGV: ${lhp.giangVien ?? "N/A"}  •  Phòng: ${lhp.phongHoc ?? "N/A"}  •  ${lhp.soBuoi} buổi',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                                    onPressed: () => _showAddEditDialog(lhp),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
                                    onPressed: () => _confirmDelete(lhp),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

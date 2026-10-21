import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/sinh_vien_model.dart';
import '../../../core/theme/app_theme.dart';

class SinhVienListScreen extends StatefulWidget {
  const SinhVienListScreen({super.key});

  @override
  State<SinhVienListScreen> createState() => _SinhVienListScreenState();
}

class _SinhVienListScreenState extends State<SinhVienListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchSinhViens();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([SinhVien? sv]) {
    final isEdit = sv != null;
    final maSvController = TextEditingController(text: sv?.maSV ?? '');
    final hoTenController = TextEditingController(text: sv?.hoTen ?? '');
    final emailController = TextEditingController(text: sv?.email ?? '');
    final sdtController = TextEditingController(text: sv?.soDienThoai ?? '');
    final lopController = TextEditingController(text: sv?.lop ?? '21DTH01');
    final khoaController = TextEditingController(text: sv?.khoa ?? 'Công nghệ thông tin');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Sửa thông tin sinh viên' : 'Thêm sinh viên mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: maSvController,
                decoration: const InputDecoration(labelText: 'Mã SV (MSSV) *'),
                readOnly: isEdit,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hoTenController,
                decoration: const InputDecoration(labelText: 'Họ và tên *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email sinh viên'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lopController,
                decoration: const InputDecoration(labelText: 'Lớp'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: khoaController,
                decoration: const InputDecoration(labelText: 'Khoa'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sdtController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (maSvController.text.trim().isEmpty || hoTenController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập MSSV và Họ tên')),
                );
                return;
              }

              final admin = Provider.of<AdminProvider>(context, listen: false);
              final newSv = SinhVien(
                id: sv?.id ?? 0,
                maSV: maSvController.text.trim(),
                hoTen: hoTenController.text.trim(),
                email: emailController.text.trim(),
                lop: lopController.text.trim(),
                khoa: khoaController.text.trim(),
                soDienThoai: sdtController.text.trim(),
              );

              Navigator.pop(ctx);
              bool ok;
              if (isEdit) {
                ok = await admin.updateSinhVien(sv.id, newSv);
              } else {
                ok = await admin.addSinhVien(newSv);
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? (isEdit ? 'Cập nhật thành công!' : 'Thêm sinh viên thành công!')
                        : (admin.errorMessage ?? 'Thao tác thất bại')),
                    backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
                  ),
                );
              }
            },
            child: Text(isEdit ? 'Lưu thay đổi' : 'Thêm mới'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(SinhVien sv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa sinh viên'),
        content: Text('Bạn có chắc chắn muốn xóa sinh viên ${sv.hoTen} (${sv.maSV})?'),
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
      final ok = await admin.deleteSinhVien(sv.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã xóa sinh viên ${sv.hoTen}' : (admin.errorMessage ?? 'Xóa thất bại')),
            backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final filtered = admin.sinhViens.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.hoTen.toLowerCase().contains(q) ||
          s.maSV.toLowerCase().contains(q) ||
          (s.lop?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Sinh Viên (CRUD)'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        tooltip: 'Thêm sinh viên mới',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, MSSV, lớp...',
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

          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng cộng: ${filtered.length} sinh viên',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: admin.isLoading && admin.sinhViens.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'Chưa có sinh viên nào' : 'Không tìm thấy kết quả phù hợp',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final sv = filtered[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                                child: Text(
                                  sv.hoTen.isNotEmpty ? sv.hoTen[0].toUpperCase() : 'S',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              title: Text(
                                sv.hoTen,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'MSSV: ${sv.maSV}  |  Lớp: ${sv.lop ?? "N/A"}\nEmail: ${sv.email ?? "Chưa có"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                                    tooltip: 'Sửa',
                                    onPressed: () => _showAddEditDialog(sv),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
                                    tooltip: 'Xóa',
                                    onPressed: () => _confirmDelete(sv),
                                  ),
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

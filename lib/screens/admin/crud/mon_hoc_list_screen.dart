import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/mon_hoc_model.dart';
import '../../../core/theme/app_theme.dart';

class MonHocListScreen extends StatefulWidget {
  const MonHocListScreen({super.key});

  @override
  State<MonHocListScreen> createState() => _MonHocListScreenState();
}

class _MonHocListScreenState extends State<MonHocListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchMonHocs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([MonHoc? mh]) {
    final isEdit = mh != null;
    final maMonController = TextEditingController(text: mh?.maMon ?? '');
    final tenMonController = TextEditingController(text: mh?.tenMon ?? '');
    final tinChiController = TextEditingController(text: (mh?.soTinChi ?? 3).toString());
    final moTaController = TextEditingController(text: mh?.moTa ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Sửa thông tin môn học' : 'Thêm môn học mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: maMonController,
                decoration: const InputDecoration(labelText: 'Mã môn học *', hintText: 'VD: LTDD01'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tenMonController,
                decoration: const InputDecoration(labelText: 'Tên môn học *', hintText: 'VD: Lập trình di động'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tinChiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tín chỉ *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: moTaController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Mô tả môn học'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (maMonController.text.trim().isEmpty || tenMonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập đầy đủ mã môn và tên môn')),
                );
                return;
              }

              final admin = Provider.of<AdminProvider>(context, listen: false);
              final item = MonHoc(
                id: mh?.id ?? 0,
                maMon: maMonController.text.trim(),
                tenMon: tenMonController.text.trim(),
                soTinChi: int.tryParse(tinChiController.text.trim()) ?? 3,
                moTa: moTaController.text.trim(),
              );

              Navigator.pop(ctx);
              bool ok;
              if (isEdit) {
                ok = await admin.updateMonHoc(mh.id, item);
              } else {
                ok = await admin.addMonHoc(item);
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? (isEdit ? 'Cập nhật môn học thành công!' : 'Thêm môn học thành công!')
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
    );
  }

  void _confirmDelete(MonHoc mh) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa môn học'),
        content: Text('Bạn có chắc chắn muốn xóa môn học "${mh.tenMon}" (${mh.maMon})?'),
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
      final ok = await admin.deleteMonHoc(mh.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã xóa môn học "${mh.tenMon}"' : (admin.errorMessage ?? 'Xóa thất bại')),
            backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final filtered = admin.monHocs.where((m) {
      final q = _searchQuery.toLowerCase();
      return m.tenMon.toLowerCase().contains(q) || m.maMon.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Môn Học (CRUD)'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        tooltip: 'Thêm môn học',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên môn, mã môn...',
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
                  'Tổng số: ${filtered.length} môn học',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: admin.isLoading && admin.monHocs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'Chưa có môn học nào' : 'Không tìm thấy môn học phù hợp',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final mh = filtered[index];
                          return Card(
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0D9488)),
                              ),
                              title: Text(
                                mh.tenMon,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Mã: ${mh.maMon}  •  ${mh.soTinChi} Tín chỉ\n${mh.moTa ?? "Không có mô tả"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                                    onPressed: () => _showAddEditDialog(mh),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
                                    onPressed: () => _confirmDelete(mh),
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

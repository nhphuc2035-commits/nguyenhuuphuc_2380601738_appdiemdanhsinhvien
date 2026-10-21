import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/diem_danh_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../widgets/attendance_detail_modal.dart';

class DiemDanhManagementScreen extends StatefulWidget {
  final int? buoiId;

  const DiemDanhManagementScreen({super.key, this.buoiId});

  @override
  State<DiemDanhManagementScreen> createState() => _DiemDanhManagementScreenState();
}

class _DiemDanhManagementScreenState extends State<DiemDanhManagementScreen> {
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchDiemDanhs(buoiId: widget.buoiId);
    });
  }

  void _showEditStatusDialog(DiemDanh dd) {
    String currentStatus = dd.trangThai;
    final ghiChuController = TextEditingController(text: dd.ghiChu ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Sửa điểm danh: ${dd.sinhVien?.hoTen ?? "Sinh viên"}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: currentStatus == 'Vang' ? 'VangKhongPhep' : currentStatus,
                decoration: const InputDecoration(labelText: 'Trạng thái điểm danh'),
                items: const [
                  DropdownMenuItem(value: 'CoMat', child: Text('Có mặt đúng giờ')),
                  DropdownMenuItem(value: 'DiTre', child: Text('Đi trễ (Quá 07:30 / 12:30)')),
                  DropdownMenuItem(value: 'VangKhongPhep', child: Text('Vắng không phép')),
                  DropdownMenuItem(value: 'VangCoPhep', child: Text('Vắng có phép')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => currentStatus = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ghiChuController,
                decoration: const InputDecoration(labelText: 'Ghi chú học vụ / Nhận xét'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final admin = Provider.of<AdminProvider>(context, listen: false);
                final updated = DiemDanh(
                  id: dd.id,
                  buoiDiemDanhId: dd.buoiDiemDanhId,
                  sinhVienId: dd.sinhVienId,
                  thoiGianDiemDanh: dd.thoiGianDiemDanh,
                  phuongThuc: dd.phuongThuc,
                  viTriViDo: dd.viTriViDo,
                  viTriKinhDo: dd.viTriKinhDo,
                  khoangCachMet: dd.khoangCachMet,
                  trangThai: currentStatus,
                  hopLe: currentStatus == 'CoMat' || currentStatus == 'DiTre',
                  ghiChu: ghiChuController.text.trim(),
                );

                final ok = await admin.updateDiemDanh(dd.id, updated);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Cập nhật điểm danh thành công!' : (admin.errorMessage ?? 'Thất bại')),
                      backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(DiemDanh dd) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xác nhận xóa bản ghi'),
        content: Text('Xóa bản ghi điểm danh của sinh viên ${dd.sinhVien?.hoTen ?? "này"}?'),
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
      final ok = await admin.deleteDiemDanh(dd.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã xóa bản ghi' : (admin.errorMessage ?? 'Xóa thất bại')),
            backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final filtered = admin.diemDanhs.where((d) {
      if (_statusFilter == 'All') return true;
      if (_statusFilter == 'Vang') {
        return d.trangThai.toLowerCase().contains('vang');
      }
      return d.trangThai.toLowerCase() == _statusFilter.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.buoiId != null ? 'Điểm Danh Buổi #${widget.buoiId}' : 'Quản Lý Điểm Danh'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'Tất cả (${admin.diemDanhs.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('CoMat', 'Đúng giờ'),
                const SizedBox(width: 8),
                _buildFilterChip('DiTre', 'Đi trễ'),
                const SizedBox(width: 8),
                _buildFilterChip('Vang', 'Vắng'),
                const SizedBox(width: 8),
                _buildFilterChip('VangCoPhep', 'Có phép'),
              ],
            ),
          ),

          Expanded(
            child: admin.isLoading && admin.diemDanhs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có dữ liệu điểm danh nào trong danh mục này.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final dd = filtered[index];
                          final sv = dd.sinhVien;
                          final statusColor = AppFormatters.getStatusColor(dd.trangThai);
                          final statusLabel = AppFormatters.getStatusLabel(dd.trangThai);
                          final methodIcon = AppFormatters.getMethodIcon(dd.phuongThuc);
                          final methodLabel = AppFormatters.getMethodLabel(dd.phuongThuc);
                          final timeVN = AppFormatters.formatVietnamDateTime(dd.thoiGianDiemDanh);

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: statusColor.withOpacity(0.25), width: 1.2),
                            ),
                            child: InkWell(
                              onTap: () => AttendanceDetailModal.show(context, dd),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: statusColor.withOpacity(0.12),
                                      child: Icon(methodIcon, color: statusColor, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  sv?.hoTen ?? 'Sinh viên #${dd.sinhVienId}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: statusColor.withOpacity(0.35)),
                                                ),
                                                child: Text(
                                                  statusLabel,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'MSSV: ${sv?.maSV ?? "N/A"}  •  Lớp: ${sv?.lop ?? "21DTH01"}',
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$methodLabel • ${dd.khoangCachMet != null ? "${dd.khoangCachMet!.toStringAsFixed(1)}m" : "N/A"}\nThời gian: $timeVN',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                                          ),
                                          if (dd.ghiChu != null && dd.ghiChu!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                'Ghi chú: ${dd.ghiChu}',
                                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                                          tooltip: 'Sửa trạng thái',
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showEditStatusDialog(dd),
                                        ),
                                        const SizedBox(height: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor, size: 20),
                                          tooltip: 'Xóa bản ghi',
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _confirmDelete(dd),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _statusFilter = value);
      },
    );
  }
}

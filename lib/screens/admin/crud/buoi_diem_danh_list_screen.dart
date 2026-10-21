import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/buoi_diem_danh_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import 'diem_danh_management_screen.dart';

class BuoiDiemDanhListScreen extends StatefulWidget {
  final int? lopHocPhanId;

  const BuoiDiemDanhListScreen({super.key, this.lopHocPhanId});

  @override
  State<BuoiDiemDanhListScreen> createState() => _BuoiDiemDanhListScreenState();
}

class _BuoiDiemDanhListScreenState extends State<BuoiDiemDanhListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      admin.fetchBuoiDiemDanhs(lopHocPhanId: widget.lopHocPhanId);
      admin.fetchLopHocPhans();
    });
  }

  void _showQrCodeModal(BuoiDiemDanh buoi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mã QR: Buổi ${buoi.soThuTuBuoi}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              buoi.lopHocPhan?.maLopHocPhan ?? 'Lớp học phần',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Trạng thái: ${buoi.trangThai}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: buoi.isMo ? AppTheme.successColor : AppTheme.dangerColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: buoi.maQRCode ?? 'QR_BUOI_${buoi.id}',
                version: QrVersions.auto,
                size: 220,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mã: ${buoi.maQRCode ?? "N/A"}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 4),
            Text(
              'Tọa độ: (${buoi.viTriViDo}, ${buoi.viTriKinhDo}) • Bán kính: ${buoi.banKinhChoPhepMet}m',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog([BuoiDiemDanh? buoi]) {
    final isEdit = buoi != null;
    final admin = Provider.of<AdminProvider>(context, listen: false);

    int? selectedLopId = buoi?.lopHocPhanId ??
        widget.lopHocPhanId ??
        (admin.lopHocPhans.isNotEmpty ? admin.lopHocPhans.first.id : null);

    final soBuoiController = TextEditingController(text: (buoi?.soThuTuBuoi ?? 1).toString());
    final ngayController = TextEditingController(
      text: buoi?.ngayDiemDanh.split('T').first ?? DateTime.now().toString().split(' ').first,
    );
    final gioBatDauController = TextEditingController(text: buoi?.gioBatDau ?? '07:30:00');
    final gioKetThucController = TextEditingController(text: buoi?.gioKetThuc ?? '11:30:00');
    final maQrController = TextEditingController(
      text: buoi?.maQRCode ?? 'QR_HUTECH_BUOI_${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
    final viDoController = TextEditingController(text: (buoi?.viTriViDo ?? 10.8018).toString());
    final kinhDoController = TextEditingController(text: (buoi?.viTriKinhDo ?? 106.7142).toString());
    final banKinhController = TextEditingController(text: (buoi?.banKinhChoPhepMet ?? 100.0).toString());
    String trangThai = buoi?.trangThai ?? 'Mo';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Sửa buổi điểm danh' : 'Tạo buổi điểm danh mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedLopId,
                  decoration: const InputDecoration(labelText: 'Lớp học phần *'),
                  items: admin.lopHocPhans.map((l) {
                    return DropdownMenuItem<int>(
                      value: l.id,
                      child: Text(l.maLopHocPhan, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedLopId = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: soBuoiController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Buổi thứ *'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: ngayController,
                        decoration: const InputDecoration(labelText: 'Ngày (YYYY-MM-DD)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: gioBatDauController,
                        decoration: const InputDecoration(labelText: 'Giờ bắt đầu'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: gioKetThucController,
                        decoration: const InputDecoration(labelText: 'Giờ kết thúc'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: maQrController,
                  decoration: const InputDecoration(labelText: 'Mã QR Code *'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: viDoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'GPS Vĩ độ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: kinhDoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'GPS Kinh độ'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: banKinhController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bán kính hợp lệ (mét)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: trangThai,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: const [
                    DropdownMenuItem(value: 'Mo', child: Text('Mở điểm danh')),
                    DropdownMenuItem(value: 'Dong', child: Text('Đóng điểm danh')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => trangThai = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (selectedLopId == null || soBuoiController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đủ thông tin bắt buộc')),
                  );
                  return;
                }

                final item = BuoiDiemDanh(
                  id: buoi?.id ?? 0,
                  lopHocPhanId: selectedLopId!,
                  soThuTuBuoi: int.tryParse(soBuoiController.text.trim()) ?? 1,
                  ngayDiemDanh: ngayController.text.trim(),
                  gioBatDau: gioBatDauController.text.trim(),
                  gioKetThuc: gioKetThucController.text.trim(),
                  maQRCode: maQrController.text.trim(),
                  viTriViDo: double.tryParse(viDoController.text.trim()) ?? 10.8018,
                  viTriKinhDo: double.tryParse(kinhDoController.text.trim()) ?? 106.7142,
                  banKinhChoPhepMet: double.tryParse(banKinhController.text.trim()) ?? 100.0,
                  trangThai: trangThai,
                );

                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                bool ok;
                if (isEdit) {
                  ok = await admin.updateBuoiDiemDanh(buoi.id, item);
                } else {
                  ok = await admin.addBuoiDiemDanh(item);
                }

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? (isEdit ? 'Cập nhật thành công!' : 'Tạo buổi điểm danh thành công!')
                        : (admin.errorMessage ?? 'Thao tác thất bại')),
                    backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
                  ),
                );
              },
              child: Text(isEdit ? 'Lưu' : 'Tạo buổi'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuoiDiemDanh buoi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa buổi điểm danh'),
        content: Text('Bạn có chắc chắn muốn xóa Buổi ${buoi.soThuTuBuoi} này?'),
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
      final ok = await admin.deleteBuoiDiemDanh(buoi.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã xóa buổi điểm danh' : (admin.errorMessage ?? 'Xóa thất bại')),
            backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lopHocPhanId != null
            ? 'Buổi Điểm Danh LHP #${widget.lopHocPhanId}'
            : 'Quản Lý Buổi Điểm Danh (CRUD)'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        tooltip: 'Thêm buổi điểm danh',
        child: const Icon(Icons.add),
      ),
      body: admin.isLoading && admin.buoiDiemDanhs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : admin.buoiDiemDanhs.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có buổi điểm danh nào.\nNhấn nút + để tạo buổi điểm danh mới.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: admin.buoiDiemDanhs.length,
                  itemBuilder: (context, index) {
                    final buoi = admin.buoiDiemDanhs[index];
                    final isMo = buoi.isMo;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isMo
                                        ? AppTheme.successColor.withOpacity(0.12)
                                        : AppTheme.dangerColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isMo ? 'ĐANG MỞ' : 'ĐÃ ĐÓNG',
                                    style: TextStyle(
                                      color: isMo ? AppTheme.successColor : AppTheme.dangerColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Buổi ${buoi.soThuTuBuoi}: ${buoi.lopHocPhan?.maLopHocPhan ?? "Lớp HP"}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                Switch(
                                  value: isMo,
                                  onChanged: (val) async {
                                    await admin.toggleDongMoBuoi(buoi.id);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ngày: ${AppFormatters.formatVietnamDate(buoi.ngayDiemDanh)}  •  ${AppFormatters.getShiftName(buoi.gioBatDau)}\nQuy định: ${buoi.gioBatDau ?? "07:30"} - ${buoi.gioKetThuc ?? "11:30"}  •  Bán kính: ${buoi.banKinhChoPhepMet}m',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                            ),
                            const Divider(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                                  label: const Text('Mã QR', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _showQrCodeModal(buoi),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.list_alt_rounded, size: 16),
                                  label: const Text('DS Điểm danh', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DiemDanhManagementScreen(buoiId: buoi.id),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                                  tooltip: 'Chỉnh sửa buổi',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _showAddEditDialog(buoi),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor, size: 20),
                                  tooltip: 'Xóa buổi',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _confirmDelete(buoi),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

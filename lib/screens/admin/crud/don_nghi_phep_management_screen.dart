import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/don_nghi_phep_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/theme/app_theme.dart';

class DonNghiPhepManagementScreen extends StatefulWidget {
  const DonNghiPhepManagementScreen({super.key});

  @override
  State<DonNghiPhepManagementScreen> createState() => _DonNghiPhepManagementScreenState();
}

class _DonNghiPhepManagementScreenState extends State<DonNghiPhepManagementScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchDonNghiPheps();
    });
  }

  void _showDuyetDialog(DonNghiPhep don) {
    String trangThai = don.trangThai.toLowerCase() == 'tuchoi' ? 'TuChoi' : 'DaDuyet';
    final phanHoiController = TextEditingController(
      text: don.phanHoiGiaoVien ??
          (trangThai == 'DaDuyet'
              ? 'Đã chấp thuận đơn xin nghỉ phép của sinh viên.'
              : 'Từ chối do minh chứng chưa hợp lệ hoặc thiếu thông tin.'),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.fact_check_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Duyệt đơn: ${don.sinhVien?.hoTen ?? "Sinh viên"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MSSV: ${don.sinhVien?.maSV ?? "N/A"} • Lớp: ${don.lopHocPhan?.maLopHocPhan ?? "N/A"}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngày nghỉ: ${don.ngayNghi.split("T").first}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lý do: ${don.lyDo}',
                        style: const TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quyết định của Giảng viên:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setDialogState(() {
                            trangThai = 'DaDuyet';
                            phanHoiController.text = 'Đã chấp thuận đơn xin nghỉ phép của sinh viên.';
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: trangThai == 'DaDuyet'
                                ? AppTheme.successColor.withOpacity(0.12)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: trangThai == 'DaDuyet'
                                  ? AppTheme.successColor
                                  : Colors.grey.shade300,
                              width: trangThai == 'DaDuyet' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: trangThai == 'DaDuyet' ? AppTheme.successColor : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Chấp thuận',
                                style: TextStyle(
                                  color: trangThai == 'DaDuyet' ? AppTheme.successColor : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setDialogState(() {
                            trangThai = 'TuChoi';
                            phanHoiController.text = 'Từ chối do minh chứng chưa hợp lệ hoặc thiếu thông tin.';
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: trangThai == 'TuChoi'
                                ? AppTheme.dangerColor.withOpacity(0.12)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: trangThai == 'TuChoi'
                                  ? AppTheme.dangerColor
                                  : Colors.grey.shade300,
                              width: trangThai == 'TuChoi' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cancel_rounded,
                                size: 18,
                                color: trangThai == 'TuChoi' ? AppTheme.dangerColor : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Từ chối',
                                style: TextStyle(
                                  color: trangThai == 'TuChoi' ? AppTheme.dangerColor : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phanHoiController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Lời nhắn phản hồi giảng viên',
                    hintText: 'Nhập phản hồi gửi tới sinh viên...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: trangThai == 'DaDuyet' ? AppTheme.successColor : AppTheme.dangerColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final admin = Provider.of<AdminProvider>(context, listen: false);
                final ok = await admin.duyetDonNghiPhep(
                  don.id,
                  trangThai: trangThai,
                  phanHoi: phanHoiController.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Đã xử lý quyết định duyệt đơn!' : (admin.errorMessage ?? 'Xử lý thất bại')),
                      backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
                    ),
                  );
                }
              },
              child: const Text('Xác nhận lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(String url) {
    final fullUrl = url.startsWith('http') ? url : '${ApiConstants.baseUrl}$url';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Minh chứng đơn nghỉ phép', style: TextStyle(fontSize: 16)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Image.network(
                fullUrl,
                headers: const {'ngrok-skip-browser-warning': 'true'},
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Text('Không thể tải ảnh minh chứng hoặc ảnh mẫu cục bộ'),
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

  void _confirmDelete(DonNghiPhep don) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa đơn'),
        content: Text('Xóa đơn nghỉ phép của sinh viên ${don.sinhVien?.hoTen ?? "này"}?'),
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
      final ok = await admin.deleteDonNghiPhep(don.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã xóa đơn nghỉ phép' : (admin.errorMessage ?? 'Xóa thất bại')),
            backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final filtered = admin.donNghiPheps.where((d) {
      if (_filter == 'All') return true;
      return d.trangThai.toLowerCase() == _filter.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt Đơn Nghỉ Phép (CRUD)'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'Tất cả (${admin.donNghiPheps.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('ChoDuyet', 'Chờ duyệt'),
                const SizedBox(width: 8),
                _buildFilterChip('DaDuyet', 'Đã duyệt'),
                const SizedBox(width: 8),
                _buildFilterChip('TuChoi', 'Từ chối'),
              ],
            ),
          ),

          Expanded(
            child: admin.isLoading && admin.donNghiPheps.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có đơn nghỉ phép nào trong danh mục này.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final don = filtered[index];
                          final sv = don.sinhVien;
                          final statusColor = _getStatusColor(don.trangThai);
                          final isPending = don.trangThai.toLowerCase() == 'choduyet';
                          final dateVN = AppFormatters.formatVietnamDate(don.ngayNghi);
                          final initials = (sv?.hoTen != null && sv!.hoTen.trim().isNotEmpty)
                              ? sv.hoTen.trim().split(' ').last[0].toUpperCase()
                              : 'S';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Header with Avatar, Name, MSSV, Class & Status Chip
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: statusColor.withOpacity(0.15),
                                        child: Text(
                                          initials,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sv?.hoTen ?? 'Sinh viên #${don.sinhVienId}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'MSSV: ${sv?.maSV ?? "N/A"}  •  Lớp: ${don.lopHocPhan?.maLopHocPhan ?? "N/A"}',
                                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getStatusIcon(don.trangThai),
                                              size: 13,
                                              color: statusColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatStatus(don.trangThai),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // 2. Info Box: Leave Date & Clean Reason
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.event_available_rounded, size: 16, color: AppTheme.primaryColor),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Ngày xin nghỉ: $dateVN',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Lý do: ${don.lyDo}',
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.35),
                                        ),
                                        if (don.phanHoiGiaoVien != null && don.phanHoiGiaoVien!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFBFDBFE)),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.comment_rounded, size: 14, color: AppTheme.primaryColor),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Lời nhắn GV: ${don.phanHoiGiaoVien}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF1D4ED8),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // 3. Evidence Image Button (If provided by student)
                                  if (don.minhChungUrl != null && don.minhChungUrl!.isNotEmpty) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF0284C7),
                                          side: const BorderSide(color: Color(0xFFBAE6FD)),
                                          backgroundColor: const Color(0xFFF0F9FF),
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.image_search_rounded, size: 17),
                                        label: const Text(
                                          'Xem ảnh minh chứng kèm theo',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                        ),
                                        onPressed: () => _showImagePreview(don.minhChungUrl!),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],

                                  // 4. Action Row (Approve/Update + Delete)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isPending
                                                ? AppTheme.primaryColor
                                                : const Color(0xFF475569),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 11),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                          ),
                                          icon: Icon(
                                            isPending ? Icons.fact_check_rounded : Icons.edit_note_rounded,
                                            size: 18,
                                          ),
                                          label: Text(
                                            isPending ? 'Duyệt / Xử Lý Đơn' : 'Cập Nhật Quyết Định',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () => _showDuyetDialog(don),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFFECACA)),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerColor, size: 21),
                                          tooltip: 'Xóa đơn',
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _confirmDelete(don),
                                        ),
                                      ),
                                    ],
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'choduyet':
        return Icons.pending_actions_rounded;
      case 'daduyet':
        return Icons.check_circle_rounded;
      case 'tuchoi':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _filter = value);
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'choduyet':
        return AppTheme.warningColor;
      case 'daduyet':
        return AppTheme.successColor;
      case 'tuchoi':
        return AppTheme.dangerColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'choduyet':
        return 'Chờ duyệt';
      case 'daduyet':
        return 'Đã duyệt';
      case 'tuchoi':
        return 'Từ chối';
      default:
        return status;
    }
  }
}

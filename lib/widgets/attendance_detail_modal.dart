import 'package:flutter/material.dart';
import '../models/diem_danh_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_formatter.dart';

class AttendanceDetailModal extends StatelessWidget {
  final DiemDanh item;

  const AttendanceDetailModal({super.key, required this.item});

  static void show(BuildContext context, DiemDanh item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttendanceDetailModal(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppFormatters.getStatusColor(item.trangThai);
    final statusLabel = AppFormatters.getStatusLabel(item.trangThai);
    final statusIcon = AppFormatters.getStatusIcon(item.trangThai);
    final methodLabel = AppFormatters.getMethodLabel(item.phuongThuc);
    final methodIcon = AppFormatters.getMethodIcon(item.phuongThuc);
    final timeVN = AppFormatters.formatVietnamDateTime(item.thoiGianDiemDanh);
    final shiftName = AppFormatters.getShiftName(item.buoiDiemDanh?.gioBatDau);
    final shiftRule = AppFormatters.getShiftRule(item.buoiDiemDanh?.gioBatDau);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi Tiết Bản Ghi Điểm Danh',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Buổi ${item.buoiDiemDanh?.soThuTuBuoi ?? "1"} • ${item.buoiDiemDanh?.lopHocPhan?.maLopHocPhan ?? "Lớp học phần"}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.hopLe ? 'Điểm danh hợp lệ' : 'Không hợp lệ / Vắng',
                                style: TextStyle(
                                  color: statusColor.withOpacity(0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Detail section
                  _buildDetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Thời gian điểm danh (Giờ VN):',
                    value: timeVN,
                    highlight: true,
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Ca học & Giờ quy định:',
                    value: '$shiftName\n($shiftRule)',
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    icon: methodIcon,
                    label: 'Phương thức xác thực:',
                    value: methodLabel,
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    icon: Icons.meeting_room_rounded,
                    label: 'Phòng học:',
                    value: item.buoiDiemDanh?.lopHocPhan?.phongHoc ?? 'A-04.05 (HUTECH)',
                  ),
                  const SizedBox(height: 12),



                  if (item.ghiChu != null && item.ghiChu!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.place_rounded, size: 18, color: Color(0xFFEA580C)),
                              SizedBox(width: 6),
                              Text(
                                'Địa điểm / Vị trí thực tế ghi nhận:',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9A3412),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.ghiChu!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7C2D12),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (item.lyDoKhongHopLe != null && item.lyDoKhongHopLe!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 18, color: AppTheme.dangerColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lý do: ${item.lyDoKhongHopLe!}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Đóng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (highlight ? AppTheme.primaryColor : Colors.grey.shade600).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: highlight ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                  color: highlight ? AppTheme.primaryColor : AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

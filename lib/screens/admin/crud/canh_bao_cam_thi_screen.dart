import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/canh_bao_cam_thi_model.dart';
import '../../../core/theme/app_theme.dart';

class CanhBaoCamThiScreen extends StatefulWidget {
  final int? initialLopId;

  const CanhBaoCamThiScreen({super.key, this.initialLopId});

  @override
  State<CanhBaoCamThiScreen> createState() => _CanhBaoCamThiScreenState();
}

class _CanhBaoCamThiScreenState extends State<CanhBaoCamThiScreen> {
  int? _selectedLopId;

  @override
  void initState() {
    super.initState();
    _selectedLopId = widget.initialLopId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      if (admin.lopHocPhans.isEmpty) {
        await admin.fetchLopHocPhans();
      }
      if (_selectedLopId == null && admin.lopHocPhans.isNotEmpty) {
        _selectedLopId = admin.lopHocPhans.first.id;
      }
      if (_selectedLopId != null) {
        admin.fetchCanhBaoCamThi(_selectedLopId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final data = admin.canhBaoCamThi;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cảnh Báo Cấm Thi Tự Động'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedLopId != null) {
                admin.fetchCanhBaoCamThi(_selectedLopId!);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown Selector Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn Lớp Học Phần Khảo Sát:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedLopId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                      items: admin.lopHocPhans.map((l) {
                        return DropdownMenuItem<int>(
                          value: l.id,
                          child: Text(
                            '${l.maLopHocPhan} - ${l.monHoc?.tenMon ?? "Môn học"}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedLopId = val);
                          admin.fetchCanhBaoCamThi(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Regulation Notice Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_rounded, color: Color(0xFF1D4ED8), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Theo Quy chế đào tạo tín chỉ: Sinh viên vắng từ 20% số buổi trở lên sẽ bị CẤM THI kết thúc học phần. Vắng từ 13% được xếp vào diện BÁO ĐỘNG NGUY CƠ.',
                      style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (admin.isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (data == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Vui lòng chọn lớp học phần để phân tích nguy cơ.')),
              )
            else ...[
              // Summary Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _RiskStatCard(
                      title: 'Tổng Sinh Viên',
                      value: '${data.tongSinhVien}',
                      color: AppTheme.primaryColor,
                      icon: Icons.people_alt,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RiskStatCard(
                      title: 'Buổi Đã Học',
                      value: '${data.tongBuoiDaDiemDanh}',
                      color: const Color(0xFF0D9488),
                      icon: Icons.event_available,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RiskStatCard(
                      title: 'Nguy Cơ (≥13%)',
                      value: '${data.soSinhVienNguyCoCamThi}',
                      color: AppTheme.warningColor,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RiskStatCard(
                      title: 'Cấm Thi (≥20%)',
                      value: '${data.soSinhVienBiCamThi}',
                      color: AppTheme.dangerColor,
                      icon: Icons.block_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Student Danger Radar List
              Text(
                'Danh Sách Phân Loại Nguy Cơ Học Vụ (${data.danhSachSinhVien.length} SV)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              if (data.danhSachSinhVien.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Chưa có dữ liệu điểm danh nào trong lớp học phần này.'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.danhSachSinhVien.length,
                  itemBuilder: (context, index) {
                    final sv = data.danhSachSinhVien[index];
                    final color = _getRiskColor(sv);
                    final badgeText = _getRiskBadgeText(sv);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: color.withOpacity(0.12),
                                  child: Icon(
                                    sv.isBiCamThi
                                        ? Icons.gpp_bad_rounded
                                        : (sv.isNguyCo ? Icons.warning_rounded : Icons.verified_user_rounded),
                                    color: color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sv.hoTen,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        'MSSV: ${sv.maSV}  •  Lớp: ${sv.lop ?? "N/A"}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: color.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Progress bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Tỷ lệ vắng: ${sv.tiLeVangPhanTram.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: color,
                                      ),
                                    ),
                                    Text(
                                      'Có mặt: ${sv.soBuoiCoMat} • Vắng: ${sv.soBuoiVang} • Phép: ${sv.soBuoiVangCoPhep} / ${sv.tongSoBuoi} buổi',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: (sv.tiLeVangPhanTram / 100.0).clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Advisory Recommendation
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.tips_and_updates_outlined, size: 16, color: color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      sv.khuyenNghi,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(SinhVienCanhBao sv) {
    if (sv.isBiCamThi) return AppTheme.dangerColor;
    if (sv.isNguyCo) return const Color(0xFFD97706);
    if (sv.isChuY) return const Color(0xFFEA580C);
    if (sv.isDiTre) return const Color(0xFFCA8A04);
    return AppTheme.successColor;
  }

  String _getRiskBadgeText(SinhVienCanhBao sv) {
    if (sv.isBiCamThi) return 'CẤM THI (≥20%)';
    if (sv.isNguyCo) return 'NGUY CƠ (≥13%)';
    if (sv.isChuY) return 'CHÚ Ý (VẮNG ${sv.soBuoiVang}B)';
    if (sv.isDiTre) return 'ĐI TRỄ (${sv.soBuoiDiTre}B)';
    return 'XUẤT SẮC';
  }
}

class _RiskStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _RiskStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

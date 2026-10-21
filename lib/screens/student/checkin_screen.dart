import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/lop_hoc_phan_model.dart';
import '../../models/buoi_diem_danh_model.dart';
import '../../models/diem_danh_model.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';

class CheckInScreen extends StatefulWidget {
  final int? buoiId;

  const CheckInScreen({super.key, this.buoiId});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  LopHocPhan? _selectedLop;
  BuoiDiemDanh? _selectedBuoi;
  Position? _currentGpsPosition;
  String _realAddress = 'Đang lấy định vị thực tế từ điện thoại...';
  bool _isLocating = true;

  final _qrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final student = Provider.of<StudentProvider>(context, listen: false);

    final svId = auth.currentUser?.sinhVien?.id;
    if (svId != null) {
      await student.fetchStudentData(svId);
    }

    // 1. Select Class (Prioritizing class with active sessions, e.g. 24DTH01_LTDD)
    if (student.myLopHocPhans.isNotEmpty) {
      _selectedLop = student.myLopHocPhans.firstWhere(
        (l) => student.activeBuois.any((b) => b.lopHocPhanId == l.id),
        orElse: () => student.myLopHocPhans.first,
      );
    }

    // 2. Select Session (Prioritizing open session, e.g. Buổi 8)
    _filterAndSelectBuoi();

    // 3. Automatically get real-world location & address from phone's GPS
    await _fetchLiveGpsAndAddress();
  }

  void _filterAndSelectBuoi() {
    final buois = _getFilteredBuois();

    if (buois.isNotEmpty) {
      if (widget.buoiId != null) {
        _selectedBuoi = buois.firstWhere(
          (b) => b.id == widget.buoiId,
          orElse: () => buois.first,
        );
      } else {
        // Priority to open session (e.g. Buổi 8)
        _selectedBuoi = buois.firstWhere(
          (b) => b.isMo,
          orElse: () => buois.first,
        );
      }
      if (_selectedBuoi != null) {
        _qrController.text = _selectedBuoi!.maQRCode ?? '';
      }
    } else {
      _selectedBuoi = null;
    }
  }

  List<BuoiDiemDanh> _getFilteredBuois() {
    final student = Provider.of<StudentProvider>(context, listen: false);
    if (_selectedLop == null) return student.activeBuois;
    final list = student.activeBuois.where((b) => b.lopHocPhanId == _selectedLop!.id).toList();
    return list.isNotEmpty ? list : student.activeBuois;
  }

  Future<void> _fetchLiveGpsAndAddress() async {
    if (!mounted) return;
    setState(() {
      _isLocating = true;
      _realAddress = 'Đang lấy định vị thực tế từ điện thoại...';
    });

    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (pos != null) {
      final address = await LocationService.getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentGpsPosition = pos;
          _realAddress = address;
          _isLocating = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _realAddress = 'Không thể lấy định vị GPS. Vui lòng bật vị trí thiết bị.';
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _handleCheckIn() async {
    final availableBuois = _getFilteredBuois();
    BuoiDiemDanh? targetBuoi = _selectedBuoi;
    if (targetBuoi == null || !availableBuois.any((b) => b.id == targetBuoi!.id)) {
      if (availableBuois.isNotEmpty) {
        targetBuoi = availableBuois.firstWhere((b) => b.isMo, orElse: () => availableBuois.first);
      }
    }

    if (targetBuoi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một buổi học để điểm danh')),
      );
      return;
    }

    // Strict validation: Closed sessions (1 to 7) cannot be checked in!
    if (!targetBuoi.isMo) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.lock_rounded, color: AppTheme.dangerColor, size: 48),
          title: const Text('Buổi Học Đã Khóa Cổng', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'Buổi ${targetBuoi!.soThuTuBuoi} đã kết thúc hoặc giảng viên đã khóa cổng điểm danh. Bạn không thể điểm danh buổi này!',
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
          ],
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final student = Provider.of<StudentProvider>(context, listen: false);

    final maSv = auth.currentUser?.sinhVien?.maSV ?? auth.currentUser?.maSV ?? '2380601738';
    final svId = auth.currentUser?.sinhVien?.id;
    final lat = _currentGpsPosition?.latitude ?? LocationService.defaultLat;
    final lng = _currentGpsPosition?.longitude ?? LocationService.defaultLng;

    // Trigger Fingerprint & Send Recorded Location to Web API
    final CheckInResponseDto result = await student.checkInWithGpsAndFingerprint(
      buoiDiemDanhId: targetBuoi.id,
      maSV: maSv,
      maQRCode: _qrController.text.trim().isNotEmpty
          ? _qrController.text.trim()
          : targetBuoi.maQRCode,
      requireFingerprint: true, // Triggers Biometric verification
      customLat: lat,
      customLng: lng,
      ghiChu: 'Địa điểm: $_realAddress',
      sinhVienId: svId,
    );

    if (!mounted) return;

    final timeVN = AppFormatters.formatVietnamDateTime(result.thoiGian);
    final statusLabel = AppFormatters.getStatusLabel(result.trangThai);
    final statusColor = AppFormatters.getStatusColor(result.trangThai);

    // Show detailed result dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          result.thanhCong ? Icons.check_circle_rounded : Icons.info_rounded,
          color: result.thanhCong ? AppTheme.successColor : AppTheme.dangerColor,
          size: 50,
        ),
        title: Text(
          result.thanhCong ? 'Điểm Danh Thành Công!' : 'Kết Quả Điểm Danh',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.thongBao,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Divider(height: 20),
            if (result.trangThai != null)
              Row(
                children: [
                  const Text('• Trạng thái: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            Text('• Địa chỉ thực tế ghi nhận: $_realAddress', style: const TextStyle(fontSize: 13, height: 1.3)),
            const SizedBox(height: 6),
            Text('• Thời gian ghi nhận: $timeVN', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Phương thức: Sinh trắc học vân tay + Định vị thực tế từ thiết bị',
                style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (result.thanhCong) {
                Navigator.pop(context); // Back to Home
              }
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = Provider.of<StudentProvider>(context);
    final availableBuois = _getFilteredBuois();

    // Safe matching for Lop dropdown
    LopHocPhan? currentLop;
    if (_selectedLop != null && student.myLopHocPhans.any((l) => l.id == _selectedLop!.id)) {
      currentLop = student.myLopHocPhans.firstWhere((l) => l.id == _selectedLop!.id);
    } else if (student.myLopHocPhans.isNotEmpty) {
      currentLop = student.myLopHocPhans.firstWhere(
        (l) => student.activeBuois.any((b) => b.lopHocPhanId == l.id),
        orElse: () => student.myLopHocPhans.first,
      );
    }

    // Safe matching for Buoi dropdown
    BuoiDiemDanh? currentBuoi;
    if (_selectedBuoi != null && availableBuois.any((b) => b.id == _selectedBuoi!.id)) {
      currentBuoi = availableBuois.firstWhere((b) => b.id == _selectedBuoi!.id);
    } else if (availableBuois.isNotEmpty) {
      currentBuoi = availableBuois.firstWhere((b) => b.isMo, orElse: () => availableBuois.first);
    }

    final shiftName = AppFormatters.getShiftName(currentBuoi?.gioBatDau);
    final shiftRule = AppFormatters.getShiftRule(currentBuoi?.gioBatDau);
    final isBuoiOpen = currentBuoi?.isMo ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm Danh Sinh Viên'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STEP 1: SELECT COURSE / CLASS
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
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text('1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '1. Chọn Lớp Học Phần:',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (student.myLopHocPhans.isEmpty)
                      const Text(
                        'Đang tải danh sách lớp học phần...',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      )
                    else
                      DropdownButtonFormField<LopHocPhan>(
                        value: currentLop,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.class_rounded, color: AppTheme.primaryColor),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: student.myLopHocPhans.map((lop) {
                          return DropdownMenuItem<LopHocPhan>(
                            value: lop,
                            child: Text(
                              '${lop.maLopHocPhan} - ${lop.monHoc?.tenMon ?? "Môn học"} (${lop.soBuoi} buổi)',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedLop = val;
                              _filterAndSelectBuoi();
                            });
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // STEP 2: SELECT ATTENDANCE SESSION (Clearly separates OPEN vs LOCKED)
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
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text('2', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '2. Chọn Buổi Cần Điểm Danh:',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (availableBuois.isEmpty)
                      const Text(
                        'Hiện không có buổi học nào của lớp này.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      )
                    else
                      DropdownButtonFormField<BuoiDiemDanh>(
                        value: currentBuoi,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.event_note_rounded, color: AppTheme.primaryColor),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: availableBuois.map((b) {
                          final statusText = b.isMo ? "Đang mở" : "ĐÃ KHÓA";
                          return DropdownMenuItem<BuoiDiemDanh>(
                            value: b,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Buổi ${b.soThuTuBuoi}: ${b.ghiChu ?? "Buổi học"}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: b.isMo ? FontWeight.bold : FontWeight.normal,
                                      color: b.isMo ? AppTheme.primaryColor : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: b.isMo ? AppTheme.successColor.withOpacity(0.12) : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: b.isMo ? AppTheme.successColor : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedBuoi = val;
                              _qrController.text = val.maQRCode ?? '';
                            });
                          }
                        },
                      ),

                    if (currentBuoi != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isBuoiOpen ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isBuoiOpen ? Colors.grey.shade300 : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isBuoiOpen ? Icons.meeting_room_outlined : Icons.lock_rounded,
                                  color: isBuoiOpen ? AppTheme.primaryColor : AppTheme.dangerColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Phòng: ${currentBuoi.lopHocPhan?.phongHoc ?? "E1-04.05 (HUTECH Thủ Đức)"} • $shiftName',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isBuoiOpen
                                        ? AppTheme.successColor.withOpacity(0.12)
                                        : AppTheme.dangerColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isBuoiOpen ? 'CỔNG ĐANG MỞ' : 'CỔNG ĐÃ KHÓA',
                                    style: TextStyle(
                                      color: isBuoiOpen ? AppTheme.successColor : AppTheme.dangerColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isBuoiOpen
                                  ? 'Quy định ca học: $shiftRule'
                                  : 'Buổi học này đã kết thúc hoặc giảng viên đã khóa. Không cho phép điểm danh!',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isBuoiOpen ? AppTheme.textSecondary : AppTheme.dangerColor,
                                fontWeight: isBuoiOpen ? FontWeight.normal : FontWeight.w600,
                              ),
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

            // STEP 3: PURE REAL-WORLD DEVICE LOCATION (No choosing, no spoofing, no raw coordinates)
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
                        const CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFFEA580C),
                          child: Text('3', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '3. Vị Trí Định Vị Thực Tế:',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isLocating)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor, size: 22),
                            tooltip: 'Lấy lại vị trí điện thoại',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _fetchLiveGpsAndAddress,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Verified Address Container (Cannot be edited, taken strictly from phone)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_on_rounded, color: Color(0xFFEA580C), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Địa chỉ ghi nhận vào hệ thống:',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9A3412),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (_isLocating)
                                  const Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 1.5),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Đang định vị địa chỉ thực tế...',
                                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    _realAddress,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF431407),
                                      height: 1.35,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: AppTheme.successColor),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Định vị tự động qua GPS thiết bị (chống gian lận)',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // QR Code Session Field
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mã QR Buổi Học (Tự động điền theo buổi):',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _qrController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.qr_code_2_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // STEP 4: BIOMETRIC FINGERPRINT BUTTON
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: isBuoiOpen
                      ? [AppTheme.primaryDark, AppTheme.primaryColor]
                      : [Colors.grey.shade600, Colors.grey.shade500],
                ),
                boxShadow: isBuoiOpen
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (student.isLoading || !isBuoiOpen) ? null : _handleCheckIn,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: student.isLoading
                        ? const Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isBuoiOpen ? Icons.fingerprint_rounded : Icons.lock_outline_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  isBuoiOpen ? '4. BẬT VÂN TAY ĐIỂM DANH' : 'CỔNG ĐÃ KHÓA (KHÔNG THỂ ĐIỂM DANH)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Center(
              child: Text(
                isBuoiOpen
                    ? 'Bước 4: Quét cảm biến vân tay để ghi nhận điểm danh & vị trí thực tế'
                    : 'Cổng điểm danh buổi này đã đóng. Vui lòng liên hệ giảng viên nếu có khiếu nại.',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

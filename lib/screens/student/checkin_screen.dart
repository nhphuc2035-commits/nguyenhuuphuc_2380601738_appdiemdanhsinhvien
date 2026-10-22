import 'dart:async';
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
  double _distanceToHutech = 0.0;
  bool _isInsideCampus = false;

  final _qrController = TextEditingController();

  // Quy định thời gian phiên điểm danh: 60 giây
  Timer? _countdownTimer;
  int _remainingSeconds = 60;
  bool _isTimeExpired = false;
  bool _hasCheckedIn = false;

  String _formatDistance(double d) {
    if (d >= 1000) {
      return '${(d / 1000).toStringAsFixed(1)}km';
    }
    return '${d.toStringAsFixed(0)}m';
  }

  @override
  void initState() {
    super.initState();
    _start60sTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _start60sTimer() {
    _countdownTimer?.cancel();
    _remainingSeconds = 60;
    _isTimeExpired = false;
    _hasCheckedIn = false;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTimeExpired = true;
        });
        _handleTimeExpiredAutoAbsent();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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

    // 1. Chọn lớp học phần (Ưu tiên lớp có buổi đang mở)
    if (student.myLopHocPhans.isNotEmpty) {
      _selectedLop = student.myLopHocPhans.firstWhere(
        (l) => student.activeBuois.any((b) => b.lopHocPhanId == l.id),
        orElse: () => student.myLopHocPhans.first,
      );
    }

    // 2. Chọn buổi học (Ưu tiên buổi đang mở)
    _filterAndSelectBuoi();

    // 3. Lấy định vị GPS thực tế từ thiết bị và tính khoảng cách tới trường HUTECH
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
      final dist = LocationService.getDistanceToHutech(pos.latitude, pos.longitude);
      final inside = LocationService.isInsideHutechCampus(pos.latitude, pos.longitude);

      if (mounted) {
        setState(() {
          _currentGpsPosition = pos;
          _realAddress = address;
          _distanceToHutech = dist;
          _isInsideCampus = inside;
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

  /// Tự động ghi nhận VẮNG KHÔNG PHÉP khi hết 60 giây
  Future<void> _handleTimeExpiredAutoAbsent() async {
    if (!mounted || _hasCheckedIn) return;

    final availableBuois = _getFilteredBuois();
    BuoiDiemDanh? targetBuoi = _selectedBuoi;
    if (targetBuoi == null || !availableBuois.any((b) => b.id == targetBuoi!.id)) {
      if (availableBuois.isNotEmpty) {
        targetBuoi = availableBuois.firstWhere((b) => b.isMo, orElse: () => availableBuois.first);
      }
    }

    if (targetBuoi == null || !targetBuoi.isMo) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final student = Provider.of<StudentProvider>(context, listen: false);
    final maSv = auth.currentUser?.sinhVien?.maSV ?? auth.currentUser?.maSV ?? '2380601738';
    final svId = auth.currentUser?.sinhVien?.id;
    final lat = _currentGpsPosition?.latitude ?? LocationService.defaultLat;
    final lng = _currentGpsPosition?.longitude ?? LocationService.defaultLng;

    _hasCheckedIn = true;

    // Gửi điểm danh VẮNG tự động do quá 60 giây
    await student.checkInWithGpsAndFingerprint(
      buoiDiemDanhId: targetBuoi.id,
      maSV: maSv,
      maQRCode: targetBuoi.maQRCode,
      requireFingerprint: false,
      customLat: lat,
      customLng: lng,
      ghiChu: 'Hết thời gian 60 giây quy định. Hệ thống tự động ghi nhận VẮNG KHÔNG PHÉP.',
      sinhVienId: svId,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.timer_off_rounded, color: AppTheme.dangerColor, size: 52),
        title: const Text(
          'ĐÃ HẾT 60 GIÂY ĐIỂM DANH!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.dangerColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phiên điểm danh chỉ cho phép tối đa 60 giây kể từ khi mở cổng. Bạn đã không hoàn thành điểm danh kịp thời!',
              style: TextStyle(fontSize: 13.5, height: 1.3),
            ),
            const Divider(height: 18),
            Row(
              children: [
                const Text('• Trạng thái: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VẮNG KHÔNG PHÉP',
                    style: TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '• Lý do: Quá thời gian 60 giây quy định của phiên điểm danh.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF991B1B)),
            ),
            const SizedBox(height: 6),
            Text('• Địa chỉ ghi nhận: $_realAddress', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Quay về Home
            },
            child: const Text('Đã hiểu & Quay về'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    // 1. Kiểm tra hết hạn 60 giây
    if (_isTimeExpired || _remainingSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hết thời gian 60 giây điểm danh! Hệ thống tự động ghi nhận VẮNG.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

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

    // Buổi học đã đóng không được phép điểm danh
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

    // 2. Kiểm tra GPS vị trí: Bán kính ngắn trong khuôn viên HUTECH (<= 200 mét)
    final distToHutech = LocationService.getDistanceToHutech(lat, lng);
    final isInsideCampus = distToHutech <= LocationService.maxCampusRadiusMeters;

    String attendanceNote;
    if (isInsideCampus) {
      attendanceNote = 'Địa điểm: $_realAddress | Trong khuôn viên HUTECH (Khoảng cách: ${distToHutech.toStringAsFixed(0)}m <= 200m)';
    } else {
      attendanceNote = 'Vị trí ngoài phạm vi trường HUTECH (Cách trường ${distToHutech.toStringAsFixed(0)}m > 200m). Địa chỉ: $_realAddress | Ghi nhận VẮNG KHÔNG PHÉP';
    }

    _countdownTimer?.cancel();
    _hasCheckedIn = true;

    // 3. Thực hiện điểm danh và gửi lên Web API
    final CheckInResponseDto result = await student.checkInWithGpsAndFingerprint(
      buoiDiemDanhId: targetBuoi.id,
      maSV: maSv,
      maQRCode: _qrController.text.trim().isNotEmpty
          ? _qrController.text.trim()
          : targetBuoi.maQRCode,
      requireFingerprint: isInsideCampus, // Chỉ yêu cầu vân tay nếu đang ở trong trường
      customLat: lat,
      customLng: lng,
      ghiChu: attendanceNote,
      sinhVienId: svId,
    );

    if (!mounted) return;

    final timeVN = AppFormatters.formatVietnamDateTime(result.thoiGian);

    // QUY ĐỊNH BẮT BUỘC: Nếu ngoài khuôn viên trường HUTECH (> 200m), chắc chắn ghi nhận VẮNG KHÔNG PHÉP
    final finalTrangThai = isInsideCampus ? (result.trangThai ?? 'CoMat') : 'VangKhongPhep';
    final finalSuccess = isInsideCampus && result.thanhCong;
    final statusLabel = AppFormatters.getStatusLabel(finalTrangThai);
    final statusColor = AppFormatters.getStatusColor(finalTrangThai);

    // Hiển thị dialog thông báo kết quả
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          finalSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: finalSuccess ? AppTheme.successColor : AppTheme.dangerColor,
          size: 50,
        ),
        title: Text(
          finalSuccess ? 'Điểm Danh Thành Công!' : 'Điểm Danh Ngoài Trường (Ghi Nhận Vắng)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.5,
            color: finalSuccess ? AppTheme.textPrimary : AppTheme.dangerColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              finalSuccess
                  ? (result.thongBao.isNotEmpty ? result.thongBao : 'Đã ghi nhận có mặt đúng giờ!')
                  : 'Vị trí của bạn nằm NGOÀI phạm vi khuôn viên trường HUTECH! Bạn đang cách trường ${_formatDistance(distToHutech)} (Quy định bán kính tối đa 200m).',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: finalSuccess ? AppTheme.textPrimary : const Color(0xFF991B1B),
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Text('• Trạng thái: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('• Địa chỉ thực tế ghi nhận: $_realAddress', style: const TextStyle(fontSize: 12.5, height: 1.3)),
            const SizedBox(height: 6),
            Text(
              '• Khoảng cách tới trường: ${_formatDistance(distToHutech)} ${isInsideCampus ? "(Hợp lệ <= 200m)" : "(Không hợp lệ > 200m)"}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isInsideCampus ? AppTheme.successColor : AppTheme.dangerColor,
              ),
            ),
            const SizedBox(height: 6),
            Text('• Thời gian ghi nhận: $timeVN', style: const TextStyle(fontSize: 12.5)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isInsideCampus ? Colors.blue.shade50 : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isInsideCampus ? Colors.blue.shade200 : const Color(0xFFFECACA),
                ),
              ),
              child: Text(
                isInsideCampus
                    ? 'Phương thức: Sinh trắc học vân tay + Định vị trong khuôn viên trường HUTECH'
                    : 'Quy chế HUTECH: Điểm danh ngoài bán kính 200m khuôn viên trường bị xử lý VẮNG KHÔNG PHÉP do vi phạm vị trí học vụ.',
                style: TextStyle(
                  fontSize: 11,
                  color: isInsideCampus ? AppTheme.primaryColor : const Color(0xFF991B1B),
                  fontStyle: FontStyle.italic,
                ),
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
              Navigator.pop(context); // Trở về Home
            },
            child: const Text('Đóng & Trở về'),
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

    // Khoảng cách thực tế đến HUTECH
    final currentLat = _currentGpsPosition?.latitude ?? LocationService.defaultLat;
    final currentLng = _currentGpsPosition?.longitude ?? LocationService.defaultLng;
    final liveDistance = _currentGpsPosition != null ? _distanceToHutech : LocationService.getDistanceToHutech(currentLat, currentLng);
    final isInsideCampus = _currentGpsPosition != null ? _isInsideCampus : LocationService.isInsideHutechCampus(currentLat, currentLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm Danh Sinh Viên'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 60-SECOND COUNTDOWN TIMER CARD (Yêu cầu: Chỉ cho phép điểm danh 60 giây, hết 60s là Vắng)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _isTimeExpired
                      ? AppTheme.dangerColor
                      : (_remainingSeconds <= 15
                          ? AppTheme.dangerColor
                          : (_remainingSeconds <= 30 ? AppTheme.warningColor : const Color(0xFF93C5FD))),
                  width: 1.5,
                ),
              ),
              color: _isTimeExpired
                  ? const Color(0xFFFEF2F2)
                  : (_remainingSeconds <= 15 ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isTimeExpired ? Icons.timer_off_rounded : Icons.timer_outlined,
                          color: _isTimeExpired
                              ? AppTheme.dangerColor
                              : (_remainingSeconds <= 15
                                  ? AppTheme.dangerColor
                                  : (_remainingSeconds <= 30 ? AppTheme.warningColor : AppTheme.successColor)),
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isTimeExpired ? 'ĐÃ HẾT GIỜ ĐIỂM DANH (60s)' : 'THỜI GIAN ĐIỂM DANH: 60 GIÂY',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: _isTimeExpired ? AppTheme.dangerColor : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isTimeExpired
                                    ? 'Đã hết 60 giây. Hệ thống tự động ghi nhận VẮNG KHÔNG PHÉP!'
                                    : 'Quá 60 giây kể từ khi mở cổng, hệ thống sẽ tự động ghi nhận VẮNG!',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _isTimeExpired ? const Color(0xFF991B1B) : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isTimeExpired
                                ? AppTheme.dangerColor
                                : (_remainingSeconds <= 15
                                    ? AppTheme.dangerColor
                                    : (_remainingSeconds <= 30 ? AppTheme.warningColor : AppTheme.primaryColor)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '00:${_remainingSeconds.toString().padLeft(2, '0')}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _isTimeExpired ? 0.0 : (_remainingSeconds / 60.0).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isTimeExpired
                              ? AppTheme.dangerColor
                              : (_remainingSeconds <= 15
                                  ? AppTheme.dangerColor
                                  : (_remainingSeconds <= 30 ? AppTheme.warningColor : AppTheme.successColor)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

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

            // STEP 2: SELECT ATTENDANCE SESSION
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

            // STEP 3: VỊ TRÍ ĐỊNH VỊ THỰC TẾ & BÁN KÍNH KHUÔN VIÊN TRƯỜNG HUTECH (<= 200m)
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
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isInsideCampus ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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

                    // Verified Address Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isInsideCampus ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isInsideCampus ? const Color(0xFF86EFAC) : const Color(0xFFFED7AA),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isInsideCampus
                                  ? const Color(0xFF10B981).withOpacity(0.12)
                                  : const Color(0xFFEA580C).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isInsideCampus ? Icons.verified_user_rounded : Icons.location_on_rounded,
                              color: isInsideCampus ? const Color(0xFF10B981) : const Color(0xFFEA580C),
                              size: 24,
                            ),
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
                                      fontSize: 13,
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

                    const SizedBox(height: 10),

                    // Phạm vi trường HUTECH & Khoảng cách
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isInsideCampus ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isInsideCampus ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isInsideCampus ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                            size: 18,
                            color: isInsideCampus ? AppTheme.successColor : AppTheme.dangerColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isInsideCampus
                                      ? 'TRONG KHUÔN VIÊN TRƯỜNG HUTECH (HỢP LỆ)'
                                      : 'NGOÀI PHẠM VI TRƯỜNG HUTECH (SẼ BỊ TÍNH VẮNG)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isInsideCampus ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Khoảng cách tới HUTECH: ${_formatDistance(liveDistance)} (Bán kính quy định: <= 200m)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isInsideCampus ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!isInsideCampus && !_isLocating) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Lưu ý: Điểm danh ngoài bán kính 200m khuôn viên HUTECH sẽ tự động bị ghi nhận VẮNG KHÔNG PHÉP!',
                                style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.25),
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
                  colors: (!isBuoiOpen || _isTimeExpired)
                      ? [Colors.grey.shade600, Colors.grey.shade500]
                      : (!isInsideCampus
                          ? [const Color(0xFFDC2626), const Color(0xFFB91C1C)]
                          : [AppTheme.primaryDark, AppTheme.primaryColor]),
                ),
                boxShadow: (isBuoiOpen && !_isTimeExpired)
                    ? [
                        BoxShadow(
                          color: (!isInsideCampus ? Colors.red : AppTheme.primaryColor).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (student.isLoading || !isBuoiOpen || _isTimeExpired) ? null : _handleCheckIn,
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
                                _isTimeExpired
                                    ? Icons.timer_off_rounded
                                    : (!isBuoiOpen
                                        ? Icons.lock_outline_rounded
                                        : (!isInsideCampus ? Icons.location_off_rounded : Icons.fingerprint_rounded)),
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  _isTimeExpired
                                      ? 'CỔNG ĐÃ HẾT 60 GIÂY (GHI NHẬN VẮNG)'
                                      : (!isBuoiOpen
                                          ? 'CỔNG ĐÃ KHÓA (KHÔNG THỂ ĐIỂM DANH)'
                                          : (!isInsideCampus
                                              ? '4. ĐIỂM DANH (NGOÀI TRƯỜNG: SẼ BỊ VẮNG)'
                                              : '4. BẬT VÂN TAY ĐIỂM DANH')),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
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
                _isTimeExpired
                    ? 'Đã hết 60 giây. Hệ thống tự động ghi nhận VẮNG KHÔNG PHÉP theo quy định.'
                    : (!isInsideCampus
                        ? 'Cảnh báo: Bạn đang ở ngoài bán kính 200m khuôn viên HUTECH. Điểm danh sẽ bị tính VẮNG!'
                        : 'Quét cảm biến vân tay để xác thực có mặt trong khuôn viên trường HUTECH'),
                style: TextStyle(
                  fontSize: 11.5,
                  color: (!isInsideCampus || _isTimeExpired) ? AppTheme.dangerColor : AppTheme.textSecondary,
                  fontWeight: (!isInsideCampus || _isTimeExpired) ? FontWeight.bold : FontWeight.normal,
                ),
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

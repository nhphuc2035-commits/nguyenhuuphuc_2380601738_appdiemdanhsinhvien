import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../core/services/location_service.dart';
import '../core/services/biometric_service.dart';
import '../core/services/ocr_service.dart';
import '../models/diem_danh_model.dart';
import '../models/don_nghi_phep_model.dart';
import '../models/buoi_diem_danh_model.dart';
import '../models/lop_hoc_phan_model.dart';

class StudentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final OcrService _ocrService = OcrService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<DiemDanh> _myDiemDanhs = [];
  List<DonNghiPhep> _myDonNghiPheps = [];
  List<BuoiDiemDanh> _activeBuois = [];
  List<LopHocPhan> _myLopHocPhans = [];
  Position? _currentGps;
  CheckInResponseDto? _lastCheckInResult;
  OcrResultModel? _lastOcrResult;

  List<DiemDanh> get myDiemDanhs => _myDiemDanhs;
  List<DonNghiPhep> get myDonNghiPheps => _myDonNghiPheps;
  List<BuoiDiemDanh> get activeBuois => _activeBuois;
  List<LopHocPhan> get myLopHocPhans => _myLopHocPhans;
  Position? get currentGps => _currentGps;
  CheckInResponseDto? get lastCheckInResult => _lastCheckInResult;
  OcrResultModel? get lastOcrResult => _lastOcrResult;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearOcr() {
    _lastOcrResult = null;
    notifyListeners();
  }

  /// Load all student data
  Future<void> fetchStudentData(int sinhVienId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch student's attendance records
      final ddRes = await _api.get(ApiConstants.diemDanhBySinhVien(sinhVienId));
      if (ddRes.success && ddRes.data is List) {
        _myDiemDanhs = (ddRes.data as List).map((e) => DiemDanh.fromJson(e)).toList();
      }

      // 2. Fetch student's leave requests
      final leaveRes = await _api.get(ApiConstants.donNghiPhepBySinhVien(sinhVienId));
      if (leaveRes.success && leaveRes.data is List) {
        _myDonNghiPheps = (leaveRes.data as List).map((e) => DonNghiPhep.fromJson(e)).toList();
      }

      // 3. Fetch active sessions (BuoiDiemDanh)
      final buoiRes = await _api.get(ApiConstants.buoiDiemDanh);
      if (buoiRes.success && buoiRes.data is List) {
        _activeBuois = (buoiRes.data as List).map((e) => BuoiDiemDanh.fromJson(e)).toList();
      }

      // 4. Fetch LopHocPhans
      final lopRes = await _api.get(ApiConstants.lopHocPhan);
      if (lopRes.success && lopRes.data is List) {
        _myLopHocPhans = (lopRes.data as List).map((e) => LopHocPhan.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = 'Lỗi tải dữ liệu sinh viên: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update current GPS position
  Future<Position?> updateGps() async {
    _currentGps = await LocationService.getCurrentPosition();
    notifyListeners();
    return _currentGps;
  }

  /// 5b + 5e: Perform Check-in with GPS Location and Fingerprint Biometrics
  Future<CheckInResponseDto> checkInWithGpsAndFingerprint({
    required int buoiDiemDanhId,
    required String maSV,
    String? maQRCode,
    bool requireFingerprint = true,
    double? customLat,
    double? customLng,
    String? ghiChu,
    int? sinhVienId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Requirement 5e: Biometric verification (fingerprint)
      if (requireFingerprint) {
        final authenticated = await BiometricService.authenticate(
          reason: 'Xác thực sinh trắc học vân tay để điểm danh môn học',
        );
        if (!authenticated) {
          _isLoading = false;
          _errorMessage = 'Xác thực vân tay không thành công hoặc đã bị hủy!';
          notifyListeners();
          return CheckInResponseDto(
            thanhCong: false,
            thongBao: 'Xác thực vân tay không thành công!',
          );
        }
      }

      // 2. Requirement 5b: GPS Location Acquisition
      double lat;
      double lng;
      if (customLat != null && customLng != null) {
        lat = customLat;
        lng = customLng;
      } else {
        final position = await updateGps();
        lat = position?.latitude ?? LocationService.defaultLat;
        lng = position?.longitude ?? LocationService.defaultLng;
      }

      // 3. Submit CheckInRequestDto to server
      final checkInDto = CheckInRequestDto(
        buoiDiemDanhId: buoiDiemDanhId,
        maSV: maSV,
        maQRCode: maQRCode,
        viTriViDo: lat,
        viTriKinhDo: lng,
        phuongThuc: 'VanTay_GPS',
        ghiChu: ghiChu ?? 'Điểm danh vân tay (Sinh trắc học) + GPS',
      );

      final response = await _api.post(ApiConstants.checkIn, body: checkInDto.toJson());
      _isLoading = false;

      if (response.data is Map) {
        _lastCheckInResult = CheckInResponseDto.fromJson(Map<String, dynamic>.from(response.data as Map));
      } else {
        _lastCheckInResult = CheckInResponseDto(
          thanhCong: response.success,
          thongBao: response.message ?? 'Đã ghi nhận điểm danh',
        );
      }

      // Automatically refresh student profile & attendance history
      if (sinhVienId != null) {
        await fetchStudentData(sinhVienId);
      }

      notifyListeners();
      return _lastCheckInResult!;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi điểm danh: $e';
      notifyListeners();
      return CheckInResponseDto(
        thanhCong: false,
        thongBao: 'Lỗi ngoại lệ: $e',
      );
    }
  }

  /// 5f: Process OCR & Translation for Medical Certificate / Student ID
  Future<OcrResultModel?> processOcrImage(File file, {String sourceLang = 'auto'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Upload image to server
      final fileUrl = await _ocrService.uploadImage(file);
      if (fileUrl == null) {
        _isLoading = false;
        _errorMessage = 'Tải ảnh lên máy chủ thất bại!';
        notifyListeners();
        return null;
      }

      // Step 2: Request OCR extraction & translation to Vietnamese
      final ocrResult = await _ocrService.extractAndTranslate(
        fileUrl,
        sourceLang: sourceLang,
        targetLang: 'vi',
      );
      _isLoading = false;
      _lastOcrResult = ocrResult;
      notifyListeners();
      return ocrResult;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi xử lý OCR: $e';
      notifyListeners();
      return null;
    }
  }

  /// Submit DonNghiPhep
  Future<bool> submitDonNghiPhep({
    required int sinhVienId,
    required int lopHocPhanId,
    required String ngayNghi,
    required String lyDo,
    String? minhChungUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final don = DonNghiPhep(
      id: 0,
      sinhVienId: sinhVienId,
      lopHocPhanId: lopHocPhanId,
      ngayNghi: ngayNghi,
      lyDo: lyDo,
      minhChungUrl: minhChungUrl,
      trangThai: 'ChoDuyet',
    );

    final res = await _api.post(ApiConstants.donNghiPhep, body: don.toJson());
    _isLoading = false;
    if (res.success) {
      await fetchStudentData(sinhVienId);
      return true;
    } else {
      _errorMessage = res.message ?? 'Nộp đơn xin nghỉ thất bại';
      notifyListeners();
      return false;
    }
  }
}

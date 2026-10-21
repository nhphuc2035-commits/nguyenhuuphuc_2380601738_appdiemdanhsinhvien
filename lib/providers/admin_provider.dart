import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../models/sinh_vien_model.dart';
import '../models/mon_hoc_model.dart';
import '../models/lop_hoc_phan_model.dart';
import '../models/buoi_diem_danh_model.dart';
import '../models/diem_danh_model.dart';
import '../models/don_nghi_phep_model.dart';
import '../models/canh_bao_cam_thi_model.dart';
import '../models/thong_ke_tong_quan_model.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cached lists
  List<SinhVien> _sinhViens = [];
  List<MonHoc> _monHocs = [];
  List<LopHocPhan> _lopHocPhans = [];
  List<BuoiDiemDanh> _buoiDiemDanhs = [];
  List<DiemDanh> _diemDanhs = [];
  List<DonNghiPhep> _donNghiPheps = [];
  ThongKeTongQuan? _thongKeTongQuan;
  CanhBaoCamThiModel? _canhBaoCamThi;

  int? _currentBuoiDiemDanhLopFilter;
  int? _currentDiemDanhBuoiFilter;

  List<SinhVien> get sinhViens => _sinhViens;
  List<MonHoc> get monHocs => _monHocs;
  List<LopHocPhan> get lopHocPhans => _lopHocPhans;
  List<BuoiDiemDanh> get buoiDiemDanhs => _buoiDiemDanhs;
  List<DiemDanh> get diemDanhs => _diemDanhs;
  List<DonNghiPhep> get donNghiPheps => _donNghiPheps;
  ThongKeTongQuan? get thongKeTongQuan => _thongKeTongQuan;
  CanhBaoCamThiModel? get canhBaoCamThi => _canhBaoCamThi;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== 1. SINH VIEN CRUD ====================
  Future<void> fetchSinhViens() async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.get(ApiConstants.sinhVien);
    _isLoading = false;
    if (res.success) {
      List? list;
      if (res.data is List) {
        list = res.data as List;
      } else if (res.data is Map && res.data['value'] is List) {
        list = res.data['value'] as List;
      } else if (res.data is Map && res.data['data'] is List) {
        list = res.data['data'] as List;
      }
      if (list != null) {
        _sinhViens = list.map((e) => SinhVien.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } else {
        _errorMessage = res.message ?? 'Không thể tải danh sách sinh viên';
      }
    } else {
      _errorMessage = res.message ?? 'Không thể tải danh sách sinh viên';
    }
    notifyListeners();
  }

  Future<bool> addSinhVien(SinhVien sv) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.post(ApiConstants.sinhVien, body: sv.toJson());
    _isLoading = false;
    if (res.success) {
      await fetchSinhViens();
      return true;
    } else {
      _errorMessage = res.message ?? 'Thêm sinh viên thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSinhVien(int id, SinhVien sv) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.put(ApiConstants.sinhVienById(id), body: sv.toJson());
    _isLoading = false;
    if (res.success) {
      await fetchSinhViens();
      return true;
    } else {
      _errorMessage = res.message ?? 'Cập nhật sinh viên thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSinhVien(int id) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.delete(ApiConstants.sinhVienById(id));
    _isLoading = false;
    if (res.success) {
      _sinhViens.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message ?? 'Xóa sinh viên thất bại';
      notifyListeners();
      return false;
    }
  }

  // ==================== 2. MON HOC CRUD ====================
  Future<void> fetchMonHocs() async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.get(ApiConstants.monHoc);
    _isLoading = false;
    if (res.success && res.data is List) {
      _monHocs = (res.data as List).map((e) => MonHoc.fromJson(e)).toList();
    } else {
      _errorMessage = res.message ?? 'Không thể tải danh sách môn học';
    }
    notifyListeners();
  }

  Future<bool> addMonHoc(MonHoc mh) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.post(ApiConstants.monHoc, body: mh.toJson());
    _isLoading = false;
    if (res.success) {
      await fetchMonHocs();
      return true;
    } else {
      _errorMessage = res.message ?? 'Thêm môn học thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMonHoc(int id, MonHoc mh) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.put(ApiConstants.monHocById(id), body: mh.toJson());
    _isLoading = false;
    if (res.success) {
      await fetchMonHocs();
      return true;
    } else {
      _errorMessage = res.message ?? 'Cập nhật môn học thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMonHoc(int id) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.delete(ApiConstants.monHocById(id));
    _isLoading = false;
    if (res.success) {
      _monHocs.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message ?? 'Xóa môn học thất bại';
      notifyListeners();
      return false;
    }
  }

  // ==================== 3. LOP HOC PHAN CRUD ====================
  Future<void> fetchLopHocPhans() async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.get(ApiConstants.lopHocPhan);
    _isLoading = false;
    if (res.success && res.data is List) {
      _lopHocPhans = (res.data as List).map((e) => LopHocPhan.fromJson(e)).toList();
    } else {
      _errorMessage = res.message ?? 'Không thể tải danh sách lớp học phần';
    }
    notifyListeners();
  }

  Future<bool> addLopHocPhan(LopHocPhan lhp) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.post(ApiConstants.lopHocPhan, body: lhp.toJson());
    _isLoading = false;
    if (res.success) {
      await fetchLopHocPhans();
      return true;
    } else {
      _errorMessage = res.message ?? 'Thêm lớp học phần thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLopHocPhan(int id, LopHocPhan lhp) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.put(ApiConstants.lopHocPhanById(id), body: lhp.toJson());
    _isLoading = false;
    if (res.success) {
      await fetchLopHocPhans();
      return true;
    } else {
      _errorMessage = res.message ?? 'Cập nhật lớp học phần thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLopHocPhan(int id) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.delete(ApiConstants.lopHocPhanById(id));
    _isLoading = false;
    if (res.success) {
      _lopHocPhans.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message ?? 'Xóa lớp học phần thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<List<SinhVien>> fetchSinhViensInLop(int lopId) async {
    final res = await _api.get(ApiConstants.lopHocPhanSinhViens(lopId));
    if (res.success && res.data is List) {
      return (res.data as List).map((e) => SinhVien.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> themSinhVienVaoLop(int lopId, int sinhVienId) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.post(ApiConstants.themSinhVienVaoLop(lopId, sinhVienId));
    _isLoading = false;
    if (res.success) {
      await fetchLopHocPhans();
      return true;
    } else {
      _errorMessage = res.message ?? 'Thêm sinh viên vào lớp thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> xoaSinhVienKhoiLop(int lopId, int sinhVienId) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.delete(ApiConstants.xoaSinhVienKhoiLop(lopId, sinhVienId));
    _isLoading = false;
    if (res.success) {
      await fetchLopHocPhans();
      return true;
    } else {
      _errorMessage = res.message ?? 'Xóa sinh viên khỏi lớp thất bại';
      notifyListeners();
      return false;
    }
  }

  // ==================== 4. BUOI DIEM DANH CRUD ====================
  Future<void> fetchBuoiDiemDanhs({int? lopHocPhanId}) async {
    _currentBuoiDiemDanhLopFilter = lopHocPhanId;
    _isLoading = true;
    notifyListeners();
    final endpoint = lopHocPhanId != null
        ? ApiConstants.buoiDiemDanhByLop(lopHocPhanId)
        : ApiConstants.buoiDiemDanh;

    final res = await _api.get(endpoint);
    _isLoading = false;
    if (res.success && res.data is List) {
      _buoiDiemDanhs = (res.data as List).map((e) => BuoiDiemDanh.fromJson(e)).toList();
    } else {
      _errorMessage = res.message ?? 'Không thể tải buổi điểm danh';
    }
    notifyListeners();
  }

  Future<bool> addBuoiDiemDanh(BuoiDiemDanh buoi) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.post(ApiConstants.buoiDiemDanh, body: buoi.toJson());
    _isLoading = false;
    if (res.success) {
      await fetchBuoiDiemDanhs(lopHocPhanId: _currentBuoiDiemDanhLopFilter);
      fetchThongKeTongQuan();
      return true;
    } else {
      _errorMessage = res.message ?? 'Tạo buổi điểm danh thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBuoiDiemDanh(int id, BuoiDiemDanh buoi) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.put(ApiConstants.buoiDiemDanhById(id), body: buoi.toJson());
    _isLoading = false;
    if (res.success) {
      await fetchBuoiDiemDanhs(lopHocPhanId: _currentBuoiDiemDanhLopFilter);
      fetchThongKeTongQuan();
      return true;
    } else {
      _errorMessage = res.message ?? 'Cập nhật buổi điểm danh thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBuoiDiemDanh(int id) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.delete(ApiConstants.buoiDiemDanhById(id));
    _isLoading = false;
    if (res.success) {
      _buoiDiemDanhs.removeWhere((item) => item.id == id);
      fetchThongKeTongQuan();
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message ?? 'Xóa buổi điểm danh thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleDongMoBuoi(int id) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.put(ApiConstants.dongMoBuoiDiemDanh(id));
    _isLoading = false;
    if (res.success) {
      await fetchBuoiDiemDanhs(lopHocPhanId: _currentBuoiDiemDanhLopFilter);
      fetchThongKeTongQuan();
      return true;
    } else {
      _errorMessage = res.message ?? 'Thao tác đóng/mở thất bại';
      notifyListeners();
      return false;
    }
  }

  // ==================== 5. DIEM DANH CRUD ====================
  Future<void> fetchDiemDanhs({int? buoiId}) async {
    _currentDiemDanhBuoiFilter = buoiId;
    _isLoading = true;
    notifyListeners();
    final endpoint = buoiId != null
        ? ApiConstants.diemDanhByBuoi(buoiId)
        : ApiConstants.diemDanh;

    final res = await _api.get(endpoint);
    _isLoading = false;
    if (res.success) {
      List? list;
      if (res.data is List) {
        list = res.data as List;
      } else if (res.data is Map && res.data['value'] is List) {
        list = res.data['value'] as List;
      } else if (res.data is Map && res.data['data'] is List) {
        list = res.data['data'] as List;
      }
      if (list != null) {
        _diemDanhs = list.map((e) => DiemDanh.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } else {
        _errorMessage = res.message ?? 'Không thể tải dữ liệu điểm danh';
      }
    } else {
      _errorMessage = res.message ?? 'Không thể tải dữ liệu điểm danh';
    }
    notifyListeners();
  }

  Future<bool> updateDiemDanh(int id, DiemDanh dd) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.put(ApiConstants.diemDanhById(id), body: dd.toJson());
    _isLoading = false;
    if (res.success) {
      await fetchDiemDanhs(buoiId: _currentDiemDanhBuoiFilter);
      fetchThongKeTongQuan();
      return true;
    } else {
      _errorMessage = res.message ?? 'Cập nhật điểm danh thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDiemDanh(int id) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.delete(ApiConstants.diemDanhById(id));
    _isLoading = false;
    if (res.success) {
      _diemDanhs.removeWhere((item) => item.id == id);
      fetchThongKeTongQuan();
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message ?? 'Xóa bản ghi điểm danh thất bại';
      notifyListeners();
      return false;
    }
  }

  // ==================== 6. DON NGHI PHEP CRUD ====================
  Future<void> fetchDonNghiPheps() async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.get(ApiConstants.donNghiPhep);
    _isLoading = false;
    if (res.success && res.data is List) {
      _donNghiPheps = (res.data as List).map((e) => DonNghiPhep.fromJson(e)).toList();
    } else {
      _errorMessage = res.message ?? 'Không thể tải danh sách đơn nghỉ phép';
    }
    notifyListeners();
  }

  Future<bool> duyetDonNghiPhep(int id, {required String trangThai, String phanHoi = ''}) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.put(
      ApiConstants.duyetDonNghiPhep(id),
      body: {
        'trangThai': trangThai, // "DaDuyet" or "TuChoi"
        'phanHoi': phanHoi,
      },
    );
    _isLoading = false;
    if (res.success) {
      await fetchDonNghiPheps();
      fetchThongKeTongQuan();
      return true;
    } else {
      _errorMessage = res.message ?? 'Duyệt đơn thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDonNghiPhep(int id) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.delete(ApiConstants.donNghiPhepById(id));
    _isLoading = false;
    if (res.success) {
      _donNghiPheps.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message ?? 'Xóa đơn thất bại';
      notifyListeners();
      return false;
    }
  }

  // ==================== 7. THONG KE & CANH BAO CAM THI ====================
  Future<void> fetchThongKeTongQuan() async {
    final res = await _api.get(ApiConstants.thongKeTongQuan);
    if (res.success && res.data is Map) {
      _thongKeTongQuan = ThongKeTongQuan.fromJson(Map<String, dynamic>.from(res.data as Map));
      notifyListeners();
    }
  }

  Future<void> fetchCanhBaoCamThi(int lopHocPhanId) async {
    _isLoading = true;
    notifyListeners();
    final res = await _api.get(ApiConstants.canhBaoCamThi(lopHocPhanId));
    _isLoading = false;
    if (res.success && res.data is Map) {
      _canhBaoCamThi = CanhBaoCamThiModel.fromJson(Map<String, dynamic>.from(res.data as Map));
    } else {
      _errorMessage = res.message ?? 'Không thể lấy thông tin cảnh báo cấm thi';
    }
    notifyListeners();
  }
}

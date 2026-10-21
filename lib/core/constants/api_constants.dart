class ApiConstants {
  static const String baseUrl = 'https://noble-courage-rear-lit.trycloudflare.com';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  // Auth endpoints
  static const String register = '/api/Authenticate/register';
  static const String requestOtp = '/api/Authenticate/request-otp';
  static const String verifyOtp = '/api/Authenticate/verify-otp';
  static const String login = '/api/Authenticate/login';
  static const String me = '/api/Authenticate/me';

  // SinhVien endpoints
  static const String sinhVien = '/api/SinhVien';
  static String sinhVienById(int id) => '/api/SinhVien/$id';
  static String sinhVienByMaSv(String maSv) => '/api/SinhVien/by-masv/$maSv';
  static String sinhVienByUserId(String userId) => '/api/SinhVien/by-user/$userId';

  // MonHoc endpoints
  static const String monHoc = '/api/MonHoc';
  static String monHocById(int id) => '/api/MonHoc/$id';

  // LopHocPhan endpoints
  static const String lopHocPhan = '/api/LopHocPhan';
  static String lopHocPhanById(int id) => '/api/LopHocPhan/$id';
  static String lopHocPhanSinhViens(int id) => '/api/LopHocPhan/$id/sinh-viens';
  static String themSinhVienVaoLop(int lopId, int svId) => '/api/LopHocPhan/$lopId/them-sinh-vien/$svId';
  static String xoaSinhVienKhoiLop(int lopId, int svId) => '/api/LopHocPhan/$lopId/xoa-sinh-vien/$svId';

  // BuoiDiemDanh endpoints
  static const String buoiDiemDanh = '/api/BuoiDiemDanh';
  static String buoiDiemDanhById(int id) => '/api/BuoiDiemDanh/$id';
  static String buoiDiemDanhByLop(int lopId) => '/api/BuoiDiemDanh/by-lophocphan/$lopId';
  static String dongMoBuoiDiemDanh(int id) => '/api/BuoiDiemDanh/$id/dong-mo';

  // DiemDanh endpoints
  static const String diemDanh = '/api/DiemDanh';
  static String diemDanhById(int id) => '/api/DiemDanh/$id';
  static String diemDanhByBuoi(int buoiId) => '/api/DiemDanh/by-buoi/$buoiId';
  static String diemDanhBySinhVien(int svId) => '/api/DiemDanh/by-sinh-vien/$svId';
  static const String checkIn = '/api/DiemDanh/check-in';

  // DonNghiPhep endpoints
  static const String donNghiPhep = '/api/DonNghiPhep';
  static String donNghiPhepById(int id) => '/api/DonNghiPhep/$id';
  static String donNghiPhepBySinhVien(int svId) => '/api/DonNghiPhep/by-sinh-vien/$svId';
  static String duyetDonNghiPhep(int id) => '/api/DonNghiPhep/$id/duyet';

  // ThongKe endpoints
  static String canhBaoCamThi(int lopId) => '/api/ThongKe/canh-bao-cam-thi/$lopId';
  static const String thongKeTongQuan = '/api/ThongKe/tong-quan';
  static String thongKeSinhVien(int svId) => '/api/ThongKe/sinh-vien/$svId';

  // Upload & OCR endpoints
  static const String uploadAnhMinhChung = '/api/Upload/anh-minh-chung';
  static const String dichAnhOcr = '/api/Upload/dich-anh-ocr';
}

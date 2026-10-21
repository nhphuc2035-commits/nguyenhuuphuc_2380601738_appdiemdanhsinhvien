class ThongKeTongQuan {
  final int tongSoMonHoc;
  final int tongSoLopHocPhan;
  final int tongSoSinhVien;
  final int tongSoBuoiDiemDanhHomNay;
  final int tongSoLuotDiemDanhHomNay;
  final int soSinhVienNguyCoCamThiToanTruong;

  ThongKeTongQuan({
    required this.tongSoMonHoc,
    required this.tongSoLopHocPhan,
    required this.tongSoSinhVien,
    required this.tongSoBuoiDiemDanhHomNay,
    required this.tongSoLuotDiemDanhHomNay,
    required this.soSinhVienNguyCoCamThiToanTruong,
  });

  factory ThongKeTongQuan.fromJson(Map<String, dynamic> json) {
    return ThongKeTongQuan(
      tongSoMonHoc: json['tongSoMonHoc'] is int
          ? json['tongSoMonHoc']
          : int.tryParse(json['tongSoMonHoc']?.toString() ?? '0') ?? 0,
      tongSoLopHocPhan: json['tongSoLopHocPhan'] is int
          ? json['tongSoLopHocPhan']
          : int.tryParse(json['tongSoLopHocPhan']?.toString() ?? '0') ?? 0,
      tongSoSinhVien: json['tongSoSinhVien'] is int
          ? json['tongSoSinhVien']
          : int.tryParse(json['tongSoSinhVien']?.toString() ?? '0') ?? 0,
      tongSoBuoiDiemDanhHomNay: json['tongSoBuoiDiemDanhHomNay'] is int
          ? json['tongSoBuoiDiemDanhHomNay']
          : int.tryParse(json['tongSoBuoiDiemDanhHomNay']?.toString() ?? '0') ?? 0,
      tongSoLuotDiemDanhHomNay: json['tongSoLuotDiemDanhHomNay'] is int
          ? json['tongSoLuotDiemDanhHomNay']
          : int.tryParse(json['tongSoLuotDiemDanhHomNay']?.toString() ?? '0') ?? 0,
      soSinhVienNguyCoCamThiToanTruong: json['soSinhVienNguyCoCamThiToanTruong'] is int
          ? json['soSinhVienNguyCoCamThiToanTruong']
          : int.tryParse(json['soSinhVienNguyCoCamThiToanTruong']?.toString() ?? '0') ?? 0,
    );
  }
}

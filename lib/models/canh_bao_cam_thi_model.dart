class CanhBaoCamThiModel {
  final int lopHocPhanId;
  final String maLopHocPhan;
  final String tenMonHoc;
  final int tongSinhVien;
  final int tongBuoiDaDiemDanh;
  final int soSinhVienNguyCoCamThi;
  final int soSinhVienBiCamThi;
  final List<SinhVienCanhBao> danhSachSinhVien;

  CanhBaoCamThiModel({
    required this.lopHocPhanId,
    required this.maLopHocPhan,
    required this.tenMonHoc,
    required this.tongSinhVien,
    required this.tongBuoiDaDiemDanh,
    required this.soSinhVienNguyCoCamThi,
    required this.soSinhVienBiCamThi,
    required this.danhSachSinhVien,
  });

  factory CanhBaoCamThiModel.fromJson(Map<String, dynamic> json) {
    List<SinhVienCanhBao> list = [];
    if (json['danhSachSinhVien'] is List) {
      for (var item in json['danhSachSinhVien']) {
        list.add(SinhVienCanhBao.fromJson(item));
      }
    }

    return CanhBaoCamThiModel(
      lopHocPhanId: json['lopHocPhanId'] is int
          ? json['lopHocPhanId']
          : int.tryParse(json['lopHocPhanId']?.toString() ?? '0') ?? 0,
      maLopHocPhan: json['maLopHocPhan']?.toString() ?? '',
      tenMonHoc: json['tenMonHoc']?.toString() ?? '',
      tongSinhVien: json['tongSinhVien'] is int
          ? json['tongSinhVien']
          : int.tryParse(json['tongSinhVien']?.toString() ?? '0') ?? 0,
      tongBuoiDaDiemDanh: json['tongBuoiDaDiemDanh'] is int
          ? json['tongBuoiDaDiemDanh']
          : int.tryParse(json['tongBuoiDaDiemDanh']?.toString() ?? '0') ?? 0,
      soSinhVienNguyCoCamThi: json['soSinhVienNguyCoCamThi'] is int
          ? json['soSinhVienNguyCoCamThi']
          : int.tryParse(json['soSinhVienNguyCoCamThi']?.toString() ?? '0') ?? 0,
      soSinhVienBiCamThi: json['soSinhVienBiCamThi'] is int
          ? json['soSinhVienBiCamThi']
          : int.tryParse(json['soSinhVienBiCamThi']?.toString() ?? '0') ?? 0,
      danhSachSinhVien: list,
    );
  }
}

class SinhVienCanhBao {
  final int sinhVienId;
  final String maSV;
  final String hoTen;
  final String? lop;
  final int tongSoBuoi;
  final int soBuoiCoMat;
  final int soBuoiDiTre;
  final int soBuoiVang;
  final int soBuoiVangCoPhep;
  final double tiLeVangPhanTram;
  final String mucDoCanhBao; // "BinhThuong", "CanhBaoNguyCo", "BiCamThi", "ChuY", "DiTre"
  final String khuyenNghi;

  SinhVienCanhBao({
    required this.sinhVienId,
    required this.maSV,
    required this.hoTen,
    this.lop,
    required this.tongSoBuoi,
    required this.soBuoiCoMat,
    this.soBuoiDiTre = 0,
    required this.soBuoiVang,
    required this.soBuoiVangCoPhep,
    required this.tiLeVangPhanTram,
    required this.mucDoCanhBao,
    required this.khuyenNghi,
  });

  bool get isBiCamThi => mucDoCanhBao.toLowerCase().contains('camthi');
  bool get isNguyCo => mucDoCanhBao.toLowerCase().contains('nguyco');
  bool get isChuY => mucDoCanhBao.toLowerCase().contains('chuy') || (soBuoiVang > 0 && !isBiCamThi && !isNguyCo);
  bool get isDiTre => mucDoCanhBao.toLowerCase().contains('ditre') || (soBuoiDiTre > 0 && soBuoiVang == 0);
  bool get isAnToan => !isBiCamThi && !isNguyCo && !isChuY && !isDiTre;

  factory SinhVienCanhBao.fromJson(Map<String, dynamic> json) {
    return SinhVienCanhBao(
      sinhVienId: json['sinhVienId'] is int
          ? json['sinhVienId']
          : int.tryParse(json['sinhVienId']?.toString() ?? '0') ?? 0,
      maSV: json['maSV']?.toString() ?? '',
      hoTen: json['hoTen']?.toString() ?? '',
      lop: json['lop']?.toString(),
      tongSoBuoi: json['tongSoBuoi'] is int
          ? json['tongSoBuoi']
          : int.tryParse(json['tongSoBuoi']?.toString() ?? '15') ?? 15,
      soBuoiCoMat: json['soBuoiCoMat'] is int
          ? json['soBuoiCoMat']
          : int.tryParse(json['soBuoiCoMat']?.toString() ?? '0') ?? 0,
      soBuoiDiTre: json['soBuoiDiTre'] is int
          ? json['soBuoiDiTre']
          : int.tryParse(json['soBuoiDiTre']?.toString() ?? '0') ?? 0,
      soBuoiVang: json['soBuoiVang'] is int
          ? json['soBuoiVang']
          : int.tryParse(json['soBuoiVang']?.toString() ?? '0') ?? 0,
      soBuoiVangCoPhep: json['soBuoiVangCoPhep'] is int
          ? json['soBuoiVangCoPhep']
          : int.tryParse(json['soBuoiVangCoPhep']?.toString() ?? '0') ?? 0,
      tiLeVangPhanTram: json['tiLeVangPhanTram'] != null
          ? (json['tiLeVangPhanTram'] as num).toDouble()
          : 0.0,
      mucDoCanhBao: json['mucDoCanhBao']?.toString() ?? 'BinhThuong',
      khuyenNghi: json['khuyenNghi']?.toString() ?? '',
    );
  }
}

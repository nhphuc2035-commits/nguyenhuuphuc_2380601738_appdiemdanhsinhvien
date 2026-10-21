import 'buoi_diem_danh_model.dart';
import 'sinh_vien_model.dart';

class DiemDanh {
  final int id;
  final int buoiDiemDanhId;
  final BuoiDiemDanh? buoiDiemDanh;
  final int sinhVienId;
  final SinhVien? sinhVien;
  final String? thoiGianDiemDanh;
  final String phuongThuc; // "VanTay", "QRCode", "KhuonMat", "ThuCong"
  final double? viTriViDo;
  final double? viTriKinhDo;
  final double? khoangCachMet;
  final String trangThai; // "CoMat", "DiTre", "Vang", "VangCoPhep"
  final bool hopLe;
  final String? lyDoKhongHopLe;
  final String? ghiChu;
  final String? anhMinhChung;

  DiemDanh({
    required this.id,
    required this.buoiDiemDanhId,
    this.buoiDiemDanh,
    required this.sinhVienId,
    this.sinhVien,
    this.thoiGianDiemDanh,
    this.phuongThuc = "VanTay",
    this.viTriViDo,
    this.viTriKinhDo,
    this.khoangCachMet,
    this.trangThai = "CoMat",
    this.hopLe = true,
    this.lyDoKhongHopLe,
    this.ghiChu,
    this.anhMinhChung,
  });

  factory DiemDanh.fromJson(Map<String, dynamic> json) {
    return DiemDanh(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      buoiDiemDanhId: json['buoiDiemDanhId'] is int
          ? json['buoiDiemDanhId']
          : int.tryParse(json['buoiDiemDanhId']?.toString() ?? '0') ?? 0,
      buoiDiemDanh: json['buoiDiemDanh'] != null ? BuoiDiemDanh.fromJson(json['buoiDiemDanh']) : null,
      sinhVienId: json['sinhVienId'] is int
          ? json['sinhVienId']
          : int.tryParse(json['sinhVienId']?.toString() ?? '0') ?? 0,
      sinhVien: json['sinhVien'] != null ? SinhVien.fromJson(json['sinhVien']) : null,
      thoiGianDiemDanh: json['thoiGianDiemDanh']?.toString(),
      phuongThuc: json['phuongThuc']?.toString() ?? 'VanTay',
      viTriViDo: json['viTriViDo'] != null ? (json['viTriViDo'] as num).toDouble() : null,
      viTriKinhDo: json['viTriKinhDo'] != null ? (json['viTriKinhDo'] as num).toDouble() : null,
      khoangCachMet: json['khoangCachMet'] != null ? (json['khoangCachMet'] as num).toDouble() : null,
      trangThai: json['trangThai']?.toString() ?? 'CoMat',
      hopLe: json['hopLe'] == true || json['hopLe'] == 1,
      lyDoKhongHopLe: json['lyDoKhongHopLe']?.toString(),
      ghiChu: json['ghiChu']?.toString(),
      anhMinhChung: json['anhMinhChung']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id > 0) 'id': id,
    'buoiDiemDanhId': buoiDiemDanhId,
    'sinhVienId': sinhVienId,
    'thoiGianDiemDanh': thoiGianDiemDanh,
    'phuongThuc': phuongThuc,
    'viTriViDo': viTriViDo,
    'viTriKinhDo': viTriKinhDo,
    'trangThai': trangThai,
    'hopLe': hopLe,
    'lyDoKhongHopLe': lyDoKhongHopLe,
    'ghiChu': ghiChu,
    'anhMinhChung': anhMinhChung,
  };
}

class CheckInRequestDto {
  final int buoiDiemDanhId;
  final String maSV;
  final String? maQRCode;
  final double viTriViDo;
  final double viTriKinhDo;
  final String phuongThuc;
  final String? anhMinhChung;
  final String? ghiChu;

  CheckInRequestDto({
    required this.buoiDiemDanhId,
    required this.maSV,
    this.maQRCode,
    required this.viTriViDo,
    required this.viTriKinhDo,
    required this.phuongThuc,
    this.anhMinhChung,
    this.ghiChu,
  });

  Map<String, dynamic> toJson() => {
    'buoiDiemDanhId': buoiDiemDanhId,
    'maSV': maSV,
    'maQRCode': maQRCode,
    'viTriViDo': viTriViDo,
    'viTriKinhDo': viTriKinhDo,
    'phuongThuc': phuongThuc,
    'anhMinhChung': anhMinhChung,
    'ghiChu': ghiChu,
  };
}

class CheckInResponseDto {
  final bool thanhCong;
  final String thongBao;
  final String? trangThai;
  final double? khoangCachMet;
  final String? thoiGian;

  CheckInResponseDto({
    required this.thanhCong,
    required this.thongBao,
    this.trangThai,
    this.khoangCachMet,
    this.thoiGian,
  });

  factory CheckInResponseDto.fromJson(Map<String, dynamic> json) {
    return CheckInResponseDto(
      thanhCong: json['thanhCong'] == true,
      thongBao: json['thongBao']?.toString() ?? '',
      trangThai: json['trangThai']?.toString(),
      khoangCachMet: json['khoangCachMet'] != null ? (json['khoangCachMet'] as num).toDouble() : null,
      thoiGian: json['thoiGian']?.toString(),
    );
  }
}

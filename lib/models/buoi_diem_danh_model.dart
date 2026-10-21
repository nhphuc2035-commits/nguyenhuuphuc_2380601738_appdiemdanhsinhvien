import 'lop_hoc_phan_model.dart';

class BuoiDiemDanh {
  final int id;
  final int lopHocPhanId;
  final LopHocPhan? lopHocPhan;
  final int soThuTuBuoi;
  final String ngayDiemDanh;
  final String? gioBatDau;
  final String? gioKetThuc;
  final String? maQRCode;
  final double viTriViDo;
  final double viTriKinhDo;
  final double banKinhChoPhepMet;
  final String trangThai; // "Mo", "Dong", "ChuaDiemDanh", "DaKetThuc"
  final String? ghiChu;

  BuoiDiemDanh({
    required this.id,
    required this.lopHocPhanId,
    this.lopHocPhan,
    required this.soThuTuBuoi,
    required this.ngayDiemDanh,
    this.gioBatDau,
    this.gioKetThuc,
    this.maQRCode,
    this.viTriViDo = 10.8018,
    this.viTriKinhDo = 106.7142,
    this.banKinhChoPhepMet = 100.0,
    this.trangThai = "Mo",
    this.ghiChu,
  });

  bool get isMo =>
      trangThai.toLowerCase() == 'mo' || trangThai.toLowerCase() == 'dangmo';

  factory BuoiDiemDanh.fromJson(Map<String, dynamic> json) {
    return BuoiDiemDanh(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      lopHocPhanId: json['lopHocPhanId'] is int
          ? json['lopHocPhanId']
          : int.tryParse(json['lopHocPhanId']?.toString() ?? '0') ?? 0,
      lopHocPhan: json['lopHocPhan'] != null ? LopHocPhan.fromJson(json['lopHocPhan']) : null,
      soThuTuBuoi: json['soThuTuBuoi'] is int
          ? json['soThuTuBuoi']
          : int.tryParse(json['soThuTuBuoi']?.toString() ?? '1') ?? 1,
      ngayDiemDanh: json['ngayDiemDanh']?.toString() ?? '',
      gioBatDau: json['gioBatDau']?.toString(),
      gioKetThuc: json['gioKetThuc']?.toString(),
      maQRCode: json['maQRCode']?.toString(),
      viTriViDo: (json['viTriViDo'] is num) ? (json['viTriViDo'] as num).toDouble() : 10.8018,
      viTriKinhDo: (json['viTriKinhDo'] is num) ? (json['viTriKinhDo'] as num).toDouble() : 106.7142,
      banKinhChoPhepMet: (json['banKinhChoPhepMet'] is num)
          ? (json['banKinhChoPhepMet'] as num).toDouble()
          : 100.0,
      trangThai: json['trangThai']?.toString() ?? 'Mo',
      ghiChu: json['ghiChu']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id > 0) 'id': id,
    'lopHocPhanId': lopHocPhanId,
    'soThuTuBuoi': soThuTuBuoi,
    'ngayDiemDanh': ngayDiemDanh,
    'gioBatDau': gioBatDau,
    'gioKetThuc': gioKetThuc,
    'maQRCode': maQRCode,
    'viTriViDo': viTriViDo,
    'viTriKinhDo': viTriKinhDo,
    'banKinhChoPhepMet': banKinhChoPhepMet,
    'trangThai': trangThai,
    'ghiChu': ghiChu,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuoiDiemDanh &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

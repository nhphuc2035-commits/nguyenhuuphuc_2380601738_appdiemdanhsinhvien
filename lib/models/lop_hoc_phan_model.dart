import 'mon_hoc_model.dart';
import 'sinh_vien_model.dart';

class LopHocPhan {
  final int id;
  final String maLopHocPhan;
  final int monHocId;
  final MonHoc? monHoc;
  final String? giangVien;
  final String? phongHoc;
  final String? hocKy;
  final String? namHoc;
  final int soBuoi;
  final List<SinhVien>? sinhViens;

  LopHocPhan({
    required this.id,
    required this.maLopHocPhan,
    required this.monHocId,
    this.monHoc,
    this.giangVien,
    this.phongHoc,
    this.hocKy,
    this.namHoc,
    this.soBuoi = 15,
    this.sinhViens,
  });

  factory LopHocPhan.fromJson(Map<String, dynamic> json) {
    List<SinhVien> svList = [];
    if (json['sinhVienLopHocPhans'] is List) {
      for (var item in json['sinhVienLopHocPhans']) {
        if (item['sinhVien'] != null) {
          svList.add(SinhVien.fromJson(item['sinhVien']));
        }
      }
    } else if (json['sinhViens'] is List) {
      for (var item in json['sinhViens']) {
        svList.add(SinhVien.fromJson(item));
      }
    }

    return LopHocPhan(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      maLopHocPhan: json['maLopHocPhan']?.toString() ?? '',
      monHocId: json['monHocId'] is int ? json['monHocId'] : int.tryParse(json['monHocId']?.toString() ?? '0') ?? 0,
      monHoc: json['monHoc'] != null ? MonHoc.fromJson(json['monHoc']) : null,
      giangVien: json['giangVien']?.toString(),
      phongHoc: json['phongHoc']?.toString(),
      hocKy: json['hocKy']?.toString(),
      namHoc: json['namHoc']?.toString(),
      soBuoi: json['soBuoi'] is int ? json['soBuoi'] : int.tryParse(json['soBuoi']?.toString() ?? '15') ?? 15,
      sinhViens: svList,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id > 0) 'id': id,
    'maLopHocPhan': maLopHocPhan,
    'monHocId': monHocId,
    'giangVien': giangVien,
    'phongHoc': phongHoc,
    'hocKy': hocKy,
    'namHoc': namHoc,
    'soBuoi': soBuoi,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LopHocPhan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

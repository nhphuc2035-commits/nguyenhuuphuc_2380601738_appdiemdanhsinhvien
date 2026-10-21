import 'lop_hoc_phan_model.dart';
import 'sinh_vien_model.dart';

class DonNghiPhep {
  final int id;
  final int sinhVienId;
  final SinhVien? sinhVien;
  final int lopHocPhanId;
  final LopHocPhan? lopHocPhan;
  final String ngayNghi;
  final String lyDo;
  final String? minhChungUrl;
  final String trangThai; // "ChoDuyet", "DaDuyet", "TuChoi"
  final String? ngayGui;
  final String? phanHoiGiaoVien;

  DonNghiPhep({
    required this.id,
    required this.sinhVienId,
    this.sinhVien,
    required this.lopHocPhanId,
    this.lopHocPhan,
    required this.ngayNghi,
    required this.lyDo,
    this.minhChungUrl,
    this.trangThai = "ChoDuyet",
    this.ngayGui,
    this.phanHoiGiaoVien,
  });

  factory DonNghiPhep.fromJson(Map<String, dynamic> json) {
    return DonNghiPhep(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      sinhVienId: json['sinhVienId'] is int
          ? json['sinhVienId']
          : int.tryParse(json['sinhVienId']?.toString() ?? '0') ?? 0,
      sinhVien: json['sinhVien'] != null ? SinhVien.fromJson(json['sinhVien']) : null,
      lopHocPhanId: json['lopHocPhanId'] is int
          ? json['lopHocPhanId']
          : int.tryParse(json['lopHocPhanId']?.toString() ?? '0') ?? 0,
      lopHocPhan: json['lopHocPhan'] != null ? LopHocPhan.fromJson(json['lopHocPhan']) : null,
      ngayNghi: json['ngayNghi']?.toString() ?? '',
      lyDo: json['lyDo']?.toString() ?? '',
      minhChungUrl: json['minhChungUrl']?.toString(),
      trangThai: json['trangThai']?.toString() ?? 'ChoDuyet',
      ngayGui: json['ngayGui']?.toString(),
      phanHoiGiaoVien: json['phanHoiGiaoVien']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id > 0) 'id': id,
    'sinhVienId': sinhVienId,
    'lopHocPhanId': lopHocPhanId,
    'ngayNghi': ngayNghi.contains('T') ? ngayNghi : '${ngayNghi}T00:00:00Z',
    'lyDo': lyDo,
    if (minhChungUrl != null && minhChungUrl!.isNotEmpty) 'minhChungUrl': minhChungUrl,
    'trangThai': trangThai,
    if (ngayGui != null && ngayGui!.isNotEmpty) 'ngayGui': ngayGui,
    if (phanHoiGiaoVien != null && phanHoiGiaoVien!.isNotEmpty) 'phanHoiGiaoVien': phanHoiGiaoVien,
  };
}

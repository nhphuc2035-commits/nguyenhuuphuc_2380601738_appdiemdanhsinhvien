class SinhVien {
  final int id;
  final String maSV;
  final String hoTen;
  final String? email;
  final String? soDienThoai;
  final String? lop;
  final String? khoa;
  final String? anhDaiDien;
  final String? userId;
  final String? ngayTao;
  final bool trangThai;

  SinhVien({
    required this.id,
    required this.maSV,
    required this.hoTen,
    this.email,
    this.soDienThoai,
    this.lop,
    this.khoa,
    this.anhDaiDien,
    this.userId,
    this.ngayTao,
    this.trangThai = true,
  });

  factory SinhVien.fromJson(Map<String, dynamic> json) {
    return SinhVien(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      maSV: json['maSV']?.toString() ?? json['maSv']?.toString() ?? '',
      hoTen: json['hoTen']?.toString() ?? '',
      email: json['email']?.toString(),
      soDienThoai: json['soDienThoai']?.toString(),
      lop: json['lop']?.toString(),
      khoa: json['khoa']?.toString(),
      anhDaiDien: json['anhDaiDien']?.toString(),
      userId: json['userId']?.toString(),
      ngayTao: json['ngayTao']?.toString(),
      trangThai: json['trangThai'] == true || json['trangThai'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id > 0) 'id': id,
    'maSV': maSV,
    'hoTen': hoTen,
    'email': email,
    'soDienThoai': soDienThoai,
    'lop': lop,
    'khoa': khoa,
    'anhDaiDien': anhDaiDien,
    'userId': userId,
    'trangThai': trangThai,
  };
}

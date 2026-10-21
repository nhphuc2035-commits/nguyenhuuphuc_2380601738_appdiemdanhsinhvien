import 'sinh_vien_model.dart';

class UserModel {
  final String id;
  final String userName;
  final String email;
  final String? hoTen;
  final String? maSV;
  final List<String> roles;
  final SinhVien? sinhVien;

  UserModel({
    required this.id,
    required this.userName,
    required this.email,
    this.hoTen,
    this.maSV,
    required this.roles,
    this.sinhVien,
  });

  bool get isAdmin => roles.any((r) => r.toLowerCase() == 'admin');
  bool get isSinhVien => roles.any((r) => r.toLowerCase() == 'sinhvien');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles = [];
    if (json['roles'] != null) {
      parsedRoles = List<String>.from(json['roles']);
    } else if (json['role'] != null) {
      parsedRoles = [json['role'].toString()];
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      userName: json['userName']?.toString() ?? json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      hoTen: json['hoTen']?.toString(),
      maSV: json['maSV']?.toString() ?? json['maSv']?.toString(),
      roles: parsedRoles,
      sinhVien: json['sinhVien'] != null ? SinhVien.fromJson(json['sinhVien']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userName': userName,
    'email': email,
    'hoTen': hoTen,
    'maSV': maSV,
    'roles': roles,
    'sinhVien': sinhVien?.toJson(),
  };
}

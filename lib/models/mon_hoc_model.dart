class MonHoc {
  final int id;
  final String maMon;
  final String tenMon;
  final int soTinChi;
  final String? moTa;

  MonHoc({
    required this.id,
    required this.maMon,
    required this.tenMon,
    required this.soTinChi,
    this.moTa,
  });

  factory MonHoc.fromJson(Map<String, dynamic> json) {
    return MonHoc(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      maMon: json['maMon']?.toString() ?? '',
      tenMon: json['tenMon']?.toString() ?? '',
      soTinChi: json['soTinChi'] is int ? json['soTinChi'] : int.tryParse(json['soTinChi']?.toString() ?? '3') ?? 3,
      moTa: json['moTa']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id > 0) 'id': id,
    'maMon': maMon,
    'tenMon': tenMon,
    'soTinChi': soTinChi,
    'moTa': moTa,
  };
}

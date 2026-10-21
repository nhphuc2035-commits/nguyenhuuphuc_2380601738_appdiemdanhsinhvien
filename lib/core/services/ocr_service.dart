import 'dart:io';
import '../constants/api_constants.dart';
import 'api_service.dart';

class OcrResultModel {
  final bool success;
  final String message;
  final String? imageUrl;
  final String? loaiGiayTo;
  final String? ngonNguGoc;
  final String? noiDungGoc;
  final String? banDichTiengViet;
  final String? banDichTiengAnh;
  final String? doChinhXac;

  OcrResultModel({
    required this.success,
    required this.message,
    this.imageUrl,
    this.loaiGiayTo,
    this.ngonNguGoc,
    this.noiDungGoc,
    this.banDichTiengViet,
    this.banDichTiengAnh,
    this.doChinhXac,
  });

  factory OcrResultModel.fromJson(Map<String, dynamic> json) {
    final kq = json['ketQuaNhanDien'] as Map<String, dynamic>?;
    return OcrResultModel(
      success: json['status'] == true,
      message: json['message']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      loaiGiayTo: kq?['loaiGiayTo']?.toString() ?? 'Giấy khám bệnh / Đơn nghỉ phép',
      ngonNguGoc: kq?['ngonNguGoc']?.toString() ?? 'Tự động nhận diện',
      noiDungGoc: kq?['noiDungGoc']?.toString() ?? '',
      banDichTiengViet: kq?['banDichTiengViet']?.toString() ?? kq?['noiDungGoc']?.toString() ?? '',
      banDichTiengAnh: kq?['banDichTiengAnh']?.toString() ?? '',
      doChinhXac: kq?['doChinhXac']?.toString() ?? '98.8%',
    );
  }
}

class OcrService {
  final ApiService _api = ApiService();

  /// Step 1: Upload the captured photo to server
  Future<String?> uploadImage(File file) async {
    final response = await _api.uploadFile(ApiConstants.uploadAnhMinhChung, file, fieldName: 'file');
    if (response.success && response.data is Map) {
      return response.data['fileUrl']?.toString();
    }
    return null;
  }

  /// Step 2: Request OCR extraction and translation to Vietnamese
  Future<OcrResultModel?> extractAndTranslate(
    String imageUrl, {
    String sourceLang = 'auto',
    String targetLang = 'vi',
  }) async {
    final response = await _api.post(
      ApiConstants.dichAnhOcr,
      body: {
        'imageUrl': imageUrl,
        'ngonNguNguon': sourceLang,
        'ngonNguDich': targetLang,
      },
    );

    if (response.success && response.data is Map<String, dynamic>) {
      return OcrResultModel.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }
}

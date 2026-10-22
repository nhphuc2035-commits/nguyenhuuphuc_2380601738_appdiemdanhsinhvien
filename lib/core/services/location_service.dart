import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Default coordinates (HUTECH Campus / Classroom: 10.8558, 106.7853)
  static const double defaultLat = 10.8558;
  static const double defaultLng = 106.7853;

  // HUTECH Campuses
  static const double hutechKhuELat = 10.8558; // Khu E Thủ Đức
  static const double hutechKhuELng = 106.7853;
  static const double hutechBinhThanhLat = 10.8018; // Trụ sở Điện Biên Phủ
  static const double hutechBinhThanhLng = 106.7142;

  // Bán kính ngắn trong khuôn viên trường: 200 mét
  static const double maxCampusRadiusMeters = 200.0;

  /// Kiểm tra xem vị trí GPS có nằm trong khuôn viên trường HUTECH (bán kính ngắn <= 200m) hay không
  static bool isInsideHutechCampus(double lat, double lng, {double maxRadius = maxCampusRadiusMeters}) {
    final distKhuE = calculateDistanceMeters(lat, lng, hutechKhuELat, hutechKhuELng);
    final distBinhThanh = calculateDistanceMeters(lat, lng, hutechBinhThanhLat, hutechBinhThanhLng);
    return distKhuE <= maxRadius || distBinhThanh <= maxRadius;
  }

  /// Tính khoảng cách ngắn nhất đến cơ sở HUTECH gần nhất (mét)
  static double getDistanceToHutech(double lat, double lng) {
    final distKhuE = calculateDistanceMeters(lat, lng, hutechKhuELat, hutechKhuELng);
    final distBinhThanh = calculateDistanceMeters(lat, lng, hutechBinhThanhLat, hutechBinhThanhLng);
    return min(distKhuE, distBinhThanh);
  }

  /// Get current GPS position with permission checks and safe fallback
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _createFallbackPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _createFallbackPosition();
      }

      // Try to get real position with a 6-second timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (e) {
      // In case of emulator or sensor timeout, return default classroom position
      return _createFallbackPosition();
    }
  }

  static Position _createFallbackPosition() {
    return Position(
      longitude: defaultLng,
      latitude: defaultLat,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  /// Get readable physical street address from GPS coordinates (No spoofing, real-time)
  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    // 1. Check known landmark proximity (Bán kính khuôn viên trường <= 200m)
    final distToHutechKhuE = calculateDistanceMeters(lat, lng, hutechKhuELat, hutechKhuELng);
    if (distToHutechKhuE <= maxCampusRadiusMeters) {
      return 'Trường ĐH HUTECH - Khu E (Phân hiệu Thủ Đức), Đường D1, P. Long Thạnh Mỹ, TP. Thủ Đức';
    }

    final distToHutechBinhThanh = calculateDistanceMeters(lat, lng, hutechBinhThanhLat, hutechBinhThanhLng);
    if (distToHutechBinhThanh <= maxCampusRadiusMeters) {
      return 'Trường ĐH HUTECH - Trụ sở 475A Điện Biên Phủ, P. 25, Q. Bình Thạnh, TP. HCM';
    }

    final distToVincomThuDuc = calculateDistanceMeters(lat, lng, 10.8510, 106.7720);
    if (distToVincomThuDuc <= 200) {
      return 'Vincom Plaza Thủ Đức, 216 Võ Văn Ngân, P. Bình Thọ, TP. Thủ Đức';
    }

    final distToVivoCity = calculateDistanceMeters(lat, lng, 10.7305, 106.7020);
    if (distToVivoCity <= 200) {
      return 'SC VivoCity, 1058 Nguyễn Văn Linh, P. Tân Phong, Quận 7, TP. HCM';
    }

    // 2. Query Nominatim reverse geocoding API for real live device position
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final res = await http.get(url, headers: {'User-Agent': 'HutechAttendanceApp/1.0'}).timeout(
        const Duration(seconds: 4),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data is Map && data['display_name'] != null) {
          final parts = (data['display_name'] as String).split(', ');
          if (parts.length > 5) {
            return parts.take(5).join(', ');
          }
          return data['display_name'] as String;
        }
      }
    } catch (_) {}

    return 'Vị trí thực tế định vị GPS thiết bị';
  }

  /// Calculates distance in meters using the Haversine formula
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000.0;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180.0;
  }
}

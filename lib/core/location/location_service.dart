import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';

/// Titik koordinat GPS perangkat.
class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
}

/// Kontrak layanan lokasi agar dapat di-fake saat pengujian.
abstract interface class LocationService {
  Future<LocationPoint> getCurrentPosition();

  double distanceBetweenMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  });
}

/// Implementasi `LocationService` menggunakan `geolocator`.
class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationPoint> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const UnknownException(
        'Layanan lokasi (GPS) tidak aktif. Aktifkan GPS perangkat Anda terlebih dahulu.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const UnknownException(
        'Izin akses lokasi ditolak. Izinkan akses lokasi untuk melakukan absensi.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const UnknownException(
        'Izin akses lokasi ditolak permanen. Aktifkan izin lokasi melalui pengaturan aplikasi.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
    );
  }

  @override
  double distanceBetweenMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

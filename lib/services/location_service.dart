import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../models/station.dart';

class AppLocation {
  final double lat;
  final double lng;
  final double? accuracyMeters;

  const AppLocation({
    required this.lat,
    required this.lng,
    this.accuracyMeters,
  });

  latlng.LatLng get point => latlng.LatLng(lat, lng);

  double distanceKmTo(Station station) => const latlng.Distance().as(
        latlng.LengthUnit.Kilometer,
        point,
        latlng.LatLng(station.lat, station.lng),
      );
}

class TravelEstimate {
  final double distanceKm;
  final int etaMinutes;
  final String provider;
  final bool isEstimated;

  const TravelEstimate({
    required this.distanceKm,
    required this.etaMinutes,
    required this.provider,
    required this.isEstimated,
  });

  factory TravelEstimate.fallback(AppLocation origin, Station station) {
    final straightLineKm = origin.distanceKmTo(station);
    final roadDistanceKm = straightLineKm * (straightLineKm < 3 ? 1.18 : 1.27);
    final averageSpeedKph = roadDistanceKm < 8
        ? 24.0
        : roadDistanceKm < 35
            ? 36.0
            : 52.0;
    final minutes = math.max(2, ((roadDistanceKm / averageSpeedKph) * 60).ceil());
    return TravelEstimate(
      distanceKm: roadDistanceKm,
      etaMinutes: minutes,
      provider: 'Estimated',
      isEstimated: true,
    );
  }
}

class LocationService {
  static AppLocation? lastKnown;

  static Future<AppLocation> determineCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceException(
          'Turn on device location to calculate distance and ETA.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
          'Location permission was denied. You can enable it in app settings.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
          'Location permission is blocked. Enable it from device settings.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    final location = AppLocation(
      lat: position.latitude,
      lng: position.longitude,
      accuracyMeters: position.accuracy,
    );
    lastKnown = location;
    return location;
  }
}

class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => message;
}

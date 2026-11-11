import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationFailureType {
  serviceDisabled,
  denied,
  deniedForever,
  timeout,
  unavailable,
  invalidEvidence,
  stale,
  future,
}

class LocationFailure implements Exception {
  const LocationFailure(this.type, this.message);

  final LocationFailureType type;
  final String message;

  @override
  String toString() => message;
}

/// A fresh GPS fix as reported by the device. Branch coordinates are never
/// known to the app; the backend decides whether the position is acceptable.
class DevicePosition {
  const DevicePosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  Map<String, dynamic> toRequestFields() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'location_timestamp': timestamp.toUtc().toIso8601String(),
      };
}

class LocationService {
  static const Duration _timeout = Duration(seconds: 20);
  static const Duration _maximumFixAge = Duration(seconds: 120);
  static const Duration _maximumFutureSkew = Duration(seconds: 30);

  static void validateFix(DevicePosition fix, {required DateTime now}) {
    if (!fix.latitude.isFinite ||
        fix.latitude < -90 ||
        fix.latitude > 90 ||
        !fix.longitude.isFinite ||
        fix.longitude < -180 ||
        fix.longitude > 180 ||
        !fix.accuracy.isFinite ||
        fix.accuracy < 0) {
      throw const LocationFailure(
        LocationFailureType.invalidEvidence,
        'The device returned invalid location evidence. Please try again.',
      );
    }

    final age = now.toUtc().difference(fix.timestamp.toUtc());
    if (age > _maximumFixAge) {
      throw const LocationFailure(
        LocationFailureType.stale,
        'Your location fix has expired. Verify your location again.',
      );
    }
    if (age < -_maximumFutureSkew) {
      throw const LocationFailure(
        LocationFailureType.future,
        'The device location timestamp is invalid. Please try again.',
      );
    }
  }

  /// Checks the location service and permission, then returns a fresh high-accuracy fix.
  /// Throws [LocationFailure] with a user-facing message for every failure case.
  Future<DevicePosition> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        LocationFailureType.serviceDisabled,
        'Location services are turned off. Turn on GPS to continue.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        LocationFailureType.denied,
        'Location permission is required to verify that you are at your branch.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureType.deniedForever,
        'Location permission is blocked. Enable it for Lyra Pulse in the app settings.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: _timeout),
      );
      final fix = DevicePosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
      validateFix(fix, now: DateTime.now());
      return fix;
    } on TimeoutException {
      throw const LocationFailure(
        LocationFailureType.timeout,
        'Getting your location took too long. Move to an open area and try again.',
      );
    } on LocationServiceDisabledException {
      throw const LocationFailure(
        LocationFailureType.serviceDisabled,
        'Location services are turned off. Turn on GPS to continue.',
      );
    } on LocationFailure {
      rethrow;
    } catch (_) {
      throw const LocationFailure(
        LocationFailureType.unavailable,
        'Unable to get an accurate location. Move to an open area and try again.',
      );
    }
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

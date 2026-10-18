import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationFailureType { serviceDisabled, denied, deniedForever, timeout, unavailable }

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
  const DevicePosition({required this.latitude, required this.longitude, required this.accuracy});

  final double latitude;
  final double longitude;
  final double accuracy;
}

class LocationService {
  static const Duration _timeout = Duration(seconds: 20);

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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: _timeout),
      );
      if (!position.latitude.isFinite || !position.longitude.isFinite || !position.accuracy.isFinite) {
        throw const LocationFailure(
          LocationFailureType.unavailable,
          'Unable to get an accurate location. Move to an open area and try again.',
        );
      }
      return DevicePosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
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

import 'dart:async';

import 'package:get/get.dart';

/// Controls the live working-hours timer displayed on the Home screen.
///
/// Start this timer only after attendance check-in succeeds.
/// Stop it only after attendance check-out succeeds.
class HomeController extends GetxController {
  final Rx<Duration> workingDuration = Duration.zero.obs;
  final RxBool isWorking = false.obs;

  DateTime? _checkInDateTime;
  Timer? _timer;

  /// Starts or resumes the timer after a successful check-in.
  ///
  /// Pass the actual check-in timestamp when it is available.
  void startWorkingTimer({DateTime? checkInTime}) {
    final startTime = checkInTime ?? DateTime.now();

    _checkInDateTime = startTime;
    _timer?.cancel();
    isWorking.value = true;

    _updateWorkingDuration();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateWorkingDuration(),
    );
  }

  void _updateWorkingDuration() {
    final startTime = _checkInDateTime;

    if (startTime == null || !isWorking.value) return;

    final elapsed = DateTime.now().difference(startTime);
    workingDuration.value = elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Stops the timer after a successful check-out.
  /// The last duration remains visible on the Home screen.
  void stopWorkingTimer() {
    _updateWorkingDuration();
    _timer?.cancel();
    _timer = null;
    isWorking.value = false;
  }

  /// Resets the timer when a new attendance day/session should begin.
  void resetWorkingTimer() {
    _timer?.cancel();
    _timer = null;
    _checkInDateTime = null;
    workingDuration.value = Duration.zero;
    isWorking.value = false;
  }

  /// Returns the live duration in HH:MM:SS format.
  String get formattedWorkingTime {
    final duration = workingDuration.value;
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  @override
  void onClose() {
    _timer?.cancel();
    _timer = null;
    super.onClose();
  }
}

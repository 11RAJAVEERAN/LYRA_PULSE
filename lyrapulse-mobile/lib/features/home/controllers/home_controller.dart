
import 'dart:async';

import 'package:get/get.dart';

class HomeController extends GetxController {
  final Rx<Duration> workingDuration = Duration.zero.obs;

  final RxBool isWorking = false.obs;

  DateTime? _checkInDateTime;
  Timer? _timer;

  /// Call this only after check-in is successfully completed.
  void startWorkingTimer({DateTime? checkInTime}) {
    _checkInDateTime = checkInTime ?? DateTime.now();

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

    workingDuration.value =
        elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Call this only after check-out is successfully completed.
  void stopWorkingTimer() {
    _updateWorkingDuration();

    _timer?.cancel();
    _timer = null;
    isWorking.value = false;
  }

  String get formattedWorkingTime {
    final duration = workingDuration.value;

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

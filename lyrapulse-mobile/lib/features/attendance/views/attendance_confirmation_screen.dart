
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'check_in_success_screen.dart';
import 'check_out_success_screen.dart';
import '../controllers/attendance_controller.dart';
import '../../../app/theme/app_colors.dart';

class AttendanceConfirmationScreen extends StatefulWidget {
  final bool isCheckOut;

  const AttendanceConfirmationScreen({
    super.key,
    this.isCheckOut = false,
  });

  @override
  State<AttendanceConfirmationScreen> createState() =>
      _AttendanceConfirmationScreenState();
}

class _AttendanceConfirmationScreenState
    extends State<AttendanceConfirmationScreen> {
  static const Color background = AppColors.hexFFF7FAFE;
  static const Color navy = AppColors.hexFF19356C;
  static const Color blue = AppColors.hexFF3978E8;
  static const Color green = AppColors.hexFF18A66A;
  static const Color textDark = AppColors.hexFF172B4D;
  static const Color textGrey = AppColors.hexFF718096;

  late final AttendanceController attendanceController;

  bool _isSaving = false;
  bool _isLoadingLocation = true;
  String _locationText = 'Getting current location...';
  String _dateText = '';
  Position? _position;

  @override
  void initState() {
    super.initState();

    attendanceController =
        Get.isRegistered<AttendanceController>()
            ? Get.find<AttendanceController>()
            : Get.put(AttendanceController(), permanent: true);

    final now = DateTime.now();
    _dateText = _formatDate(now);

    _loadLocation();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _loadLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Please enable location services.');
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is not available.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String address =
          '${position.latitude.toStringAsFixed(5)}, '
          '${position.longitude.toStringAsFixed(5)}';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = <String?>[
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].where((part) => part != null && part.trim().isNotEmpty);

          final formatted = parts.join(', ');
          if (formatted.isNotEmpty) {
            address = formatted;
          }
        }
      } catch (_) {
        // Keep coordinates if reverse geocoding is unavailable.
      }

      if (!mounted) return;

      setState(() {
        _position = position;
        _locationText = address;
        _isLoadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _locationText = 'Location unavailable';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _confirmAttendance() async {
    if (_isSaving) return;

    if (_isLoadingLocation || _position == null) {
      Get.snackbar(
        'Location Required',
        'Please wait until your current location is verified.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: navy,
        colorText: AppColors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isCheckOut) {
        // Make sure the saved check-in is loaded before checkout.
        if (attendanceController.checkInTime.value == null) {
          Get.snackbar(
            'Check In Required',
            'Please complete your check in before checking out.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: navy,
            colorText: AppColors.white,
            margin: const EdgeInsets.all(16),
          );
          return;
        }

        if (attendanceController.checkOutTime.value != null) {
          Get.snackbar(
            'Already Checked Out',
            'Your check out has already been recorded.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: navy,
            colorText: AppColors.white,
            margin: const EdgeInsets.all(16),
          );
          return;
        }

        await attendanceController.checkOutNow();

        if (attendanceController.checkOutTime.value == null) {
          throw Exception('Check out time was not saved.');
        }

        if (!mounted) return;

        Get.off(
          () => const CheckOutSuccessScreen(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 350),
        );
      } else {
        if (attendanceController.isCheckedIn) {
          Get.snackbar(
            'Already Checked In',
            'You have already checked in today.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: navy,
            colorText: AppColors.white,
            margin: const EdgeInsets.all(16),
          );
          return;
        }

        await attendanceController.checkInNow();

        if (attendanceController.checkInTime.value == null) {
          throw Exception('Check in time was not saved.');
        }

        if (!mounted) return;

        Get.off(
          () => const CheckInSuccessScreen(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 350),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Attendance Error',
        'Unable to save attendance. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.red.shade700,
        colorText: AppColors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCheckOut = widget.isCheckOut;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // TOP BAR
              Row(
                children: [
                  _iconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Get.back(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        isCheckOut
                            ? 'Check Out Confirmation'
                            : 'Attendance Confirmation',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: navy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),

              const SizedBox(height: 30),

              // STATUS ICON
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: blue.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: blue.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCheckOut
                        ? Icons.logout_rounded
                        : Icons.login_rounded,
                    color: blue,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                isCheckOut ? 'CHECK OUT READY' : 'CHECK IN READY',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: textDark,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                isCheckOut
                    ? 'Please review your details before\nconfirming your check out.'
                    : 'Please review your details before\nconfirming your attendance.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: textGrey,
                ),
              ),

              const SizedBox(height: 28),

              // EMPLOYEE DETAILS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Employee Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _DetailRow(
                      icon: Icons.person_rounded,
                      title: 'Employee Name',
                      value: 'Employee',
                    ),
                    const SizedBox(height: 16),
                    const _DetailRow(
                      icon: Icons.badge_rounded,
                      title: 'Employee ID',
                      value: 'LYRA001',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ATTENDANCE DETAILS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckOut
                          ? 'Check Out Details'
                          : 'Attendance Details',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Obx(() {
                      final savedTime = isCheckOut
                          ? attendanceController.checkOutTime.value
                          : attendanceController.checkInTime.value;

                      final displayTime = savedTime ?? DateTime.now();

                      return _DetailRow(
                        icon: isCheckOut
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                        title: isCheckOut
                            ? 'Check Out Time'
                            : 'Check In Time',
                        value: attendanceController.formatTime(
                          displayTime,
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    _DetailRow(
                      icon: Icons.location_on_rounded,
                      title: 'Location',
                      value: _locationText,
                    ),

                    const SizedBox(height: 16),

                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      title: 'Date',
                      value: _dateText,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // VERIFICATION STATUS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: green.withOpacity(0.14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 17),
                    _VerificationRow(
                      title: 'Location Verified',
                      verified: _position != null,
                    ),
                    const SizedBox(height: 13),
                    const _VerificationRow(
                      title: 'Face Verified',
                      verified: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // CONFIRM BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _confirmAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: navy.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isCheckOut
                                  ? Icons.logout_rounded
                                  : Icons.login_rounded,
                              size: 19,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              isCheckOut
                                  ? 'Confirm Check Out'
                                  : 'Confirm Check In',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: _isSaving ? null : () => Get.back(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textGrey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: AppColors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Your attendance data is securely verified',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.grey.shade500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'LYRA PULSE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: navy,
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: navy),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withOpacity(0.045),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.hexFFF1F5FB,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 19,
            color: AppColors.hexFF3978E8,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.hexFF718096,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.hexFF19356C,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationRow extends StatelessWidget {
  final String title;
  final bool verified;

  const _VerificationRow({
    required this.title,
    this.verified = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = verified
        ? AppColors.hexFF18A66A
        : AppColors.hexFFB8C3D0;

    return Row(
      children: [
        Icon(
          verified
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: color,
          size: 21,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.hexFF19356C,
            ),
          ),
        ),
        Text(
          verified ? 'Verified' : 'Pending',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

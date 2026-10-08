import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CheckOutSuccessScreen extends StatelessWidget {
  const CheckOutSuccessScreen({super.key});

  static const Color background = Color(0xFFF7FAFE);
  static const Color navy = Color(0xFF19356C);
  static const Color blue = Color(0xFF3978E8);
  static const Color green = Color(0xFF18A66A);
  static const Color textDark = Color(0xFF172B4D);
  static const Color textGrey = Color(0xFF718096);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                const SizedBox(height: 28),

                // ==========================================================
                // TOP BAR
                // ==========================================================

                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: navy,
                        ),
                      ),
                    ),

                    const Expanded(
                      child: Center(
                        child: Text(
                          'Attendance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: navy,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 44),
                  ],
                ),

                const SizedBox(height: 42),

                // ==========================================================
                // SUCCESS ICON
                // ==========================================================

                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: green.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ==========================================================
                // TITLE
                // ==========================================================

                const Text(
                  'CHECK OUT SUCCESSFUL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Your attendance has been successfully\nchecked out for today.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: textGrey,
                  ),
                ),

                const SizedBox(height: 30),

                // ==========================================================
                // EMPLOYEE CARD
                // ==========================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.045),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: blue.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: blue,
                              size: 25,
                            ),
                          ),

                          const SizedBox(width: 14),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Employee',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Employee ID: LYRA001',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: green.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'PRESENT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: green,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),

                      const SizedBox(height: 20),

                      // Check Out Time
                      _InfoRow(
                        icon: Icons.logout_rounded,
                        title: 'Check Out Time',
                        value: '06:15 PM',
                      ),

                      const SizedBox(height: 16),

                      // Working Hours
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        title: 'Working Hours',
                        value: '08h 45m',
                      ),

                      const SizedBox(height: 16),

                      // Location
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        title: 'Location',
                        value: 'Verified',
                        valueColor: green,
                      ),

                      const SizedBox(height: 16),

                      // Face
                      _InfoRow(
                        icon: Icons.face_rounded,
                        title: 'Face Verification',
                        value: 'Verified',
                        valueColor: green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ==========================================================
                // SECURITY MESSAGE
                // ==========================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: green.withOpacity(0.15),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: green,
                        size: 21,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Your location and face were verified securely.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ==========================================================
                // DONE BUTTON
                // ==========================================================

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.until((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ==========================================================
                // FOOTER
                // ==========================================================

                const Text(
                  'LYRA PULSE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Secure Attendance System',
                  style: TextStyle(
                    fontSize: 10,
                    color: textGrey,
                  ),
                ),

                SizedBox(height: size.height < 700 ? 20 : 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// INFO ROW
// ==========================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5FB),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 19,
            color: const Color(0xFF3978E8),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
            ),
          ),
        ),

        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF19356C),
          ),
        ),
      ],
    );
  }
}
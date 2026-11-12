import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/app_text_field.dart';

class PhoneInput extends StatelessWidget {
  const PhoneInput({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hintText: 'Enter your phone number',
      keyboardType: TextInputType.phone,
      maxLength: 10,
      prefix: Padding(
        padding: EdgeInsets.only(left: 18, right: 8),
        child: Text('+91', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

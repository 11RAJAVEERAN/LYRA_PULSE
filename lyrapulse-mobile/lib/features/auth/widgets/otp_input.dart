
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateUI);
    _focusNode.addListener(_updateUI);
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateUI);
    _focusNode.removeListener(_updateUI);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otp = widget.controller.text;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: SizedBox(
        height: 58,
        child: Stack(
          children: [
            Row(
              children: List.generate(6, (index) {
                final hasValue = index < otp.length;
                final isFocused =
                    _focusNode.hasFocus && index == otp.length;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == 5 ? 0 : 4,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFCFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFocused
                              ? AppColors.primary
                              : const Color(0xFFE2E0F5),
                          width: isFocused ? 1.8 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        hasValue ? otp[index] : '',
                        style: GoogleFonts.inter(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 21,
                ),
                cursorColor: Colors.transparent,
                showCursor: false,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  setState(() {});

                  if (value.length == 6) {
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
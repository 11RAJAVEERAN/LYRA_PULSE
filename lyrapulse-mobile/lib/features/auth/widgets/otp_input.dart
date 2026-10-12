import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

/// Six visual OTP boxes driven by the single [controller] owned by
/// AuthController. A transparent TextField on top captures the input, so
/// typing, deleting, pasting and SMS autofill all update that one controller.
class OtpInput extends StatefulWidget {
  const OtpInput({
    required this.controller,
    super.key,
    this.hasError = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  static const int _length = 6;
  static const double _boxHeight = 58;
  static const double _boxGap = 7;

  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, _focusNode]),
      builder: (context, _) {
        final text = widget.controller.text;
        final activeIndex = text.length.clamp(0, _length - 1);

        return SizedBox(
          height: _boxHeight,
          child: Stack(
            children: [
              Row(
                children: [
                  for (var i = 0; i < _length; i++) ...[
                    if (i > 0) const SizedBox(width: _boxGap),
                    Expanded(
                      child: _OtpBox(
                        char: i < text.length ? text[i] : '',
                        isActive: _focusNode.hasFocus && i == activeIndex,
                        hasError: widget.hasError,
                      ),
                    ),
                  ],
                ],
              ),
              Positioned.fill(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  expands: true,
                  maxLines: null,
                  maxLength: _length,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  showCursor: false,
                  cursorColor: Colors.transparent,
                  style: const TextStyle(
                    color: Colors.transparent,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () => widget.controller.selection =
                      TextSelection.collapsed(
                    offset: widget.controller.text.length,
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.char,
    required this.isActive,
    required this.hasError,
  });

  final String char;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.error
        : isActive
            ? AppColors.primaryBlue
            : AppColors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(191),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
          width: isActive || hasError ? 2.2 : 1.5,
        ),
      ),
      child: Text(
        char,
        style: AppTextStyles.title.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: hasError
              ? AppColors.error
              : AppColors.textPrimary,
        ),
      ),
    );
  }
}
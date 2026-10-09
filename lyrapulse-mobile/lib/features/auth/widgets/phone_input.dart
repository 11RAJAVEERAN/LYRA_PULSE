import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';

class PhoneInput extends StatefulWidget {
  const PhoneInput({
    required this.controller,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;

  /// Called when the keyboard "done" action is pressed.
  final ValueChanged<String>? onSubmitted;

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    const radius = AppDimensions.cardRadius;
    return GestureDetector(
      // Tapping anywhere on the field (including the +91 section) focuses it.
      behavior: HitTestBehavior.opaque,
      onTap: _focusNode.requestFocus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: focused ? AppColors.focus : AppColors.border,
            width: focused ? 1.5 : 1,
          ),
          boxShadow: focused
              ? const [
                  BoxShadow(color: AppColors.focusRing, spreadRadius: 3),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          // Grows with the system text scale instead of clipping.
          child: IntrinsicHeight(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Visual-only country code: the backend expects 10-digit
                  // Indian numbers, so there is no country selection.
                  Container(
                    color: AppColors.infoBackground,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    child: Text('+91',
                        semanticsLabel: 'Country code plus 91',
                        style: AppTextStyles.label.copyWith(
                            fontSize: 16, color: AppColors.primary)),
                  ),
                  const VerticalDivider(
                      width: 1, thickness: 1, color: AppColors.border),
                  const Padding(
                    padding: EdgeInsets.only(left: 14),
                    child: Center(
                      child: Icon(Icons.phone_outlined,
                          size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational
                      ],
                      onSubmitted: widget.onSubmitted,
                      maxLength: 10,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle:
                            AppTextStyles.bodySmall.copyWith(fontSize: 14),
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
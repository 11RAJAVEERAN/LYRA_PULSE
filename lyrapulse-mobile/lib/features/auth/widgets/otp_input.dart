import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    this.hasError = false,
    this.onChanged,
    this.length = 6,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final int length;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput>
    with SingleTickerProviderStateMixin {
  final FocusNode _focus = FocusNode();
  late final AnimationController _blink;

  /// Filled box the user tapped; cursor stays behind its digit.
  int? _tappedIndex;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);

    widget.controller.addListener(_refresh);
    _focus.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focus.removeListener(_refresh);
    _focus.dispose();
    _blink.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  /// Which box currently holds the cursor.
  int get _activeIndex {
    final text = widget.controller.text;
    final offset = widget.controller.selection.baseOffset;
    final pos = offset < 0 ? text.length : offset;

    // User tapped a filled box and the cursor is still right after its digit.
    if (_tappedIndex != null &&
        _tappedIndex! < text.length &&
        pos == _tappedIndex! + 1) {
      return _tappedIndex!;
    }

    return pos.clamp(0, widget.length - 1);
  }

  void _onBoxTap(int index) {
    final len = widget.controller.text.length;

    _focus.requestFocus();

    if (index < len) {
      // Filled box: cursor goes to the back of its digit.
      _tappedIndex = index;
      widget.controller.selection = TextSelection.collapsed(offset: index + 1);
    } else {
      // Empty box: cursor goes to the next free position.
      _tappedIndex = null;
      widget.controller.selection = TextSelection.collapsed(offset: len);
    }

    // Force the keyboard open, even if the field was already focused.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  Widget _cursor() {
    return FadeTransition(
      opacity: _blink,
      child: Container(
        width: 2,
        height: 26,
        color: AppColors.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;

    return Stack(
      children: [
        // Hidden field that actually receives the keyboard input / autofill.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              showCursor: false,
              enableInteractiveSelection: false,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              onChanged: widget.onChanged,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        // Visible boxes.
        Row(
          children: List.generate(widget.length, (i) {
            final filled = i < text.length;
            final isActive = _focus.hasFocus && i == _activeIndex;

            final borderColor = widget.hasError
                ? AppColors.error
                : isActive
                    ? AppColors.primaryBlue
                    : Colors.grey.shade300;

            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: i == widget.length - 1 ? 0 : 8),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onBoxTap(i),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: isActive || widget.hasError ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (filled)
                          Text(
                            text[i],
                            style: AppTextStyles.title.copyWith(fontSize: 22),
                          ),
                        if (isActive) ...[
                          if (filled) const SizedBox(width: 2),
                          _cursor(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
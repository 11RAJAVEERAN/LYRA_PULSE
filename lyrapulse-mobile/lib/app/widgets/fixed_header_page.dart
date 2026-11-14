import 'package:flutter/material.dart';

class FixedHeaderPage extends StatelessWidget {
  /// Mela fixed-ah irukkum (logo / title / toggle)
  final Widget? header;

  /// Header keezha fixed-ah irukkum (month header, tabs, filters)
  final Widget? pinned;

  /// Scroll aagura content
  final List<Widget> children;

  /// Keezha fixed-ah irukkum (confirm button, etc.)
  final Widget? bottom;

  final Future<void> Function()? onRefresh;
  final EdgeInsets padding;
  final Color? backgroundColor;

  const FixedHeaderPage({
    super.key,
    this.header,
    this.pinned,
    required this.children,
    this.bottom,
    this.onRefresh,
    this.backgroundColor,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 28),
  });

  @override
  Widget build(BuildContext context) {
    Widget scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );

    if (onRefresh != null) {
      scroll = RefreshIndicator(onRefresh: onRefresh!, child: scroll);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (header != null) header!,
            if (pinned != null) pinned!,
            Expanded(child: scroll),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}
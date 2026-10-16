

import 'dart:async';

import 'package:flutter/material.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';
import '../app_localizations.dart';

// ─── Toast States ─────────────────────────────
enum ToastStates { success, error, warning, info }

// ─── Custom Toast Widget ──────────────────────
class CustomToast {
  static OverlayEntry? _currentToast;
  static Timer? _dismissTimer;

  static void show({
    required BuildContext context,
    required String message,
    ToastStates state = ToastStates.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // The previous toast's timer has to die with the toast. It used to be a bare
    // `Future.delayed` that read the static `_currentToast` when it fired, not the entry it was
    // created for -- so toast A's three seconds removed toast B, and a second message that arrived
    // 2.5s after the first was on screen for half a second.
    hide();

    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: _ToastWidget(
          message: message,
          state: state,
          // Closes over `entry`, so a manual dismiss removes THIS toast and never a later one.
          onDismiss: () => _dismiss(entry),
        ),
      ),
    );

    _currentToast = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, () => _dismiss(entry));
  }

  static void _dismiss(OverlayEntry entry) {
    if (_currentToast != entry) return;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    entry.remove();
    _currentToast = null;
  }

  static void hide() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentToast?.remove();
    _currentToast = null;
  }
}

// ─── Toast Widget ─────────────────────────────
class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastStates state;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.state,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: LynPalette.ink,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent(), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Hidden from the accessibility tree: the sentence beside it already says what
                // happened, and the live region reads the whole row.
                ExcludeSemantics(
                  child: Icon(_iconData(), color: _accent(), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: LynType.callout.copyWith(
                      color: LynPalette.onDark,
                      height: 1.4,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _controller.reverse().then((_) => widget.onDismiss()),
                  icon: const Icon(Icons.close, size: 18),
                  color: LynPalette.onDarkSoft,
                  visualDensity: VisualDensity.compact,
                  // The close affordance was a bare `GestureDetector` round an icon: no name, and a
                  // target smaller than the 44pt minimum. `IconButton` gives it both.
                  tooltip: AppLocalizations.tr(context, 'dismiss'),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  // The bar used to be the tone colour at 95% with white text on top. White on
  // `LynPalette.danger` measures 3.76:1, under the 4.5:1 body text needs, and the warning tone was
  // worse. `LynFeedback` already settled this for the snackbars: one dark field, the tone carried by
  // a coloured icon. The two mechanisms stay separate because this one draws in an `Overlay` and
  // works without a `Scaffold` -- the login screen needs that -- but they now look like one system.
  Color _accent() => switch (widget.state) {
        ToastStates.success => LynPalette.successSoft,
        ToastStates.error => LynPalette.dangerSoft,
        ToastStates.warning => LynPalette.warningSoft,
        ToastStates.info => LynPalette.indigoOnDark,
      };

  IconData _iconData() => switch (widget.state) {
        ToastStates.success => Icons.check_circle_outline_rounded,
        ToastStates.error => Icons.error_outline_rounded,
        ToastStates.warning => Icons.warning_amber_rounded,
        ToastStates.info => Icons.info_outline_rounded,
      };
}
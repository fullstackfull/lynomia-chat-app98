

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

// ─── Toast States ─────────────────────────────
enum ToastStates { success, error, warning, info }

// ─── Custom Toast Widget ──────────────────────
class CustomToast {
  static OverlayEntry? _currentToast;

  static void show({
    required BuildContext context,
    required String message,
    ToastStates state = ToastStates.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // ✅ إخفاء أي Toast سابق
    _currentToast?.remove();

    final overlay = Overlay.of(context);
    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: _ToastWidget(
          message: message,
          state: state,
          onDismiss: () {
            _currentToast?.remove();
            _currentToast = null;
          },
        ),
      ),
    );

    overlay.insert(_currentToast!);

    // ✅ إخفاء تلقائي بعد المدة
    Future.delayed(duration, () {
      _currentToast?.remove();
      _currentToast = null;
    });
  }

  static void hide() {
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
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getBorderColor(),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _getIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _controller.reverse().then((_) => widget.onDismiss());
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (widget.state) {
      case ToastStates.success:
        return HexColor('#22C55E').withOpacity(0.95);
      case ToastStates.error:
        return HexColor('#EF4444').withOpacity(0.95);
      case ToastStates.warning:
        return HexColor('#F59E0B').withOpacity(0.95);
      case ToastStates.info:
        return HexColor('#3B82F6').withOpacity(0.95);
    }
  }

  Color _getBorderColor() {
    switch (widget.state) {
      case ToastStates.success:
        return HexColor('#16A34A');
      case ToastStates.error:
        return HexColor('#DC2626');
      case ToastStates.warning:
        return HexColor('#D97706');
      case ToastStates.info:
        return HexColor('#2563EB');
    }
  }

  Widget _getIcon() {
    IconData iconData;
    switch (widget.state) {
      case ToastStates.success:
        iconData = Icons.check_circle_rounded;
        break;
      case ToastStates.error:
        iconData = Icons.error_rounded;
        break;
      case ToastStates.warning:
        iconData = Icons.warning_rounded;
        break;
      case ToastStates.info:
        iconData = Icons.info_rounded;
        break;
    }

    return Icon(
      iconData,
      color: Colors.white,
      size: 24,
    );
  }
}
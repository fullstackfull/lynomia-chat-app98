import 'package:flutter/material.dart';

import '../../../shared/app_localizations.dart';
import '../../../shared/styles/lyn_palette.dart';
import '../../../shared/styles/lyn_type.dart';

/// Three dots that actually move, in the place an incoming bubble would be.
///
/// WHY THIS EXISTS. The indicator this replaces was three `AnimatedContainer`s whose decoration never
/// changed between builds -- a fixed `withOpacity(0.4 + index * 0.3)` each -- so nothing ever
/// animated. It rendered as three dots of three different greys, sitting still. On a typing indicator
/// that is not a cosmetic miss: the motion IS the message. A still row of dots says nothing about
/// whether anyone is at the other end, which is the single fact the widget exists to report.
///
/// It was also invisible to a screen reader. Three unlabelled circles have nothing to announce, so a
/// VoiceOver user got no signal at all; now the bubble carries a name and announces itself once when
/// it appears.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, required this.isDark});

  final bool isDark;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  /// One cycle of the wave. Long enough to read as a considered pause rather than a flicker.
  static const Duration _cycle = Duration(milliseconds: 1200);

  /// How far into the cycle each dot starts, as a fraction. The stagger is what makes it a wave
  /// instead of a pulse.
  static const List<double> _phases = [0.0, 0.15, 0.30];

  /// The slice of the cycle one dot spends rising and falling; the rest of it rests.
  static const double _span = 0.5;

  /// How far a dot lifts, in logical pixels.
  static const double _lift = 5;

  static const double _dotSize = 8;

  /// The faintest a dot ever gets. Below this the dots stop carrying 3:1 against the bubble.
  static const double _restingAlpha = 0.75;

  late final AnimationController _controller = AnimationController(vsync: this, duration: _cycle);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the system's "reduce motion" switch, and re-check it whenever it changes: a looping
    // animation is exactly what that setting exists to stop. Without motion the dots still read as a
    // typing indicator, because the staggered opacity is baked into their resting state.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A dot's progress through its own rise-and-fall, 0 at rest and 1 at the top.
  double _progress(int index) {
    final start = _phases[index];
    final t = (_controller.value - start) % 1.0;
    if (t > _span) return 0;
    return Curves.easeInOut.transform(t / _span <= 0.5 ? t / _span * 2 : (1 - t / _span) * 2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Semantics(
      label: AppLocalizations.tr(context, 'typing'),
      // Announced once, when the bubble appears. The node is not rebuilt by the animation, so the
      // wave itself never re-announces.
      liveRegion: true,
      container: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          margin: const EdgeInsetsDirectional.only(start: LynSpace.lg, bottom: LynSpace.sm),
          padding: const EdgeInsets.symmetric(horizontal: LynSpace.lg, vertical: LynSpace.md),
          decoration: BoxDecoration(
            color: LynSurface.surface(isDark),
            border: Border.all(color: LynSurface.border(isDark)),
            // The same tail as an incoming bubble, on the same edge, because that is what it stands in
            // for: the message that has not arrived yet.
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(18),
              topEnd: Radius.circular(18),
              bottomEnd: Radius.circular(18),
              bottomStart: Radius.circular(4),
            ),
          ),
          child: ExcludeSemantics(
            child: SizedBox(
              height: _dotSize + _lift,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < _phases.length; i++) _dot(i, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(int index, bool isDark) {
    final p = _progress(index);
    // The old indicator ran 0.4 / 0.7 / 1.0 of `LynPalette.indigo`, which put its faintest dot at
    // 1.77:1 against a light bubble -- under the 3:1 a graphic that carries meaning needs, and these
    // dots carry all of it. The floor is set where the faintest one clears that, and the hue is the
    // palette's own on-dark indigo in dark mode, because plain `indigo` tops out at 3.18:1 there even
    // at full strength.
    final hue = isDark ? LynPalette.indigoOnDark : LynPalette.indigo;
    final rest = _restingAlpha + (index * 0.05);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Transform.translate(
        offset: Offset(0, -_lift * p),
        child: Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(
            // The stagger survives at rest, so the row still reads as a sequence rather than a row of
            // three identical dots when motion is switched off.
            color: hue.withOpacity((rest + (0.25 * p)).clamp(0.0, 1.0)),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

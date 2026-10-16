import 'package:flutter/material.dart';

import 'lyn_palette.dart';

/// The shape of a screen, drawn before its content arrives.
///
/// WHAT IT REPLACES. Every list in this app opened on a centred `CircularProgressIndicator` on an
/// otherwise empty canvas. A spinner reports that something is happening and nothing else: it does not
/// say what is coming, how much of it there is, or where on the screen it will land, so the layout
/// arrives as a jump rather than as a fill. On the conversations list, which is the screen this app is
/// for, that jump is the first thing an agent sees every time they open an inbox.
///
/// A skeleton answers all three. It is the row's own geometry -- the same 48px avatar, the same two
/// lines at the same widths on the same baselines -- so the real rows replace it in place. Two tests
/// in `test/visual/skeleton_test.dart` hold each placeholder to its real row's measured height.
///
/// MOTION IS ONE BAND ACROSS THE WHOLE LIST, not a pulse per block. Each block paints its own slice of
/// a gradient laid out in the GROUP's coordinate space, so the crest crosses the list as a single
/// sweep. Masking the group as a whole would have been simpler and is wrong: `srcATop` paints wherever
/// the subtree put ink, so a card with a surface fill -- which the inbox card has -- comes out as one
/// solid gradient slab with its own contents invisible inside it.
///
/// AND IT HOLDS STILL WHEN THE SYSTEM SAYS SO. `MediaQuery.disableAnimations` is the one setting that
/// exists to stop exactly this kind of indefinite looping motion; with it on, the blocks are simply
/// drawn in their base tone, which still shows the geometry.
class LynSkeleton {
  const LynSkeleton._();

  /// The block itself.
  static Color base(bool isDark) => isDark ? LynPalette.lineDark : LynPalette.line;

  /// The crest of the sweep. One step lighter than [base] on either field.
  static Color highlight(bool isDark) => isDark ? LynPalette.inkSoft : LynPalette.mist;

  /// How wide the crest is, as a fraction of the group's width.
  static const double bandWidth = 0.3;
}

/// Carries the running sweep down to the blocks.
///
/// It holds the animation itself rather than its value, so the scope is rebuilt once and never again:
/// each block listens to the animation directly, and a tick repaints the blocks without rebuilding
/// anything above them.
class _SweepScope extends InheritedWidget {
  const _SweepScope({
    required this.animation,
    required this.groupKey,
    required this.isDark,
    required super.child,
  });

  final Animation<double> animation;

  /// Resolves the group's box, which is the coordinate space the gradient is laid out in.
  final GlobalKey groupKey;

  final bool isDark;

  static _SweepScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SweepScope>();

  @override
  bool updateShouldNotify(_SweepScope old) =>
      animation != old.animation || groupKey != old.groupKey || isDark != old.isDark;
}

/// One placeholder block: a stand-in for a line of text, an avatar, a chip.
///
/// Outside a [LynSkeletonGroup], or with motion switched off, it is a flat block in
/// [LynSkeleton.base] -- correct on its own, with nothing to tidy up.
class LynSkeletonBlock extends StatelessWidget {
  const LynSkeletonBlock({
    super.key,
    required this.isDark,
    required this.width,
    required this.height,
    this.radius = 6,
    this.shape = BoxShape.rectangle,
  });

  /// A round block at [size] across: an avatar, a status dot.
  const LynSkeletonBlock.circle({
    super.key,
    required this.isDark,
    required double size,
  })  : width = size,
        height = size,
        radius = 0,
        shape = BoxShape.circle;

  /// A line of text [height] tall and [width] wide. A placeholder line is set a little shorter than
  /// the line box it stands in, the way a lowercase word is, so the row's rhythm survives.
  const LynSkeletonBlock.line({
    super.key,
    required this.isDark,
    required this.width,
    this.height = 12,
  })  : radius = 4,
        shape = BoxShape.rectangle;

  final bool isDark;
  final double width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final block = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: LynSkeleton.base(isDark),
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
    );

    final sweep = _SweepScope.maybeOf(context);
    if (sweep == null) return block;

    return AnimatedBuilder(
      animation: sweep.animation,
      // `srcATop` keeps the block's own silhouette -- its circle, its rounded corners -- and replaces
      // only the colour inside it.
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => _shader(context, bounds, sweep),
        child: child,
      ),
      child: block,
    );
  }

  /// The gradient, laid out across the whole group and sampled over this block's slice of it.
  Shader _shader(BuildContext context, Rect bounds, _SweepScope sweep) {
    final group = sweep.groupKey.currentContext?.findRenderObject();
    final self = context.findRenderObject();

    // Before the group has laid out there is nothing to position against; a flat block is the right
    // answer for that frame rather than a gradient in the wrong place.
    if (group is! RenderBox || self is! RenderBox || !group.hasSize || !self.hasSize) {
      return LinearGradient(
        colors: <Color>[LynSkeleton.base(isDark), LynSkeleton.base(isDark)],
      ).createShader(bounds);
    }

    // The group's rect, expressed in THIS block's coordinates: the gradient then spans the group and
    // the block shows the part of it that falls where the block sits.
    final origin = group.globalToLocal(self.localToGlobal(Offset.zero));
    final rect = Rect.fromLTWH(-origin.dx, -origin.dy, group.size.width, group.size.height);

    // Travels from before the leading edge to past the trailing one, so the crest enters and leaves
    // rather than appearing mid-surface.
    const band = LynSkeleton.bandWidth;
    final crest = -band + sweep.animation.value * (1 + 2 * band);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return LinearGradient(
      begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
      end: rtl ? Alignment.centerLeft : Alignment.centerRight,
      colors: <Color>[
        LynSkeleton.base(isDark),
        LynSkeleton.highlight(isDark),
        LynSkeleton.base(isDark),
      ],
      // Clamped rather than offset, so the band compresses against the edge instead of disappearing:
      // `stops` must not decrease, and equal stops are legal.
      stops: <double>[
        (crest - band).clamp(0.0, 1.0),
        crest.clamp(0.0, 1.0),
        (crest + band).clamp(0.0, 1.0),
      ],
    ).createShader(rect);
  }
}

/// Runs one band of light across every block inside it, and names the whole group for a screen reader.
///
/// The children are excluded from the accessibility tree: a dozen unlabelled rectangles have nothing
/// to say, and the group says the one thing that matters once. [label] is announced as a live region
/// because the thing it reports -- that the screen is still loading -- appears after the screen does.
class LynSkeletonGroup extends StatefulWidget {
  const LynSkeletonGroup({
    super.key,
    required this.isDark,
    required this.label,
    required this.child,
  });

  final bool isDark;

  /// Already translated. The group is generic; only its caller knows what is loading.
  final String label;

  final Widget child;

  @override
  State<LynSkeletonGroup> createState() => _LynSkeletonGroupState();
}

class _LynSkeletonGroupState extends State<LynSkeletonGroup>
    with SingleTickerProviderStateMixin {
  /// One pass of the band. Slow enough to read as a sweep rather than a flash, and slow enough that
  /// a list which loads quickly shows at most one pass.
  static const Duration _sweep = Duration(milliseconds: 1400);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _sweep);

  final GlobalKey _groupKey = GlobalKey();

  bool _motionOff = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-read on every dependency change, so flipping the system switch while a list is loading takes
    // effect rather than waiting for the next screen.
    final off = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (off != _motionOff) setState(() => _motionOff = off);
    if (off) {
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

  @override
  Widget build(BuildContext context) {
    final body = ExcludeSemantics(child: KeyedSubtree(key: _groupKey, child: widget.child));

    return Semantics(
      label: widget.label,
      liveRegion: true,
      container: true,
      child: _motionOff
          ? body
          : _SweepScope(
              animation: _controller,
              groupKey: _groupKey,
              isDark: widget.isDark,
              child: body,
            ),
    );
  }
}

/// A placeholder for one line of text, occupying that line's real box.
///
/// WHY IT IS NOT A FIXED HEIGHT, which is what it was first written as. The real rows are built from
/// `Text`, whose line box grows with `MediaQuery.textScaler`; nothing in this app clamps that, so the
/// OS font-size setting reaches both screens. A placeholder measured in fixed logical pixels therefore
/// matches the real row at the default size and nowhere else -- measured, the conversation row goes
/// 73 / 82 / 113 at scale 1.0 / 1.3 / 2.0 while a fixed placeholder stays at 73, so the fifth row
/// landed 36px then 160px away from the grey bar that stood for it. That is the layout jump this whole
/// component exists to remove, returning for exactly the people who enlarged their type.
///
/// So the height is not computed here at all. An invisible zero-width space, set in the REAL rank,
/// is laid out by the engine and the bar is drawn over it: the placeholder then occupies whatever box
/// the arriving sentence will occupy, at every scale, with no arithmetic of ours to drift from what
/// the engine actually does. (`fontSize * height` is not that number -- the engine reports 22.0 for
/// the 16/1.4 rank, not 22.4.)
class LynSkeletonTextLine extends StatelessWidget {
  const LynSkeletonTextLine({
    super.key,
    required this.isDark,
    required this.style,
    required this.width,
  });

  final bool isDark;

  /// The rank the real text at this position is set in.
  final TextStyle style;

  /// How wide the bar is. The line box's height is taken from [style]; only the width is chosen.
  final double width;

  /// The bar's height as a fraction of its rank's font size, so a larger type setting gets a
  /// proportionally heavier bar rather than a thin rule floating in a tall box. Picked to land on the
  /// heights these placeholders were drawn at before they scaled: 14 on the 16px rank, 12 on 14px,
  /// 10 on 12px.
  static const double _weight = 0.86;

  @override
  Widget build(BuildContext context) {
    final bar = MediaQuery.textScalerOf(context).scale(style.fontSize! * _weight);

    return SizedBox(
      width: width,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: <Widget>[
          // Lays out, paints nothing. `\u200B` is a zero-width space: it carries the line box and no
          // glyph, so the box is the rank's, independent of which font happens to be resolved.
          Opacity(
            opacity: 0,
            child: Text('\u200B', style: style, maxLines: 1),
          ),
          LynSkeletonBlock(isDark: isDark, width: width, height: bar, radius: 4),
        ],
      ),
    );
  }
}

/// The gap the real rows put between their two lines. A placeholder has to use the same one, or its
/// column stops matching the moment the text scales.
const double kSkeletonLineGap = 2;

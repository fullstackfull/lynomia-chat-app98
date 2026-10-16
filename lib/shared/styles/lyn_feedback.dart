import 'package:flutter/material.dart';

import 'lyn_palette.dart';
import 'lyn_type.dart';
import '../app_localizations.dart';

/// What a piece of transient feedback is telling you.
enum LynTone { error, warning, success, neutral }

/// Transient feedback, in one shape.
///
/// WHY THIS EXISTS. The chat screen grew thirteen hand-rolled `SnackBar`s, and they were wrong in two
/// ways that only showed up together.
///
/// Five of them were hardcoded Arabic sentences -- `'❌ فشل بدء التسجيل: $e'` and its siblings -- shown
/// to every user whatever their locale. An English-speaking agent whose recording failed got a line
/// they could not read.
///
/// The rest leaned on an emoji glued to the front of the string to say which KIND of message it was,
/// with `backgroundColor: Colors.red` as the only other signal. The emoji was doing real work there,
/// because colour alone does not reach the one man in twelve who cannot separate red from green. But
/// an emoji inside a string is not something the accessibility tree can describe, and the red bar it
/// was propping up does not even pass for sighted readers: white text on `LynPalette.danger` measures
/// 3.76:1, under the 4.5:1 that body text needs.
///
/// So the tone is carried by a real `Icon`, which a screen reader can be given a name for, over the
/// one dark bar that Material already intends for this component -- 16:1 for the text and 9.35:1 for
/// the icon, in both themes, because a snackbar floats over whichever surface is behind it and should
/// not have to guess which one that is.
class LynFeedback {
  const LynFeedback._();

  /// Show [messageKey], translated. A key that is not in the catalogue comes back unchanged, so a
  /// message relayed from the server can be passed straight through.
  ///
  /// [detail] is appended after the message when the cause is worth showing -- a file name, a code.
  /// Never pass a raw exception: `$e` on a `DioException` prints the request, headers included.
  static void show(
    BuildContext context,
    String messageKey, {
    LynTone tone = LynTone.neutral,
    String? detail,
    String? actionKey,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final message = AppLocalizations.tr(context, messageKey);
    final icon = _icon(tone);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: LynPalette.ink,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? (tone == LynTone.error ? const Duration(seconds: 5) : const Duration(seconds: 3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LynSpace.md)),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              // Hidden from the accessibility tree: it repeats the tone, and the sentence beside it
              // already says what happened. A screen reader reading "error, could not start
              // recording" twice is worse than reading it once.
              ExcludeSemantics(child: Icon(icon, size: 20, color: _accent(tone))),
              const SizedBox(width: LynSpace.md),
            ],
            Expanded(
              child: Text(
                detail == null || detail.isEmpty ? message : '$message — $detail',
                style: LynType.callout.copyWith(color: LynPalette.onDark),
              ),
            ),
          ],
        ),
        action: actionKey == null || onAction == null
            ? null
            : SnackBarAction(
                label: AppLocalizations.tr(context, actionKey),
                textColor: LynPalette.indigoOnDark,
                onPressed: onAction,
              ),
      ),
    );
  }

  static IconData? _icon(LynTone tone) => switch (tone) {
        LynTone.error => Icons.error_outline_rounded,
        LynTone.warning => Icons.warning_amber_rounded,
        LynTone.success => Icons.check_circle_outline_rounded,
        LynTone.neutral => null,
      };

  static Color _accent(LynTone tone) => switch (tone) {
        LynTone.error => LynPalette.dangerSoft,
        LynTone.warning => LynPalette.warningSoft,
        LynTone.success => LynPalette.successSoft,
        LynTone.neutral => LynPalette.onDarkSoft,
      };
}

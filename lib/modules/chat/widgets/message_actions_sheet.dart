import 'package:flutter/material.dart';

import '../../../shared/app_localizations.dart';
import '../../../shared/styles/lyn_palette.dart';
import '../../../shared/styles/lyn_type.dart';

/// What you can do with one message, after a long press.
///
/// Pulled out of `chat_screen.dart`, where it put Delete FIRST -- top of the list, right under the
/// grab bar, where a thumb coming off a long press already is. A destructive action belongs at the
/// end, behind a rule, which is where both platforms put theirs. Its only mark of being destructive
/// was a red icon next to a label in the ordinary text colour, and red alone does not reach the one
/// man in twelve who cannot separate it from the rest; now the word carries the warning too, in the
/// palette's danger tone rather than a raw `Colors.red`.
class MessageActionsSheet extends StatelessWidget {
  const MessageActionsSheet({
    super.key,
    required this.isDark,
    required this.canCopy,
    required this.onCopy,
    required this.onSelect,
    required this.onDelete,
  });

  final bool isDark;

  /// False for a message with no text of its own -- an attachment with no caption.
  final bool canCopy;
  final VoidCallback onCopy;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: LynSpace.sm),
          ExcludeSemantics(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: LynSurface.borderStrong(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // A sheet that appears out of a long press should say what it is about. Without this it
          // opened on a bare list of verbs with nothing naming what they would act on.
          Padding(
            padding: const EdgeInsets.fromLTRB(LynSpace.xl, LynSpace.md, LynSpace.xl, LynSpace.sm),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                AppLocalizations.tr(context, 'Message'),
                style: LynType.caption.copyWith(
                  color: LynSurface.textTertiary(isDark),
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          if (canCopy)
            _Action(
              icon: Icons.copy_rounded,
              label: AppLocalizations.tr(context, 'Copy Text'),
              isDark: isDark,
              onTap: onCopy,
            ),
          _Action(
            icon: Icons.check_circle_outline,
            label: AppLocalizations.tr(context, 'Select Messages'),
            isDark: isDark,
            onTap: onSelect,
          ),
          Divider(height: LynSpace.lg, thickness: 1, color: LynSurface.border(isDark)),
          _Action(
            icon: Icons.delete_outline,
            label: AppLocalizations.tr(context, 'Delete Message'),
            isDark: isDark,
            isDestructive: true,
            onTap: onDelete,
          ),
          const SizedBox(height: LynSpace.lg),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    // The measured tone for each surface, not the raw status colour: `LynPalette.danger` on a light
    // sheet is 3.76:1, under what a label needs.
    final ink = isDestructive ? LynSurface.dangerText(isDark) : LynSurface.textPrimary(isDark);

    return ListTile(
      onTap: onTap,
      leading: ExcludeSemantics(
        child: Icon(icon, color: isDestructive ? LynPalette.danger : LynPalette.indigo),
      ),
      title: Text(
        label,
        style: LynType.body.copyWith(
          color: ink,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

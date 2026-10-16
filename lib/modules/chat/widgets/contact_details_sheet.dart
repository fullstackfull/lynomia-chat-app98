import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../shared/app_localizations.dart';
import '../../../shared/styles/lyn_channel.dart';
import '../../../shared/styles/lyn_palette.dart';
import '../../../shared/styles/lyn_type.dart';

/// Everything the sheet shows about one person. Plain data, so the sheet can be pumped on its own.
class ContactDetails {
  const ContactDetails({
    required this.name,
    this.email = '',
    this.phone = '',
    this.avatarUrl,
    this.channelType,
    this.lastActivity,
  });

  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? channelType;
  final DateTime? lastActivity;
}

/// Who you are talking to, and the one thing you can change about them.
///
/// Pulled out of `chat_screen.dart`, where it was a 90-line closure built from raw numbers. Four
/// things were wrong with it beyond the spacing:
///
///   * it printed `channelType.replaceAll('Channel::', '')` under the name -- the raw machine value,
///     "TwilioSms", while the app bar one layer up showed the same channel's real label;
///   * its large avatar tested `avatarUrl == null`, so the empty string this API returns for a
///     contact with no picture sent it off to load `''` and left a broken image where the initial
///     should be. The small avatar beside it had always tested for empty as well;
///   * its one action was styled as a muted secondary button, which is not what the only action on a
///     surface should look like;
///   * it ended in a fixed 32px, so on a phone with a gesture bar that action sat under the bar.
class ContactDetailsSheet extends StatelessWidget {
  const ContactDetailsSheet({
    super.key,
    required this.contact,
    required this.isDark,
    required this.isLoading,
    required this.onEditName,
  });

  final ContactDetails contact;
  final bool isDark;

  /// True while the details are being fetched or a rename is in flight.
  final bool isLoading;
  final VoidCallback onEditName;

  static const double _avatarSize = 100;

  @override
  Widget build(BuildContext context) {
    final unknown = AppLocalizations.tr(context, 'Not available');

    return Container(
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // A sheet is not a screen: it has to survive a small phone with the system text size turned up,
      // and it has to clear the gesture bar. Both of those used to be fixed numbers.
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Handle(isDark: isDark),
              const SizedBox(height: LynSpace.xl),
              _Avatar(url: contact.avatarUrl, name: contact.name, isDark: isDark),
              const SizedBox(height: LynSpace.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: LynSpace.xl),
                child: Text(
                  contact.name,
                  style: LynType.title.copyWith(color: LynSurface.textPrimary(isDark)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: LynSpace.xs),
              Text(
                // The channel's real name, the same one the app bar shows, rather than the class
                // suffix off the back of `Channel::TwilioSms`.
                LynChannel.label(context, contact.channelType),
                style: LynType.callout.copyWith(color: LynSurface.textSecondary(isDark)),
              ),
              const SizedBox(height: LynSpace.xl),
              _InfoTile(
                icon: Icons.email_outlined,
                label: AppLocalizations.tr(context, 'Email'),
                value: contact.email.isNotEmpty ? contact.email : unknown,
                isDark: isDark,
              ),
              _InfoTile(
                icon: Icons.phone_outlined,
                label: AppLocalizations.tr(context, 'Phone'),
                value: contact.phone.isNotEmpty ? contact.phone : unknown,
                isDark: isDark,
              ),
              _InfoTile(
                icon: Icons.access_time,
                label: AppLocalizations.tr(context, 'Last Activity'),
                // `yyyy-MM-dd HH:mm` is one pattern for every reader. `yMMMd` and `jm` are the
                // locale's own, so an Arabic reader gets Arabic months and a 12-hour clock where
                // that is what they use.
                value: contact.lastActivity == null
                    ? unknown
                    : '${intl.DateFormat.yMMMd(_locale(context)).format(contact.lastActivity!)}'
                        ' · ${intl.DateFormat.jm(_locale(context)).format(contact.lastActivity!)}',
                isDark: isDark,
              ),
              const SizedBox(height: LynSpace.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: LynSpace.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onEditName,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.edit, size: 18),
                    label: Text(
                      AppLocalizations.tr(context, 'Edit Name'),
                      style: LynType.callout.copyWith(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      // The only action on the sheet, so it looks like one.
                      backgroundColor: LynPalette.indigo,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: LynPalette.indigo.withOpacity(0.5),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: LynSpace.md + 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LynSpace.md)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LynSpace.xxl),
            ],
          ),
        ),
      ),
    );
  }

  static String _locale(BuildContext context) => Localizations.localeOf(context).toString();
}

/// The grab bar. It is decoration to a screen reader, so it is hidden from one.
class _Handle extends StatelessWidget {
  const _Handle({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.only(top: LynSpace.md),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: LynSurface.borderStrong(isDark),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name, required this.isDark});

  final String? url;
  final String name;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Empty, not just null: this API answers a contact with no picture with `""`, and handing that to
    // an image provider paints a broken image where the initial belongs.
    final hasAvatar = url != null && url!.isNotEmpty;

    return Hero(
      tag: 'contact_avatar_large_${name.hashCode}',
      child: Container(
        width: ContactDetailsSheet._avatarSize,
        height: ContactDetailsSheet._avatarSize,
        decoration: BoxDecoration(
          color: hasAvatar ? null : LynPalette.indigo.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: LynSurface.border(isDark), width: 3),
          image: hasAvatar
              ? DecorationImage(image: CachedNetworkImageProvider(url!), fit: BoxFit.cover)
              : null,
        ),
        child: hasAvatar
            ? null
            : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: LynType.display.copyWith(color: LynPalette.indigo),
                ),
              ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: LynSpace.xl, vertical: LynSpace.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: LynSurface.surfaceMuted(isDark),
                borderRadius: BorderRadius.circular(10),
              ),
              // The icon repeats the label beside it, so it is decoration to a screen reader.
              child: ExcludeSemantics(child: Icon(icon, color: LynPalette.indigo, size: 20)),
            ),
            const SizedBox(width: LynSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark))),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: LynType.body.copyWith(
                      color: LynSurface.textPrimary(isDark),
                      fontWeight: FontWeight.w500,
                    ),
                    // An email or a long number wraps rather than losing its tail: there is nowhere
                    // else in this product to read it, so truncating it hides the only copy.
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Renaming a contact.
///
/// It was an `AlertDialog` built inline with `textAlign: TextAlign.right` hard-coded on the field, so
/// an English name typed into it was pushed to the far edge; and its Save button accepted the tap and
/// did nothing when the name was blank or unchanged, which reads as a broken button rather than as a
/// rule. It also built a `TextEditingController` it never disposed, once per open.
class EditContactNameDialog extends StatefulWidget {
  const EditContactNameDialog({
    super.key,
    required this.currentName,
    required this.isDark,
    required this.onSave,
  });

  final String currentName;
  final bool isDark;
  final ValueChanged<String> onSave;

  @override
  State<EditContactNameDialog> createState() => _EditContactNameDialogState();
}

class _EditContactNameDialogState extends State<EditContactNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave {
    final next = _controller.text.trim();
    return next.isNotEmpty && next != widget.currentName;
  }

  void _save() {
    if (!_canSave) return;
    widget.onSave(_controller.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return AlertDialog(
      backgroundColor: LynSurface.surface(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        AppLocalizations.tr(context, 'Edit Contact Name'),
        style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        // START, not right. A hard right alignment put every English name against the far edge of the
        // field; `start` resolves to whichever edge the script actually begins at.
        textAlign: TextAlign.start,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _save(),
        onChanged: (_) => setState(() {}),
        style: LynType.body.copyWith(color: LynSurface.textPrimary(isDark)),
        decoration: InputDecoration(
          hintText: AppLocalizations.tr(context, 'Enter new name'),
          hintStyle: LynType.body.copyWith(color: LynSurface.textTertiary(isDark)),
          filled: true,
          fillColor: LynSurface.canvas(isDark),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(LynSpace.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(LynSpace.md),
            borderSide: const BorderSide(color: LynPalette.indigo, width: 2),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.tr(context, 'Cancel'),
            style: LynType.callout.copyWith(color: LynSurface.textSecondary(isDark)),
          ),
        ),
        ElevatedButton(
          // Disabled rather than silently inert: a button that takes the tap and does nothing reads
          // as broken, where a dimmed one reads as a rule you have not met yet.
          onPressed: _canSave ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: LynPalette.indigo,
            foregroundColor: Colors.white,
            disabledBackgroundColor: LynSurface.surfaceMuted(isDark),
            disabledForegroundColor: LynSurface.textTertiary(isDark),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LynSpace.md)),
          ),
          child: Text(
            AppLocalizations.tr(context, 'Save'),
            style: LynType.callout.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

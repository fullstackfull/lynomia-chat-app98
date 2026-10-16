import 'package:flutter/material.dart';

import '../app_localizations.dart';
import 'lyn_palette.dart';

/// How a channel is named, drawn and coloured, in one place.
///
/// WHY IT EXISTS. The API sends `channel_type` as a Rails class name — `Channel::Whatsapp`,
/// `Channel::FacebookPage`, `Channel::TwilioSms`. Two screens were switching on `'whatsapp'` and
/// `'email'` against the RAW value, so no case ever matched: every inbox in the picker fell through to
/// the grey default icon and showed the literal string "Channel::Whatsapp" as its name. [key] strips
/// the prefix first, which is the whole of that bug.
///
/// The hexes are the channels' own brand colours, used to identify the channel and nothing else — the
/// same job a favicon does in a browser tab.
class LynChannel {
  const LynChannel._();

  /// `Channel::FacebookPage` -> `facebookpage`; also accepts a value that was already stripped.
  static String key(String? channelType) =>
      (channelType ?? '').replaceAll('Channel::', '').toLowerCase().trim();

  static IconData icon(String? channelType) {
    switch (key(channelType)) {
      case 'whatsapp':
        return Icons.chat_bubble_rounded;
      case 'facebookpage':
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'twitter':
      case 'twitterprofile':
        return Icons.alternate_email;
      case 'email':
        return Icons.mail_outline_rounded;
      case 'telegram':
        return Icons.send_rounded;
      case 'line':
        return Icons.forum_outlined;
      case 'twiliosms':
      case 'sms':
        return Icons.sms_outlined;
      case 'api':
        return Icons.code_rounded;
      case 'web':
      case 'website':
      case 'webwidget':
        return Icons.language_rounded;
      default:
        return Icons.inbox_rounded;
    }
  }

  static Color color(String? channelType) {
    switch (key(channelType)) {
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'facebookpage':
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFD6246E);
      case 'twitter':
      case 'twitterprofile':
        return const Color(0xFF1DA1F2);
      case 'email':
        return LynPalette.warning;
      case 'telegram':
        return const Color(0xFF0088CC);
      case 'line':
        return const Color(0xFF00B900);
      case 'twiliosms':
      case 'sms':
        return const Color(0xFF8B5CF6);
      case 'api':
        return LynPalette.indigo;
      case 'web':
      case 'website':
      case 'webwidget':
        return LynPalette.blue;
      default:
        return LynPalette.muted;
    }
  }

  /// The channel's own name, translated where the product has a translation for it.
  ///
  /// An unrecognised type is spaced out of CamelCase rather than printed raw, so a channel this map
  /// has not caught up with still reads as words instead of as a class name.
  static String label(BuildContext context, String? channelType) {
    switch (key(channelType)) {
      case 'whatsapp':
        return AppLocalizations.tr(context, 'WhatsApp');
      case 'facebookpage':
      case 'facebook':
        return AppLocalizations.tr(context, 'Facebook');
      case 'instagram':
        return AppLocalizations.tr(context, 'Instagram');
      case 'twitter':
      case 'twitterprofile':
        return AppLocalizations.tr(context, 'Twitter');
      case 'email':
        return AppLocalizations.tr(context, 'Email');
      case 'telegram':
        return AppLocalizations.tr(context, 'Telegram');
      case 'line':
        return AppLocalizations.tr(context, 'LINE');
      case 'twiliosms':
      case 'sms':
        return AppLocalizations.tr(context, 'SMS');
      case 'api':
        return AppLocalizations.tr(context, 'API');
      case 'web':
      case 'website':
      case 'webwidget':
        return AppLocalizations.tr(context, 'Live chat');
      default:
        final raw = (channelType ?? '').replaceAll('Channel::', '');
        if (raw.isEmpty) return AppLocalizations.tr(context, 'Unknown');
        return raw.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ');
    }
  }
}

import 'package:flutter/material.dart';

import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';

/// A policy document, as the server sends it: plain text, blank lines between sections, and a
/// section's heading written as the words before the first colon.
///
/// THE SPLIT WAS WRONG. It was `text.split('\r\n\r\n')` — CRLF, and only CRLF. A server sending Unix
/// line endings, which is the ordinary case, matched nothing, so the entire privacy policy rendered
/// as ONE unbroken paragraph with no headings at all. A blank line is a blank line here whichever way
/// it is encoded.
///
/// THE HEADING TEST WAS TOO EAGER. Any colon in the first fifty characters made a heading, so a
/// paragraph opening with a URL became the heading "https" over a body of "//lynomia.com/…". A
/// heading is now a single line, and a colon followed by a slash is part of a URL rather than the end
/// of a title.
///
/// This renderer lived in two files with the same bug twice: `PrivacyScreen`, which nothing reached,
/// and `PrivacyHubScreen`, which the drawer opens.
class PolicyDocument extends StatelessWidget {
  const PolicyDocument({super.key, required this.text, required this.isDark});

  final String text;
  final bool isDark;

  /// A blank line, in CRLF, LF or CR, with any trailing spaces on it.
  static final RegExp _blankLine = RegExp(r'(\r\n|\r|\n)[ \t]*(\r\n|\r|\n)');

  /// The longest a heading may be. A legal section is titled in a few words; a sentence that happens
  /// to contain a colon is not a title.
  static const int _headingLimit = 60;

  @override
  Widget build(BuildContext context) {
    final sections = text
        .split(_blankLine)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ..._section(sections[i], isLast: i == sections.length - 1),
      ],
    );
  }

  List<Widget> _section(String section, {required bool isLast}) {
    final heading = _headingOf(section);
    final gap = SizedBox(height: isLast ? 0 : LynSpace.xl);

    if (heading == null) {
      return [_body(section), gap];
    }
    return [
      Text(
        heading.title,
        style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark)),
      ),
      const SizedBox(height: LynSpace.sm),
      if (heading.body.isNotEmpty) _body(heading.body),
      gap,
    ];
  }

  Widget _body(String text) => Text(
        text,
        textAlign: TextAlign.start,
        style: LynType.body.copyWith(
          color: LynSurface.textSecondary(isDark),
          // Longer than the scale's own leading: this is a wall of legal prose read top to bottom,
          // and half of it is Arabic, whose marks need the room.
          height: 1.75,
        ),
      );

  ({String title, String body})? _headingOf(String section) {
    final colon = section.indexOf(':');
    if (colon <= 0 || colon > _headingLimit) return null;

    final title = section.substring(0, colon).trim();
    // A colon inside a URL is not the end of a title.
    if (section.length > colon + 1 && section[colon + 1] == '/') return null;
    // A title is one line. A paragraph whose second sentence contains a colon is not titled by its
    // first.
    if (title.contains('\n') || title.contains('\r')) return null;

    return (title: title, body: section.substring(colon + 1).trim());
  }
}

/// The card a policy document sits in.
class PolicyCard extends StatelessWidget {
  const PolicyCard({
    super.key,
    required this.title,
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final String title;
  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // One accent for all three documents, the product's own. They were coloured success-green,
    // indigo and warning-amber — so the "About us" tab was permanently painted in the colour this
    // product uses to say something needs attention.
    final ink = isDark ? LynPalette.indigoOnDark : LynPalette.indigoDeep;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LynSpace.xl),
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        borderRadius: BorderRadius.circular(LynSpace.lg),
        border: Border.all(color: LynSurface.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: LynPalette.indigo.withOpacity(isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(LynSpace.md),
                ),
                child: Icon(icon, size: 20, color: ink),
              ),
              const SizedBox(width: LynSpace.md),
              Expanded(
                child: Text(
                  title,
                  style: LynType.title.copyWith(color: LynSurface.textPrimary(isDark)),
                ),
              ),
            ],
          ),
          const SizedBox(height: LynSpace.lg),
          Divider(height: 1, thickness: 1, color: LynSurface.border(isDark)),
          const SizedBox(height: LynSpace.lg),
          PolicyDocument(text: text, isDark: isDark),
        ],
      ),
    );
  }
}

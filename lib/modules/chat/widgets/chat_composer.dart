import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../shared/app_localizations.dart';
import '../../../shared/styles/lyn_palette.dart';
import '../../../shared/styles/lyn_type.dart';

/// The bar at the bottom of a conversation: attach, type, record, send.
///
/// WHY IT IS ITS OWN FILE. It lived inside `_ChatScreenState` as three private methods on a 2,545-line
/// `State` that needs a Cubit, a socket and a live conversation, so the one surface an agent touches on
/// every single message could not be rendered by a test at all. Here it takes plain values and callbacks,
/// so a golden pumps THE REAL WIDGET rather than a reimplementation of it.
///
/// It also stops the whole screen rebuilding on every keystroke. The screen held
/// `_messageController.addListener(() => setState(() {}))` purely to swap one button between a microphone
/// and a send arrow; that rebuilt the message list, the app bar and every bubble on each character typed.
/// The swap is a `ValueListenableBuilder` around that button and nothing else.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.isDark,
    required this.isWhatsAppChannel,
    required this.isRestrictedToTemplates,
    required this.isRecording,
    required this.recordingSeconds,
    required this.recordAnimation,
    required this.onSend,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onPickFile,
    required this.onOpenTemplates,
  });

  final TextEditingController controller;
  final bool isDark;

  /// Whether this conversation can carry WhatsApp templates at all.
  final bool isWhatsAppChannel;

  /// Meta's 24-hour window has closed, so free-form replies are refused and a template is the only way
  /// to reach this customer.
  final bool isRestrictedToTemplates;

  final bool isRecording;
  final int recordingSeconds;
  final Animation<double> recordAnimation;

  final VoidCallback onSend;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onPickFile;
  final VoidCallback onOpenTemplates;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  /// How long the "hold it" hint stays up after someone taps the microphone.
  static const Duration _hintDuration = Duration(seconds: 2);

  bool _showHoldHint = false;

  void _onMicTapped() {
    // Tapping the microphone used to do NOTHING -- the button carried `onLongPressStart` and
    // `onLongPressEnd` and no `onTap`, so the obvious gesture was swallowed in silence and the only
    // instruction that it is hold-to-record was nowhere on the screen.
    setState(() => _showHoldHint = true);
    Future.delayed(_hintDuration, () {
      if (mounted) setState(() => _showHoldHint = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        border: Border(top: BorderSide(color: LynSurface.border(isDark))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showHoldHint && !widget.isRecording) _HoldHint(isDark: isDark),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LynSpace.sm,
                vertical: LynSpace.sm,
              ),
              child: widget.isRecording
                  ? _buildRecording(isDark)
                  : widget.isRestrictedToTemplates
                      ? _buildTemplateOnly(isDark)
                      : _buildNormal(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // The ordinary state: attach, type, record or send.
  // ───────────────────────────────────────────────────────────────
  Widget _buildNormal(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.isWhatsAppChannel)
          ComposerAction(
            icon: Icons.description_outlined,
            label: AppLocalizations.tr(context, 'Whatsapp Templates'),
            onTap: widget.onOpenTemplates,
            foreground: LynPalette.indigo,
          ),
        _AttachmentMenu(
          isDark: isDark,
          onCamera: widget.onPickCamera,
          onGallery: widget.onPickGallery,
          onFile: widget.onPickFile,
        ),
        Expanded(child: _buildField(isDark)),
        const SizedBox(width: LynSpace.sm),
        // Only this button listens to the field. Everything else on the screen stays still while
        // somebody types.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            if (hasText) {
              return ComposerAction(
                icon: Icons.send_rounded,
                label: AppLocalizations.tr(context, 'Send message'),
                onTap: widget.onSend,
                filled: true,
              );
            }
            return ComposerAction(
              icon: Icons.mic_rounded,
              label: AppLocalizations.tr(context, 'Hold to record'),
              onTap: _onMicTapped,
              onLongPressStart: widget.onStartRecording,
              onLongPressEnd: widget.onStopRecording,
              filled: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildField(bool isDark) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LynSurface.surfaceMuted(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LynSurface.border(isDark)),
      ),
      child: TextField(
        controller: widget.controller,
        // No forced `TextAlign.right`: the field follows the keyboard's own script, so an agent typing
        // English gets English alignment and one typing Arabic gets Arabic.
        textAlign: TextAlign.start,
        style: LynType.body.copyWith(color: LynSurface.textPrimary(isDark)),
        minLines: 1,
        maxLines: 5,
        textInputAction: TextInputAction.send,
        keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
        decoration: InputDecoration(
          hintText: AppLocalizations.tr(context, 'Type your message...'),
          hintStyle: LynType.body.copyWith(color: LynSurface.textTertiary(isDark)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LynSpace.lg,
            vertical: LynSpace.md,
          ),
        ),
        onSubmitted: (_) => widget.onSend(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // The 24-hour window has closed.
  // ───────────────────────────────────────────────────────────────
  Widget _buildTemplateOnly(bool isDark) {
    // The banner above the message list already explains the window at length. Repeating the whole
    // sentence here, in a box shaped like the text field, left two paragraphs of the same news on one
    // screen and buried the one thing the agent can actually do.
    return Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.tr(context, 'Replies are closed. Send a template to reopen this conversation.'),
            style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark)),
          ),
        ),
        const SizedBox(width: LynSpace.md),
        _PillButton(
          icon: Icons.description_outlined,
          label: AppLocalizations.tr(context, 'Send Template'),
          onTap: widget.onOpenTemplates,
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Recording.
  // ───────────────────────────────────────────────────────────────
  Widget _buildRecording(bool isDark) {
    return Row(
      children: [
        ComposerAction(
          icon: Icons.delete_outline_rounded,
          label: AppLocalizations.tr(context, 'Discard recording'),
          onTap: widget.onCancelRecording,
          foreground: LynPalette.danger,
        ),
        Expanded(
          child: _Waveform(animation: widget.recordAnimation),
        ),
        const SizedBox(width: LynSpace.sm),
        Text(
          _formatDuration(widget.recordingSeconds),
          style: LynType.subtitle.copyWith(
            color: LynSurface.textPrimary(isDark),
            // Proportional digits make a running timer shuffle its own width every second, which drags
            // the waveform beside it back and forth.
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: LynSpace.md),
        ComposerAction(
          icon: Icons.send_rounded,
          label: AppLocalizations.tr(context, 'Send message'),
          onTap: widget.onStopRecording,
          filled: true,
        ),
      ],
    );
  }

  static String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}

/// A round 48dp action in the composer.
///
/// The composer's buttons were bare `GestureDetector`s around a 44px `Container`: no ripple, no pressed
/// state, and nothing for a screen reader to say, so a row of them announced as nothing at all. 48 is
/// Material's minimum target and comfortably over the HIG's 44pt.
class ComposerAction extends StatelessWidget {
  const ComposerAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.filled = false,
    this.foreground,
  });

  final IconData icon;

  /// Spoken by a screen reader and shown on a long hover. Icon-only controls carry no other name.
  final String label;

  final VoidCallback onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  /// Brand fill with a white glyph: the one primary action in the row.
  final bool filled;

  final Color? foreground;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = filled ? Colors.white : (foreground ?? LynSurface.textSecondary(isDark));

    final button = Material(
      color: filled ? LynPalette.indigo : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPressStart,
        onLongPressUp: onLongPressEnd,
        child: SizedBox(
          width: _size,
          height: _size,
          child: Icon(icon, size: 22, color: ink),
        ),
      ),
    );

    return Tooltip(
      message: label,
      child: Semantics(button: true, label: label, child: button),
    );
  }
}

/// The attach menu, with a name of its own.
class _AttachmentMenu extends StatelessWidget {
  const _AttachmentMenu({
    required this.isDark,
    required this.onCamera,
    required this.onGallery,
    required this.onFile,
  });

  final bool isDark;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label) => Row(
          children: [
            Icon(icon, size: 20, color: LynPalette.indigo),
            const SizedBox(width: LynSpace.md),
            Text(label, style: LynType.callout.copyWith(color: LynSurface.textPrimary(isDark))),
          ],
        );

    return PopupMenuButton<VoidCallback>(
      tooltip: AppLocalizations.tr(context, 'Attach a file'),
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: onCamera,
          child: item(Icons.camera_alt_outlined, AppLocalizations.tr(context, 'Camera')),
        ),
        PopupMenuItem(
          value: onGallery,
          child: item(Icons.photo_library_outlined, AppLocalizations.tr(context, 'Gallery')),
        ),
        PopupMenuItem(
          value: onFile,
          child: item(Icons.insert_drive_file_outlined, AppLocalizations.tr(context, 'File')),
        ),
      ],
      child: Semantics(
        button: true,
        label: AppLocalizations.tr(context, 'Attach a file'),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.attach_file_rounded, size: 22, color: LynSurface.textSecondary(isDark)),
        ),
      ),
    );
  }
}

/// "Hold to record", shown for a moment after the microphone is tapped rather than pressed.
class _HoldHint extends StatelessWidget {
  const _HoldHint({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: LynSpace.lg, vertical: LynSpace.sm),
      color: LynSurface.canvasAlt(isDark),
      child: Text(
        AppLocalizations.tr(context, 'Hold the microphone to record a voice message.'),
        textAlign: TextAlign.center,
        style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark)),
      ),
    );
  }
}

/// A filled pill with a label: the composer's one secondary action, styled like every other primary
/// button in the app rather than with an inline `ElevatedButton.styleFrom`.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LynPalette.indigo,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: LynSpace.lg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: LynSpace.sm),
              Text(label, style: LynType.callout.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The twenty bars that move while a voice message is being recorded.
class _Waveform extends StatelessWidget {
  const _Waveform({required this.animation});

  final Animation<double> animation;

  static const int _bars = 20;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_bars, (index) {
          final height = 4 + (math.sin((animation.value * math.pi * 2) + index * 0.5) * 20).abs();
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: LynPalette.indigo,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

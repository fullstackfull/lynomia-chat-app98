


import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../layout/cubit/cubit.dart';
import '../../layout/cubit/states.dart';
import '../../models/chatwoot_models.dart';
import '../../shared/app_localizations.dart';
import '../../shared/components/components.dart';
import '../../shared/styles/lyn_channel.dart';
import '../../shared/styles/lyn_feedback.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';
import 'widgets/chat_composer.dart';
import 'widgets/contact_details_sheet.dart';
import 'widgets/message_actions_sheet.dart';
import 'widgets/typing_indicator.dart';

// ═══════════════════════════════════════════════════════════════
// ChatScreen - Professional WhatsApp-like Experience v2.0
// ═══════════════════════════════════════════════════════════════
/// The content strings this app writes INSTEAD of a caption when it uploads an attachment, so the
/// server has something to show in a conversation list. They are protocol values, not copy: the
/// audio one is written by `chatwoot_api_service.dart`, and the other two sit in the message history
/// of installs that predate it. A bubble must recognise them so it does not print "🎵 تسجيل صوتي" as
/// a line of text under the clip it is describing.
const Set<String> _attachmentPlaceholders = {'📷 صورة', '📎 ملف', '🎵 تسجيل صوتي'};

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  // ─── Controllers ───────────────────────────────────────────
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _audioPlayer = AudioPlayer();
  final _audioRecorder = AudioRecorder();

  // ─── Scroll State ──────────────────────────────────────────
  bool _isAtBottom = true;
  bool _showScrollToBottom = false;
  bool _isLoadingMore = false;

  // ─── Selection ─────────────────────────────────────────────
  final Set<dynamic> _selectedMessageIds = {};
  bool get _isSelectionMode => _selectedMessageIds.isNotEmpty;

  // ─── Audio Recording ───────────────────────────────────────
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // ─── Audio Playback ────────────────────────────────────────
  bool _isPlayingAudio = false;
  int? _currentlyPlayingAudioId;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  bool _isAudioLoading = false;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  // ─── Animation Controllers ─────────────────────────────────
  late AnimationController _recordAnimationController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initAudioPlayer();
    _initRecordAnimation();

    // No listener on `_messageController`. It used to be `addListener(() => setState(() {}))`, which
    // rebuilt this entire screen -- the message list, every bubble, the app bar -- on every character
    // typed, to swap one button between a microphone and a send arrow. `ChatComposer` listens to the
    // controller around that button alone.
  }

  void _initAudioPlayer() {
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (mounted) setState(() => _audioPosition = position);
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlayingAudio = false;
          _currentlyPlayingAudioId = null;
          _audioPosition = Duration.zero;
        });
      }
    });
  }

  void _initRecordAnimation() {
    _recordAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _recordAnimationController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // SCROLL HANDLING
  // ═══════════════════════════════════════════════════════════════
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // ✅ مع reverse: true — pixels = 0 يعني أسفل المحادثة، وmaxScroll يعني أعلاها
    if (mounted) {
      setState(() {
        _isAtBottom = currentScroll < 100;
        _showScrollToBottom = currentScroll > 300;
      });
    }

    if ((maxScroll - currentScroll) < 100 && !_isLoadingMore) {
      final cubit = context.read<AppCubit>();
      // ✅ لا نطلب المزيد إذا وصلنا لبداية المحادثة
      if (cubit.hasMoreMessages) {
        _loadMoreMessages();
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    // ✅ مع reverse: true الأسفل هو الموضع 0
    if (animate) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(0);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD MORE MESSAGES
  // ═══════════════════════════════════════════════════════════════
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final cubit = context.read<AppCubit>();
      final accountId = cubit.selectedConversation?.accountId ?? 6;
      final conversationId = cubit.selectedConversation?.id ?? 0;

      // ✅ مع reverse: true لا حاجة لأي تعويض يدوي —
      // القائمة المعكوسة تحافظ على موضعك تلقائياً عند إضافة رسائل أقدم بالأعلى
      await cubit.loadMoreMessages(accountId, conversationId);
    } catch (e) {
      print('❌ Load more error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEND TEXT MESSAGE
  // ═══════════════════════════════════════════════════════════════
  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final cubit = context.read<AppCubit>();
    if (cubit.selectedConversation != null) {
      cubit.sendMessageAdminApi(content);
    } else {
      cubit.sendMessage(content);
    }

    _messageController.clear();
    _scrollToBottom();
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE PICKING (Image / Gallery / File)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (picked != null) {
        await _sendFile(File(picked.path));
      }
    } catch (e) {
      print('❌ Pick Image Error: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        await _sendFile(File(result.files.single.path!));
      }
    } catch (e) {
      print('❌ Pick File Error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEND FILE (Unified for all types)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _sendFile(File file) async {
    final cubit = context.read<AppCubit>();
    await cubit.sendMessageWithAttachment(file);
    _scrollToBottom();
  }

  // ═══════════════════════════════════════════════════════════════
  // AUDIO RECORDING (WhatsApp-style) - FIXED v2.0
  // ═══════════════════════════════════════════════════════════════
  Future<void> _startRecording() async {
    // ✅ طلب إذن الميكروفون
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      if (mounted) {
        LynFeedback.show(context, 'Microphone permission required', tone: LynTone.warning);
      }
      return;
    }

    // ✅ طلب إذن التخزين (للأندرويد)
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      if (storageStatus != PermissionStatus.granted) {
        // حاول بـ manage external storage للأندرويد 11+
        await Permission.manageExternalStorage.request();
      }
    }

    try {
      // ✅ التحقق من أن المسجل جاهز
      final isReady = await _audioRecorder.hasPermission();
      if (!isReady) {
        print('❌ Recorder not ready');
        return;
      }

      final dir = await getTemporaryDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = '${dir.path}/$fileName';

      print('🎙️ Starting recording to: $_recordingPath');

      // ✅ بدء التسجيل بإعدادات AAC
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });

      print('✅ Recording started successfully');
    } catch (e, stackTrace) {
      print('❌ Start Recording Error: $e');
      print(stackTrace);
      if (mounted) {
        LynFeedback.show(context, 'Could not start recording',
            tone: LynTone.error, actionKey: 'Retry', onAction: _startRecording);
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();

    try {
      print('🎙️ Stopping recording...');
      final path = await _audioRecorder.stop();
      print('🎙️ Recording stopped. Path: $path');

      setState(() => _isRecording = false);

      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final size = await file.length();
          print('✅ Recording file exists: ${file.path} | Size: $size bytes');

          if (size > 1000) { // ✅ التحقق من أن الملف ليس فارغاً
            await _sendFile(file);
          } else {
            print('⚠️ Recording file too small, might be empty');
            if (mounted) {
              LynFeedback.show(context, 'Recording too short', tone: LynTone.warning);
            }
          }
        } else {
          print('❌ Recording file does not exist');
        }
      } else {
        print('❌ Recording path is null');
      }
    } catch (e, stackTrace) {
      print('❌ Stop Recording Error: $e');
      print(stackTrace);
      if (mounted) {
        LynFeedback.show(context, 'Could not stop recording', tone: LynTone.error);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AUDIO PLAYBACK (WhatsApp-style with Progress)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _toggleAudio(String url, int messageId) async {
    try {
      // إيقاف التشغيل الحالي
      if (_currentlyPlayingAudioId == messageId && _isPlayingAudio) {
        await _audioPlayer.pause();
        setState(() => _isPlayingAudio = false);
        return;
      }

      // إذا كان ملف مختلف، نوقف القديم ونحمل الجديد
      if (_currentlyPlayingAudioId != messageId) {
        await _audioPlayer.stop();
        setState(() {
          _isAudioLoading = true;
          _currentlyPlayingAudioId = messageId;
          _audioPosition = Duration.zero;
          _audioDuration = Duration.zero;
        });

        // ✅ استخدام flutter_cache_manager للكاش الفعلي
        final file = await DefaultCacheManager().getSingleFile(url);
        print('✅ Audio cached at: ${file.path}');

        await _audioPlayer.setFilePath(file.path);
        final duration = await _audioPlayer.duration ?? Duration.zero;

        if (mounted) {
          setState(() {
            _audioDuration = duration;
            _isAudioLoading = false;
            _isPlayingAudio = true;
          });
        }

        await _audioPlayer.play();
      } else {
        // استئناف التشغيل
        setState(() => _isPlayingAudio = true);
        await _audioPlayer.play();
      }
    } catch (e) {
      print('❌ Audio Play Error: $e');
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
          _isPlayingAudio = false;
        });
        LynFeedback.show(context, 'Could not play this audio', tone: LynTone.error);
      }
    }
  }

  String _formatAudioDuration(Duration duration) {
    final mins = duration.inMinutes.toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  // ═══════════════════════════════════════════════════════════════
  // IMAGE VIEWER (Full Screen with Zoom, Share, Download)
  // ═══════════════════════════════════════════════════════════════
  void _viewImageFullScreen(String url, String? heroTag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageViewerScreen(
          imageUrl: url,
          heroTag: heroTag,
          isDark: AppCubit.get(context).isDark,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE OPENER - عرض في المتصفح بدون تحميل تلقائي
  // ═══════════════════════════════════════════════════════════════
  Future<void> _openFile(String url, String fileName) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();

      // ✅ الصور تعرض داخل التطبيق
      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
        _viewImageFullScreen(url, 'file_${url.hashCode}');
        return;
      }

      // ✅ الفيديو - فتح في مشغل خارجي
      if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return;
      }

      // ✅ الملفات الأخرى - عرض في المتصفح (Google Docs Viewer للـ PDF و Office)
      String viewerUrl;
      if (ext == 'pdf') {
        // ✅ عرض PDF في المتصفح بدون تحميل
        viewerUrl = 'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(url)}';
      } else if (['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext)) {
        // ✅ عرض Office في Google Docs Viewer
        viewerUrl = 'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(url)}';
      } else {
        // ✅ فتح الملف مباشرة في المتصفح
        viewerUrl = url;
      }

      final uri = Uri.parse(viewerUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // ✅ يفتح في المتصفح/تطبيق خارجي
        );
      } else {
        // fallback: مشاركة الرابط
        await Share.share(url, subject: fileName);
      }
    } catch (e) {
      print('❌ Open File Error: $e');
      if (mounted) {
        LynFeedback.show(context, 'Cannot open file', tone: LynTone.error);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SELECTION HANDLERS
  // ═══════════════════════════════════════════════════════════════
  void _toggleMessageSelection(dynamic messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _clearSelection() => setState(() => _selectedMessageIds.clear());

  // ═══════════════════════════════════════════════════════════════
  // DELETE HANDLERS
  // ═══════════════════════════════════════════════════════════════
  Future<void> _deleteSingleMessage(dynamic messageId, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteDialog(isDark: isDark, isMultiple: false),
    );
    if (confirmed != true) return;

    try {
      final cubit = context.read<AppCubit>();
      await cubit.deleteMessage(messageId);
      setState(() => cubit.messages.removeWhere((m) => m['id'] == messageId));
    } catch (e) {
      if (mounted) {
        LynFeedback.show(context, 'Delete failed', tone: LynTone.error);
      }
    }
  }

  Future<void> _deleteSelectedMessages(bool isDark) async {
    if (_selectedMessageIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteDialog(isDark: isDark, isMultiple: true, count: _selectedMessageIds.length),
    );
    if (confirmed != true) return;

    try {
      final cubit = context.read<AppCubit>();
      final deletedIds = <dynamic>[];

      for (final id in _selectedMessageIds) {
        try {
          await cubit.deleteMessage(id);
          deletedIds.add(id);
        } catch (e) {
          print('❌ Failed to delete $id: $e');
        }
      }

      setState(() {
        cubit.messages.removeWhere((m) => deletedIds.contains(m['id']));
        _selectedMessageIds.clear();
      });
    } catch (e) {
      if (mounted) {
        LynFeedback.show(context, 'Delete failed', tone: LynTone.error);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is AppMessagesLoadedState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(animate: false);
          });
        }
        if (state is AppNewMessageReceivedState) {
          if (_isAtBottom) {
            Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom());
          }
        }
      },
      builder: (context, state) {
        final cubit = AppCubit.get(context);
        final messages = cubit.messages;
        final isDark = cubit.isDark;

        return Scaffold(
          backgroundColor: LynSurface.canvasAlt(isDark),
          appBar: _buildAppBar(cubit, isDark),
          body: Column(
            children: [
              if (cubit.is24HourWindowRestricted(cubit.selectedConversation))
                _build24HourWindowBanner(isDark),
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildMessagesList(messages, isDark, state),
              ),
              if (cubit.isTyping) TypingIndicator(isDark: isDark),
              _buildInputField(isDark),
            ],
          ),
          floatingActionButton: _showScrollToBottom
              ? _buildScrollToBottomButton()
              : null,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar(AppCubit cubit, bool isDark) {
    if (_isSelectionMode) {
      return _buildSelectionAppBar(cubit, isDark);
    }
    return _buildNormalAppBar(cubit, isDark);
  }

  PreferredSizeWidget _buildSelectionAppBar(AppCubit cubit, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: LynPalette.indigo,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: _clearSelection,
      ),
      title: Text(
        AppLocalizations.tr(context, '{count} selected').replaceFirst('{count}', _selectedMessageIds.length.toString()),
        style: LynType.headline.copyWith(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: () => _deleteSelectedMessages(isDark),
        ),
        IconButton(
          icon: const Icon(Icons.select_all, color: Colors.white),
          onPressed: () {
            setState(() {
              if (_selectedMessageIds.length == cubit.messages.length) {
                _selectedMessageIds.clear();
              } else {
                _selectedMessageIds.clear();
                for (final msg in cubit.messages) {
                  if (msg['id'] != null) _selectedMessageIds.add(msg['id']);
                }
              }
            });
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildNormalAppBar(AppCubit cubit, bool isDark) {
    final conversation = cubit.selectedConversation;
    final contactName = conversation?.contactName ?? AppLocalizations.tr(context, 'Conversation');
    final channelType = conversation?.channelType ?? '';
    final avatarUrl = conversation?.contactAvatar;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: LynSurface.surface(isDark),
      // A hairline, not a shadow. The bar and the canvas are two close tones, so they need a line to
      // part them; a shadow at this contrast only smudges the boundary.
      shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
      titleSpacing: 0,
      leadingWidth: 44,
      leading: IconButton(
        // No direction check: `Icons.arrow_back_ios_new` is `matchTextDirection: true`, so `Icon`
        // flips it under RTL by itself. Swapping the glyph as well mirrored it twice and left the
        // Arabic back button pointing left.
        icon: Icon(Icons.arrow_back_ios_new,
            size: 20, color: LynSurface.textPrimary(isDark)),
        onPressed: () => Navigator.pop(context),
      ),
      title: InkWell(
        onTap: () => _showContactDetailsBottomSheet(cubit, isDark),
        borderRadius: BorderRadius.circular(LynSpace.md),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: LynSpace.sm, top: LynSpace.sm, bottom: LynSpace.sm),
          child: Row(
            children: [
              _buildAvatar(avatarUrl, contactName, isDark, size: 38),
              const SizedBox(width: LynSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contactName,
                      style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      LynChannel.label(context, channelType),
                      style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════
  // AVATAR WIDGET
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAvatar(String? avatarUrl, String contactName, bool isDark, {required double size}) {
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Hero(
      tag: 'contact_avatar_${contactName.hashCode}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hasAvatar ? null : LynPalette.indigo.withOpacity(0.14),
          shape: BoxShape.circle,
          border: Border.all(color: LynSurface.border(isDark)),
          image: hasAvatar
              ? DecorationImage(image: CachedNetworkImageProvider(avatarUrl), fit: BoxFit.cover)
              : null,
        ),
        child: !hasAvatar
            ? Center(
          child: Text(
            contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
            style: LynType.subtitle.copyWith(color: LynPalette.indigo, fontSize: size * 0.42, height: 1),
          ),
        )
            : null,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CONTACT DETAILS BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════
  void _showContactDetailsBottomSheet(AppCubit cubit, bool isDark) {
    final conversation = cubit.selectedConversation;
    if (conversation?.contactId == null) return;

    cubit.fetchContactDetails(conversation!.contactId!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocConsumer<AppCubit, AppStates>(
        listener: (context, state) {
          if (state is AppUpdateContactSuccessState) {
            Navigator.pop(context);
            _showContactDetailsBottomSheet(cubit, isDark);
          }
          if (state is AppUpdateContactErrorState) {
            LynFeedback.show(context, state.error, tone: LynTone.error);
          }
        },
        builder: (context, state) {
          final details = cubit.currentContactDetails;
          final name = details?['name']?.toString() ?? conversation.contactName ?? '';

          return ContactDetailsSheet(
            contact: ContactDetails(
              name: name,
              email: details?['email']?.toString() ?? conversation.contactEmail ?? '',
              phone: details?['phone_number']?.toString() ?? conversation.contactPhone ?? '',
              avatarUrl: details?['thumbnail']?.toString() ?? conversation.contactAvatar,
              channelType: conversation.channelType,
              lastActivity: conversation.lastMessageAt,
            ),
            isDark: isDark,
            isLoading: state is AppFetchContactDetailsLoadingState ||
                state is AppUpdateContactLoadingState,
            onEditName: () => showDialog(
              context: context,
              builder: (_) => EditContactNameDialog(
                currentName: name,
                isDark: isDark,
                onSave: (next) => cubit.updateContactName(conversation.contactId!, next),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGES LIST (Performance Optimized)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMessagesList(List<Map<String, dynamic>> messages, bool isDark, AppStates state) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true, // ✅ مثل واتساب: مرساة من الأسفل + الحفاظ على الموضع عند تحميل القديم تلقائياً
      padding: const EdgeInsets.symmetric(vertical: LynSpace.sm),
      itemCount: messages.length + (_isLoadingMore ? 1 : 0),
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        // ✅ في القائمة المعكوسة: آخر index = أعلى الشاشة (مؤشر التحميل)
        if (_isLoadingMore && index == messages.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(LynSpace.lg),
              child: CircularProgressIndicator(color: LynPalette.indigo, strokeWidth: 2),
            ),
          );
        }

        // ✅ عكس المؤشر: index 0 في القائمة المعكوسة = أحدث رسالة
        final actualIndex = messages.length - 1 - index;
        final message = messages[actualIndex];
        final isOutgoing = _isOutgoing(message);

        // A RUN is consecutive messages from the same side on the same day. Only the run's last bubble
        // gets the pointed tail and only its first carries the sender's name, so a burst of four replies
        // reads as one utterance rather than four stacked cards.
        final previous = actualIndex > 0 ? messages[actualIndex - 1] : null;
        final next = actualIndex < messages.length - 1 ? messages[actualIndex + 1] : null;
        final day = _dayOf(message);
        final startsDay = previous == null || _dayOf(previous) != day;
        final startsRun = startsDay || _isOutgoing(previous) != isOutgoing;
        final endsRun = next == null || _isOutgoing(next) != isOutgoing || _dayOf(next) != day;

        final bubble = _buildMessageBubble(
          message: message,
          isOutgoing: isOutgoing,
          showSender: startsRun && _getSenderName(message) != (previous == null ? null : _getSenderName(previous)),
          startsRun: startsRun,
          endsRun: endsRun,
          isDark: isDark,
        );

        if (!startsDay) return bubble;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildDaySeparator(message, isDark), bubble],
        );
      },
    );
  }

  /// The calendar day a message belongs to, as a sortable `yyyy-mm-dd`, or an empty string when the
  /// message carries no parseable timestamp — in which case it never starts a day and never breaks a run.
  String _dayOf(Map<String, dynamic> message) {
    final at = _parseDateTime(message['created_at']);
    if (at == null) return '';
    final local = at.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  /// A date, once, above the first message of each day. It is what lets every bubble below it show a bare
  /// clock time instead of repeating "Mar 12," on all eighty of them.
  Widget _buildDaySeparator(Map<String, dynamic> message, bool isDark) {
    final at = _parseDateTime(message['created_at'])?.toLocal();
    if (at == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(at.year, at.month, at.day);
    final days = today.difference(that).inDays;

    final String label;
    if (days == 0) {
      label = AppLocalizations.tr(context, 'Today');
    } else if (days == 1) {
      label = AppLocalizations.tr(context, 'Yesterday');
    } else {
      label = intl.DateFormat(
        days < 365 ? 'MMMM d' : 'MMMM d, yyyy',
        Localizations.localeOf(context).toString(),
      ).format(at);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LynSpace.lg),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: LynSpace.md, vertical: LynSpace.xs + 2),
          decoration: BoxDecoration(
            color: LynSurface.surface(isDark),
            border: Border.all(color: LynSurface.border(isDark)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: LynType.micro.copyWith(color: LynSurface.textSecondary(isDark))),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE BUBBLE (WhatsApp-style with Attachments)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMessageBubble({
    required Map<String, dynamic> message,
    required bool isOutgoing,
    required bool showSender,
    required bool startsRun,
    required bool endsRun,
    required bool isDark,
  }) {
    final content = message['content']?.toString() ?? '';
    final senderName = _getSenderName(message);
    final createdAt = _parseDateTime(message['created_at']);
    // A bare clock time. The calendar date is carried once by the day separator above the run, so
    // repeating it inside every bubble only crowds the message it is supposed to annotate.
    final timeText = createdAt != null
        ? intl.DateFormat.jm(Localizations.localeOf(context).toString()).format(createdAt.toLocal())
        : '';
    final messageId = message['id'];
    final isSelected = _selectedMessageIds.contains(messageId);
    final attachments = message['attachments'] as List<dynamic>?;
    final hasAttachments = attachments != null && attachments.isNotEmpty;
    final hasText = content.isNotEmpty && !_attachmentPlaceholders.contains(content);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) _toggleMessageSelection(messageId);
      },
      onLongPress: () => _showMessageOptions(message, isDark, content, messageId),
      child: Container(
        width: double.infinity,
        color: isSelected
            ? (isDark ? LynPalette.indigo.withOpacity(0.15) : LynPalette.indigo.withOpacity(0.08))
            : Colors.transparent,
        child: Padding(
          // Tight inside a run, open between runs: the gap is what groups the bubbles, so it has to be
          // visibly different from the one that separates them.
          padding: EdgeInsets.only(
            left: LynSpace.lg,
            right: LynSpace.lg,
            top: startsRun ? LynSpace.sm + 2 : 2,
            bottom: endsRun ? 2 : 0,
          ),
          child: Align(
            // DIRECTIONAL, not left/right. In Arabic the agent's own replies belong on the start edge
            // and the customer's on the end edge, exactly mirrored; `Alignment.centerRight` would pin
            // them to the same physical side in both scripts and read as backwards to half this market.
            alignment: isOutgoing ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelected && !isOutgoing) _buildSelectionCheck(),
                Flexible(
                  child: Column(
                    crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isOutgoing && showSender)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: LynSpace.md, bottom: LynSpace.xs),
                          child: Text(senderName,
                              style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark))),
                        ),
                      if (hasAttachments) _buildAttachmentsList(attachments, isDark, isOutgoing, messageId),
                      // Real text, if there is any: a placeholder standing in for the attachment is
                      // not something to print beside the attachment itself.
                      if (hasText)
                        Padding(
                          // Clear of the attachment it captions; flush when it is the whole message.
                          padding: EdgeInsets.only(top: hasAttachments ? LynSpace.xs : 0),
                          child: _buildTextBubble(message, content, timeText, isOutgoing, isDark, isSelected,
                              endsRun: endsRun),
                        ),
                    ],
                  ),
                ),
                if (isSelected && isOutgoing) _buildSelectionCheck(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCheck() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: LynSpace.md, top: LynSpace.sm),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: LynPalette.indigo, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildTextBubble(
    Map<String, dynamic> message,
    String content,
    String timeText,
    bool isOutgoing,
    bool isDark,
    bool isSelected, {
    bool endsRun = true,
  }) {
    final status = message['status']?.toString().toLowerCase();
    final isFailed = status == 'failed' || message['is_failed'] == true;
    // In flight: the optimistic copy the cubit appends before the request returns. It carries
    // `is_temp` until the real message replaces it, which is the one delivery fact this app actually
    // holds -- the API gives no per-message read receipt.
    final isSending = message['is_temp'] == true;

    // The tail -- the one corner that is cut back to 4 -- marks the side a message came from, so it
    // belongs on the LAST bubble of a run and nowhere else. The other three corners stay at 18.
    // Directional, so the tail follows the start/end edge rather than a fixed physical one.
    const tail = Radius.circular(4);
    const round = Radius.circular(18);
    final radius = BorderRadiusDirectional.only(
      topStart: round,
      topEnd: round,
      bottomStart: isOutgoing || !endsRun ? round : tail,
      bottomEnd: isOutgoing && endsRun ? tail : round,
    );

    return Column(
      crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: LynSpace.lg, vertical: LynSpace.sm + 2),
          decoration: BoxDecoration(
            color: isFailed
                ? (LynSurface.dangerSurface(isDark))
                : (isOutgoing ? LynPalette.indigo : (LynSurface.surface(isDark))),
            borderRadius: radius,
            // An incoming bubble is separated from the canvas by a hairline, not by a drop shadow. The
            // shadow this replaces was a flat 5% black under every bubble: on the dark canvas it was
            // invisible, and on the light one it put the same grey halo under eighty elements, which
            // reads as texture rather than as depth. The outgoing bubble is solid indigo and needs
            // neither.
            border: isSelected
                ? Border.all(color: LynPalette.indigo, width: 2)
                : isFailed
                    ? Border.all(color: LynPalette.dangerSoft, width: 1)
                    : isOutgoing
                        ? null
                        : Border.all(color: LynSurface.border(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                content,
                style: LynType.body.copyWith(
                  color: isFailed
                      ? (LynSurface.dangerText(isDark))
                      : (isOutgoing ? Colors.white : (LynSurface.textPrimary(isDark))),
                ),
                // START, not right. A hard `TextAlign.right` set every English message ragged-left
                // inside a left-aligned bubble; `start` resolves to the correct edge in both scripts.
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: LynSpace.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeText,
                    style: LynType.micro.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isFailed
                          ? LynPalette.danger
                          : (isOutgoing ? Colors.white.withOpacity(0.92) : LynSurface.textSecondary(isDark)),
                    ),
                  ),
                  if (isOutgoing && !isFailed) ...[
                    const SizedBox(width: LynSpace.xs),
                    // ONE check, not two. `Icons.done_all` is the double tick every messaging app on
                    // earth uses for "delivered", and it was drawn on every outgoing message
                    // regardless -- including one still waiting on the request. This app is never
                    // told that a message was delivered or read, so it says only what it knows: a
                    // clock while the send is in flight, a single check once the server has it.
                    Semantics(
                      label: AppLocalizations.tr(context, isSending ? 'Sending...' : 'Sent'),
                      child: Icon(
                        isSending ? Icons.schedule : Icons.done,
                        size: 14,
                        color: Colors.white.withOpacity(isSending ? 0.72 : 0.92),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (isFailed)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: LynSpace.xs, end: LynSpace.xs),
            child: InkWell(
              onTap: () {
                final cubit = context.read<AppCubit>();
                if (cubit.is24HourWindowRestricted(cubit.selectedConversation)) {
                  _showWhatsAppTemplatesModal(context, cubit, isDark);
                } else {
                  cubit.retrySendMessage(message);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.tr(context, 'Failed to send'),
                    style: LynType.caption.copyWith(color: LynPalette.danger, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: LynSpace.xs),
                  Icon(Icons.error_outline, color: LynPalette.danger, size: 14),
                  const SizedBox(width: 4),
                  Icon(Icons.refresh, color: LynPalette.danger, size: 14),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ATTACHMENTS LIST
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAttachmentsList(List<dynamic> attachments, bool isDark, bool isOutgoing, int messageId) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: attachments.map((attachment) {
        final isImage = attachment['is_image'] == true;
        final isAudio = attachment['is_audio'] == true;
        final isVideo = attachment['is_video'] == true;
        final fileUrl = attachment['file_url']?.toString() ?? '';
        final thumbUrl = attachment['thumb_url']?.toString();
        final fileName = attachment['file_name']?.toString() ?? AppLocalizations.tr(context, 'File');
        final attachmentId = attachment['id'] ?? 0;

        if (isImage) {
          return _buildImageAttachment(fileUrl, thumbUrl, isDark, isOutgoing);
        } else if (isAudio) {
          return _buildAudioAttachment(fileUrl, fileName, attachmentId, isDark, isOutgoing, messageId);
        } else if (isVideo) {
          return _buildVideoAttachment(fileUrl, thumbUrl, isDark, isOutgoing);
        } else {
          return _buildFileAttachment(fileUrl, fileName, isDark, isOutgoing);
        }
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // IMAGE ATTACHMENT (Displayed inside app)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildImageAttachment(String url, String? thumbUrl, bool isDark, bool isOutgoing) {
    // ✅ استخدام thumbUrl إذا كان موجود، وإلا استخدام fileUrl
    final imageUrl = (thumbUrl != null && thumbUrl.isNotEmpty) ? thumbUrl : url;
    
    return GestureDetector(
      onTap: () => _viewImageFullScreen(url, 'image_${url.hashCode}'),
      child: Hero(
        tag: 'image_${url.hashCode}',
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: LynSurface.surfaceMuted(isDark)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: 250,
              height: 200,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: LynSurface.border(isDark),
                highlightColor: LynSurface.surfaceRaised(isDark),
                child: Container(width: 250, height: 200, color: Colors.white),
              ),
              errorWidget: (context, url, error) => Container(
                width: 200,
                height: 150,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: LynSurface.textTertiary(isDark), size: 40),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.tr(context, 'Image failed to load'), style: LynType.caption.copyWith(
                      color: LynSurface.textSecondary(isDark),
                      fontWeight: FontWeight.w400,
                    )),
                    const SizedBox(height: 4),
                    Text('URL: ${imageUrl.length > 30 ? imageUrl.substring(0, 30) + '...' : imageUrl}', style: LynType.micro.copyWith(
                      color: LynSurface.textTertiary(isDark),
                      fontWeight: FontWeight.w400,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AUDIO ATTACHMENT (WhatsApp-style with Progress Bar)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAudioAttachment(String url, String fileName, int id, bool isDark, bool isOutgoing, int messageId) {
    final isPlaying = _currentlyPlayingAudioId == messageId && _isPlayingAudio;
    final isLoading = _currentlyPlayingAudioId == messageId && _isAudioLoading;
    final isCurrentAudio = _currentlyPlayingAudioId == messageId;

    return GestureDetector(
      onTap: isLoading ? null : () => _toggleAudio(url, messageId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isOutgoing ? LynPalette.indigo.withOpacity(0.95) : (LynSurface.surfaceMuted(isDark)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Play/Pause Button with Loading
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isOutgoing ? Colors.white.withOpacity(0.2) : LynPalette.indigo.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isOutgoing ? Colors.white : LynPalette.indigo,
                  ),
                )
                    : Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isOutgoing ? Colors.white : LynPalette.indigo,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // ✅ Progress Bar & Duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // شريط التقدم
                  SizedBox(
                    height: 30,
                    child: isCurrentAudio && !isLoading
                        ? SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: isOutgoing ? Colors.white.withOpacity(0.8) : LynPalette.indigo,
                        inactiveTrackColor: isOutgoing ? Colors.white.withOpacity(0.3) : LynPalette.indigo.withOpacity(0.2),
                        thumbColor: isOutgoing ? Colors.white : LynPalette.indigo,
                      ),
                      child: Slider(
                        value: _audioDuration.inMilliseconds > 0
                            ? math.max(0, math.min(1, _audioPosition.inMilliseconds / _audioDuration.inMilliseconds))
                            : 0,
                        onChanged: (value) async {
                          final position = Duration(milliseconds: (value * _audioDuration.inMilliseconds).round());
                          await _audioPlayer.seek(position);
                        },
                      ),
                    )
                        : Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: isOutgoing ? Colors.white.withOpacity(0.3) : LynPalette.indigo.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // المدة
                  Text(
                    isCurrentAudio && !isLoading
                        ? '${_formatAudioDuration(_audioPosition)} / ${_formatAudioDuration(_audioDuration)}'
                        : AppLocalizations.tr(context, 'Voice message'),
                    style: LynType.micro.copyWith(
                      color: isOutgoing ? Colors.white.withOpacity(0.8) : LynSurface.textSecondary(isDark),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // VIDEO ATTACHMENT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildVideoAttachment(String url, String? thumbUrl, bool isDark, bool isOutgoing) {
    return GestureDetector(
      onTap: () => _openFile(url, 'video.mp4'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 200),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: LynSurface.surfaceMuted(isDark)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CachedNetworkImage(
                imageUrl: thumbUrl ?? '',
                fit: BoxFit.cover,
                width: 250,
                height: 200,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: LynSurface.border(isDark),
                  highlightColor: LynSurface.surfaceRaised(isDark),
                  child: Container(width: 250, height: 200, color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 250,
                  height: 200,
                  color: LynSurface.surfaceMuted(isDark),
                  child: Icon(Icons.videocam, color: LynSurface.textTertiary(isDark), size: 50),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE ATTACHMENT (Open in viewer without auto-download)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFileAttachment(String url, String fileName, bool isDark, bool isOutgoing) {
    final extension = fileName.split('.').last.toUpperCase();

    return GestureDetector(
      onTap: () => _openFile(url, fileName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isOutgoing ? LynPalette.indigo.withOpacity(0.95) : (LynSurface.surfaceMuted(isDark)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isOutgoing ? Colors.white.withOpacity(0.2) : LynPalette.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(extension, style: LynType.caption.copyWith(
                  color: isOutgoing ? Colors.white : LynPalette.indigo,
                  fontWeight: FontWeight.bold,
                )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(fileName, style: LynType.callout.copyWith(
                    color: isOutgoing ? Colors.white : LynSurface.textPrimary(isDark),
                  ), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.tr(context, 'Tap to open'), style: LynType.micro.copyWith(
                    color: isOutgoing ? Colors.white.withOpacity(0.7) : LynSurface.textSecondary(isDark),
                    fontWeight: FontWeight.w400,
                  )),
                ],
              ),
            ),
            Icon(Icons.open_in_new, color: isOutgoing ? Colors.white.withOpacity(0.7) : LynSurface.textSecondary(isDark), size: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE OPTIONS BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════
  void _showMessageOptions(Map<String, dynamic> message, bool isDark, String content, dynamic messageId) {
    if (_isSelectionMode) {
      _toggleMessageSelection(messageId);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: LynSurface.surface(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => MessageActionsSheet(
        isDark: isDark,
        canCopy: content.isNotEmpty,
        onCopy: () {
          Navigator.pop(sheetContext);
          Clipboard.setData(ClipboardData(text: content));
          LynFeedback.show(context, 'Copied', tone: LynTone.success, duration: const Duration(seconds: 1));
        },
        onSelect: () {
          Navigator.pop(sheetContext);
          _toggleMessageSelection(messageId);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          _deleteSingleMessage(messageId, isDark);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INPUT FIELD (with Voice Recording)
  // ═══════════════════════════════════════════════════════════════
  /// The composer, which now lives in `widgets/chat_composer.dart`.
  ///
  /// Everything it needs is passed in: this screen owns the recording state and the pickers, and the
  /// composer owns how they look and how they are reached.
  Widget _buildInputField(bool isDark) {
    final cubit = AppCubit.get(context);
    final channelType = cubit.selectedConversation?.channelType?.toLowerCase() ??
        cubit.selectedInbox?.channelType?.toLowerCase() ??
        '';

    return ChatComposer(
      controller: _messageController,
      isDark: isDark,
      isWhatsAppChannel: channelType.contains('whatsapp'),
      isRestrictedToTemplates: cubit.is24HourWindowRestricted(cubit.selectedConversation),
      isRecording: _isRecording,
      recordingSeconds: _recordingSeconds,
      recordAnimation: _recordAnimationController,
      onSend: _sendMessage,
      onStartRecording: _startRecording,
      onStopRecording: _stopRecording,
      onCancelRecording: _discardRecording,
      onPickCamera: () => _pickImage(ImageSource.camera),
      onPickGallery: () => _pickImage(ImageSource.gallery),
      onPickFile: _pickFile,
      onOpenTemplates: () => _showWhatsAppTemplatesModal(context, cubit, isDark),
    );
  }

  /// Throw the recording away. The send path is `_stopRecording`; this one stops the recorder and keeps
  /// nothing, which is what the bin in the recording bar has always meant.
  Future<void> _discardRecording() async {
    try {
      await _audioRecorder.stop();
    } catch (e) {
      print('❌ Error stopping recorder: $e');
    }
    _recordingTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
    });
  }

  Widget _build24HourWindowBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: LynSpace.md, vertical: LynSpace.md),
      margin: const EdgeInsets.fromLTRB(LynSpace.md, LynSpace.md, LynSpace.md, 0),
      decoration: BoxDecoration(
        color: LynSurface.dangerSurface(isDark),
        borderRadius: BorderRadius.circular(LynSpace.md),
        border: Border.all(color: LynPalette.dangerSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_rounded, color: LynPalette.danger, size: 18),
          const SizedBox(width: LynSpace.sm + 2),
          Expanded(
            child: Text(
              AppLocalizations.tr(context, 'You can only reply to this conversation using a template message due to 24 hour message window restriction'),
              style: LynType.caption.copyWith(color: LynSurface.dangerText(isDark), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SCROLL TO BOTTOM BUTTON
  // ═══════════════════════════════════════════════════════════════
  Widget _buildScrollToBottomButton() {
    return FloatingActionButton.small(
      onPressed: () => _scrollToBottom(),
      backgroundColor: LynPalette.indigo,
      child: const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: LynPalette.indigo.withOpacity(isDark ? 0.16 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 32, color: LynPalette.indigo),
          ),
          const SizedBox(height: LynSpace.xl),
          Text(AppLocalizations.tr(context, 'No messages yet'),
              style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark))),
          const SizedBox(height: LynSpace.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LynSpace.xxl),
            child: Text(
              AppLocalizations.tr(context, 'Start the conversation by sending a message'),
              textAlign: TextAlign.center,
              style: LynType.callout.copyWith(color: LynSurface.textSecondary(isDark)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════
  bool _isOutgoing(Map<String, dynamic> message) {
    final senderType = message['sender_type']?.toString().toLowerCase() ?? '';
    final messageType = message['message_type']?.toString().toLowerCase() ?? '';
    return senderType == 'user' || senderType == 'agent' || messageType == 'outgoing' || messageType == '1';
  }

  String _getSenderName(Map<String, dynamic> message) {
    return message['sender_name']?.toString() ?? message['sender']?['name']?.toString() ?? AppLocalizations.tr(context, 'Unknown');
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      if (value.toString().length == 10) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════
// IMAGE VIEWER SCREEN (Full Screen with Zoom & Share)
// ═══════════════════════════════════════════════════════════════
class _ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final bool isDark;

  const _ImageViewerScreen({
    required this.imageUrl,
    this.heroTag,
    required this.isDark,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.black,
  appBar: AppBar(
    backgroundColor: Colors.black.withOpacity(0.5),
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.white),
    actions: [
      IconButton(
        icon: const Icon(Icons.share, color: Colors.white),
        onPressed: () => Share.share(widget.imageUrl),
      ),
      IconButton(
        icon: const Icon(Icons.download, color: Colors.white),
        onPressed: () => _downloadImage(),
      ),
    ],
  ),
  body: Center(
    child: Hero(
      tag: widget.heroTag ?? '',
      child: PhotoView(
        imageProvider: CachedNetworkImageProvider(widget.imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 64),
        ),
      ),
    ),
  ),
);
}

Future<void> _downloadImage() async {
  try {
    LynFeedback.show(context, 'Saving image');

    // ✅ طلب إذن التخزين للأندرويد
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      if (storageStatus != PermissionStatus.granted) {
        await Permission.manageExternalStorage.request();
      }
    }

    // ✅ استخدام flutter_cache_manager لتحميل الصورة
    final file = await DefaultCacheManager().getSingleFile(widget.imageUrl);
    
    // ✅ حفظ الصورة في مجلد Downloads
    final directory = Platform.isAndroid 
        ? Directory('/storage/emulated/0/Download')
        : await getApplicationDocumentsDirectory();
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await file.copy('${directory.path}/$fileName');
    
    if (mounted) {
      LynFeedback.show(context, 'Image saved', tone: LynTone.success);
    }
  } catch (e) {
    print('❌ Download Error: $e');
    if (mounted) {
      LynFeedback.show(context, 'Could not save image',
          tone: LynTone.error, actionKey: 'Retry', onAction: _downloadImage);
    }
  }
}
}

// ═══════════════════════════════════════════════════════════════
// DELETE DIALOG WIDGET
// ═══════════════════════════════════════════════════════════════
class _DeleteDialog extends StatelessWidget {
  final bool isDark;
  final bool isMultiple;
  final int? count;

  const _DeleteDialog({
    required this.isDark,
    required this.isMultiple,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: LynSurface.surface(isDark),
      title: Text(
        isMultiple
            ? AppLocalizations.tr(context, 'Delete {count} messages').replaceFirst('{count}', count.toString())
            : AppLocalizations.tr(context, 'Delete Message'),
        textAlign: TextAlign.right,
        style: TextStyle(color: LynSurface.textPrimary(isDark)),
      ),
      content: Text(
        isMultiple
            ? AppLocalizations.tr(context, 'Are you sure you want to delete the selected messages?')
            : AppLocalizations.tr(context, 'Are you sure you want to delete this message?'),
        textAlign: TextAlign.right,
        style: TextStyle(color: LynSurface.textSecondary(isDark)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.tr(context, 'cancel'), style: TextStyle(color: LynPalette.indigo)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(AppLocalizations.tr(context, 'Delete'), style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WHATSAPP TEMPLATES MODAL BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════
void _showWhatsAppTemplatesModal(BuildContext context, AppCubit cubit, bool isDark) {
  cubit.fetchWhatsAppTemplates();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _WhatsAppTemplatesBottomSheet(cubit: cubit, isDark: isDark),
  );
}

class _WhatsAppTemplatesBottomSheet extends StatefulWidget {
  final AppCubit cubit;
  final bool isDark;

  const _WhatsAppTemplatesBottomSheet({required this.cubit, required this.isDark});

  @override
  State<_WhatsAppTemplatesBottomSheet> createState() => _WhatsAppTemplatesBottomSheetState();
}

class _WhatsAppTemplatesBottomSheetState extends State<_WhatsAppTemplatesBottomSheet> {
  WhatsAppTemplate? _selectedTemplate;
  final Map<String, TextEditingController> _paramControllers = {};
  String _searchQuery = '';

  @override
  void dispose() {
    for (var c in _paramControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectTemplate(WhatsAppTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _paramControllers.clear();
      for (var varName in template.variables) {
        _paramControllers[varName] = TextEditingController();
      }
    });
  }

  void _goBack() {
    setState(() {
      _selectedTemplate = null;
    });
  }

  void _sendTemplate() {
    if (_selectedTemplate == null) return;

    final Map<String, String> params = {};
    _paramControllers.forEach((key, controller) {
      params[key] = controller.text.trim();
    });

    widget.cubit.sendWhatsAppTemplate(
      template: _selectedTemplate!,
      parameters: params.isNotEmpty ? params : null,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom + 16,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: LynSurface.surface(widget.isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BlocConsumer<AppCubit, AppStates>(
        listener: (context, state) {
          if (state is AppSendWhatsAppTemplateSuccessState) {
            CustomToast.show(
              context: context,
              message: AppLocalizations.tr(context, 'Send Message'),
              state: ToastStates.success,
            );
          }
          if (state is AppSendWhatsAppTemplateErrorState) {
            CustomToast.show(
              context: context,
              message: state.error,
              state: ToastStates.error,
            );
          }
        },
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: LynSurface.borderStrong(widget.isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.tr(context, 'Whatsapp Templates'),
                          style: LynType.headline.copyWith(
                            color: LynSurface.textPrimary(widget.isDark),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTemplate == null
                              ? AppLocalizations.tr(context, 'Select the whatsapp template you want to send')
                              : AppLocalizations.tr(context, 'Configure template: {name}').replaceFirst('{name}', _selectedTemplate!.name),
                          style: LynType.callout.copyWith(
                            color: LynSurface.textSecondary(widget.isDark),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: LynSurface.textSecondary(widget.isDark)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content based on screen state
              if (_selectedTemplate == null)
                _buildTemplateListScreen(state)
              else
                _buildTemplateConfigureScreen(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTemplateListScreen(AppStates state) {
    final templates = widget.cubit.whatsappTemplates.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.bodyText?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    return Expanded(
      child: Column(
        children: [
          // Search & Refresh Row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: LynSurface.canvas(widget.isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: LynSurface.border(widget.isDark),
                    ),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: LynSurface.textPrimary(widget.isDark)),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.tr(context, 'Search Templates'),
                      hintStyle: TextStyle(color: LynSurface.textTertiary(widget.isDark)),
                      prefixIcon: Icon(Icons.search, color: LynSurface.textTertiary(widget.isDark)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: LynSurface.canvas(widget.isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: LynSurface.border(widget.isDark),
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.refresh, color: LynPalette.indigo),
                  onPressed: () => widget.cubit.fetchWhatsAppTemplates(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Template List View
          Expanded(
            child: state is AppFetchWhatsAppTemplatesLoadingState && templates.isEmpty
                ? Center(child: CircularProgressIndicator(color: LynPalette.indigo))
                : templates.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.tr(context, 'No templates found'),
                          style: TextStyle(color: LynSurface.textTertiary(widget.isDark)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: templates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          return _buildTemplateCard(template);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(WhatsAppTemplate template) {
    return InkWell(
      onTap: () => _selectTemplate(template),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LynSurface.canvas(widget.isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: LynSurface.border(widget.isDark),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: LynType.subtitle.copyWith(
                      color: LynSurface.textPrimary(widget.isDark),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: LynSurface.border(widget.isDark),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Language: ${template.language ?? 'en'}',
                    style: LynType.caption.copyWith(
                      color: LynSurface.textPrimary(widget.isDark),
                    ),
                  ),
                ),
              ],
            ),
            if (template.headerText != null) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.tr(context, 'Header'),
                style: LynType.caption.copyWith(
                  color: LynSurface.textSecondary(widget.isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                template.headerText!,
                style: LynType.callout.copyWith(
                  color: LynSurface.textPrimary(widget.isDark),
                ),
              ),
            ],
            if (template.bodyText != null) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.tr(context, 'Body'),
                style: LynType.caption.copyWith(
                  color: LynSurface.textSecondary(widget.isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                template.bodyText!,
                style: LynType.callout.copyWith(
                  color: LynSurface.textPrimary(widget.isDark),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            if (template.category != null) ...[
              const SizedBox(height: 12),
              Text(
                AppLocalizations.tr(context, 'Category'),
                style: LynType.caption.copyWith(
                  color: LynSurface.textSecondary(widget.isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                template.category!,
                style: LynType.callout.copyWith(
                  color: LynSurface.textPrimary(widget.isDark),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateConfigureScreen(AppStates state) {
    final template = _selectedTemplate!;
    final variables = template.variables;

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTemplateCard(template),
                  if (variables.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Template Parameters',
                      style: LynType.body.copyWith(
                        color: LynSurface.textPrimary(widget.isDark),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...variables.map((varName) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: _paramControllers[varName],
                          style: TextStyle(color: LynSurface.textPrimary(widget.isDark)),
                          decoration: InputDecoration(
                            labelText: 'Variable {{ $varName }}',
                            labelStyle: TextStyle(color: LynPalette.indigo),
                            filled: true,
                            fillColor: LynSurface.canvas(widget.isDark),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: LynSurface.border(widget.isDark)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _goBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    AppLocalizations.tr(context, 'Go Back'),
                    style: TextStyle(color: LynSurface.textPrimary(widget.isDark)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: state is AppSendWhatsAppTemplateLoadingState ? null : _sendTemplate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LynPalette.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state is AppSendWhatsAppTemplateLoadingState
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(AppLocalizations.tr(context, 'Send Message')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
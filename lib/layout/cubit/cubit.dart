

import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';  // ← أضف هذا السطر

import '../../models/chatwoot_models.dart';
import '../../shared/components/constants.dart';
import '../../shared/network/chatwoot_api_service.dart';
import '../../shared/network/firebase_config/firebase_helper.dart';
import '../../shared/network/local/cache_helper.dart';
import 'states.dart';


class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitialState());

  static AppCubit get(BuildContext context) => BlocProvider.of(context);

  final ChatwootApiService _apiService = ChatwootApiService();
  StreamSubscription<ChatwootMessage>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _pollingTimer;
  int _pollingIntervalSeconds = 10;
  DateTime? _lastMessageTime;

  // ─── Theme ───────────────────────────────────
  bool isDark = CacheHelper.getBool(key: CacheHelper.keyIsDark) ?? true;

  void changeTheme({bool? fromShared}) {
    if (fromShared != null) {
      isDark = fromShared;
    } else {
      isDark = !isDark;
      CacheHelper.saveData(key: CacheHelper.keyIsDark, value: isDark);
    }
    emit(AppChangeThemeState(isDark));
  }

  // ─── Data ────────────────────────────────────
  List<Map<String, dynamic>> messages = [];
  ChatwootContact? currentContact;
  bool isTyping = false;
  List<ChatwootConversation> conversations = [];
  ChatwootConversation? selectedConversation;
  bool isSending = false;
  List<ChatwootInbox> inboxes = [];
  ChatwootInbox? selectedInbox;

  // ─── Subscription Data ────────────────────────────────────
  ChatwootSubscription? currentSubscription;
  bool get isSubscribed => currentSubscription?.isActive ?? false;

  void init() {
    _apiService.init();
    // ✅ جلب الشروط صامتاً عند البدء
    _fetchTermsSilently();
  }



  // ─── Terms Cache ───────────────────────────────
  Map<String, String>? _cachedTerms;
  DateTime? _lastTermsFetch;
  String? _lastTermsLang; // ✅ NEW

  Map<String, String>? get cachedTerms => _cachedTerms;

  void clearTermsCache() {
    _cachedTerms = null;
    _lastTermsFetch = null;
    _lastTermsLang = null; // ✅ NEW
  }

  Future<void> fetchTerms({required String lang, bool forceRefresh = false}) async {
    // ✅ إذا تغيّرت اللغة، نمسح الكاش تلقائياً
    if (_lastTermsLang != null && _lastTermsLang != lang) {
      print('🌍 Language changed from $_lastTermsLang to $lang, clearing cache...');
      clearTermsCache();
    }

    // ✅ استخدام الكاش إذا كان متاحاً ولم يمر أكثر من ساعة
    if (!forceRefresh && _cachedTerms != null && _lastTermsFetch != null &&
        DateTime.now().difference(_lastTermsFetch!).inHours < 1) {
      emit(AppFetchTermsSuccessState(termsData: _cachedTerms!));
      return;
    }

    emit(AppFetchTermsLoadingState());

    try {
      final termsData = await _apiService.fetchTerms(lang: lang);
      _cachedTerms = termsData;
      _lastTermsFetch = DateTime.now();
      _lastTermsLang = lang;
      emit(AppFetchTermsSuccessState(termsData: termsData));
    } catch (error) {
      print('❌ Fetch Terms Error: $error');

      // ✅ NEW: إذا كان هناك كاش بلغة أخرى، نستخدمه كـ Fallback
      if (_cachedTerms != null && _cachedTerms!.isNotEmpty) {
        print('⚠️ Using cached terms (different language) as fallback');
        emit(AppFetchTermsSuccessState(
          termsData: _cachedTerms!,
          isOffline: true, // ✅ NEW: Flag للـ Offline
        ));
        return;
      }

      // ✅ NEW: رسالة خطأ ودية حسب نوع الخطأ
      final String friendlyError = _getFriendlyError(error);
      emit(AppFetchTermsErrorState(error: friendlyError));
    }
  }

  // ✅ NEW: دالة لتحويل الأخطاء التقنية لرسائل ودية
  String _getFriendlyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('no address associated')) {
      return 'no_internet_connection';
    }

    if (errorString.contains('timeout')) {
      return 'connection_timeout';
    }

    if (errorString.contains('404')) {
      return 'content_not_found';
    }

    if (errorString.contains('500')) {
      return 'server_error';
    }

    return 'unknown_error';
  }

  Future<void> _fetchTermsSilently() async {
    try {
      final locale = CacheHelper.getData(key: 'locale')?.toString() ?? 'en';
      final apiLang = locale == 'ar' ? 'ar' : 'eng';
      final termsData = await _apiService.fetchTerms(lang: apiLang);
      _cachedTerms = termsData;
      _lastTermsFetch = DateTime.now();
      print('✅ Terms pre-fetched successfully');
      print('✅ Privacy: ${termsData['privacy']?.substring(0, 50)}...');
    } catch (e) {
      print('⚠️ Silent terms fetch failed: $e');
    }
  }





  // ═══════════════════════════════════════════════════════════════
  // Create Contact & Start Chat (Public API)
  // ═══════════════════════════════════════════════════════════════
  Future<void> createContact({
    required String name,
    required String email,
    required String inboxIdentifier,
  }) async {
    emit(AppCreateContactLoadingState());

    try {
      await CacheHelper.saveData(key: CacheHelper.keyUserName, value: name);
      await CacheHelper.saveData(key: CacheHelper.keyUserEmail, value: email);

      final contact = await _apiService.createContact(
        inboxIdentifier: inboxIdentifier,
        name: name,
        email: email,
      );
      currentContact = contact;

      await _apiService.getOrCreateConversation();

      final msgs = await _apiService.getMessages();
      _updateMessages(msgs);

      _apiService.connectWebSocket();
      _listenToMessages();

      await CacheHelper.saveData(key: CacheHelper.keyIsLoggedIn, value: true);

      emit(AppCreateContactSuccessState());
    } catch (error) {
      print('❌ Create Contact Error: $error');
      emit(AppCreateContactErrorState(error: error.toString()));
    }
  }

  Future<void> loadExistingSession() async {
    emit(AppLoadSessionLoadingState());

    try {
      // ✅ التحقق من وجود auth_token
      final authToken = CacheHelper.getString(key: CacheHelper.keyAuthToken);
      final accountId = CacheHelper.getData(key: CacheHelper.keyAccountId);
      final userId = CacheHelper.getData(key: CacheHelper.keyUserId);
      final userEmail = CacheHelper.getString(key: CacheHelper.keyUserEmail);

      if (authToken == null || authToken.isEmpty) {
        print('❌ No auth token found - redirecting to login');
        emit(AppNoSessionState());
        return;
      }

      // ✅ تهيئة الـ API Service
      _apiService.init();
      await _apiService.loadAuthToken();

      // ✅ التحقق من صلاحية الـ token (اختياري)
      await _apiService.fetchUserProfile();

      // ✅ تحميل الاشتراك من الكاش أولاً
      await _loadSubscriptionFromCache();

      // ✅ ثم فحص الاشتراك من الـ API لتحديثه
      if (userEmail != null && userEmail.isNotEmpty) {
        await checkSubscription(email: userEmail);
      }

      // ✅ تهيئة FCM (أضيف حديثاً)
      await initializeFCM();

      print('✅ Session loaded successfully');
      print('✅ Auth token present');
      print('✅ Account ID: $accountId');
      print('✅ User ID: $userId');

      emit(AppLoadSessionSuccessState());
    } catch (error) {
      print('❌ Load Session Error: $error');
      // إذا فشل التحميل، نحذف البيانات القديمة ونطلب تسجيل دخول جديد
      await CacheHelper.removeData(key: CacheHelper.keyAuthToken);
      await CacheHelper.removeData(key: CacheHelper.keyAccountId);
      await CacheHelper.removeData(key: CacheHelper.keyUserId);
      emit(AppNoSessionState());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Listen to Incoming Messages (Public API)
  // ═══════════════════════════════════════════════════════════════
  void _listenToMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = _apiService.messageStream?.listen(
          (message) {
        final msgMap = _messageToMap(message);

        // ✅ 1. موجودة مسبقاً بنفس الـ id؟ تجاهلها (صدى مكرر)
        final idExists = messages.any(
              (m) => m['id'].toString() == msgMap['id'].toString(),
        );
        if (idExists) return;

        // ✅ 2. نسخة من رسالة مؤقتة (Optimistic)؟ استبدلها بدل الإضافة
        final tempIndex = messages.indexWhere((m) =>
        m['is_temp'] == true &&
            m['content'] == msgMap['content'] &&
            m['sender_type'] == msgMap['sender_type']);

        if (tempIndex != -1) {
          messages[tempIndex] = msgMap;
          emit(AppNewMessageReceivedState(message: msgMap));
          return;
        }

        // ✅ 3. مكررة بنفس المحتوى والمرسل خلال 10 ثوانٍ؟ تجاهلها (صدى WebSocket)
        final isRecentDuplicate = messages.any((m) {
          if (m['content'] != msgMap['content'] ||
              m['sender_type'] != msgMap['sender_type']) {
            return false;
          }
          final t1 = DateTime.tryParse(m['created_at']?.toString() ?? '');
          final t2 = DateTime.tryParse(msgMap['created_at']?.toString() ?? '');
          if (t1 == null || t2 == null) return true;
          return t2.difference(t1).inSeconds.abs() <= 10;
        });
        if (isRecentDuplicate) return;

        // ✅ 4. رسالة جديدة فعلاً
        messages.add(msgMap);
        emit(AppNewMessageReceivedState(message: msgMap));
      },
      onError: (error) {
        print('❌ Message Stream Error: $error');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Send Message (Public API)
  // ═══════════════════════════════════════════════════════════════
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) {
      emit(AppSendMessageErrorState(error: 'الرسالة فارغة'));
      return;
    }

    emit(AppSendMessageLoadingState());

    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempMessage = {
      'id': tempId,
      'content': content.trim(),
      'message_type': 'incoming',
      'sender_type': 'contact',
      'sender_name': CacheHelper.getString(key: CacheHelper.keyUserName) ?? 'أنت',
      'created_at': DateTime.now().toIso8601String(),
      'is_temp': true,
    };

    messages.add(tempMessage);
    emit(AppNewMessageReceivedState(message: tempMessage));

    try {
      final sentMessage = await _apiService.sendMessage(content: content.trim());
      final sentMap = _messageToMap(sentMessage);

      final index = messages.indexWhere((m) => m['id'] == tempId);
      if (index != -1) {
        messages[index] = sentMap;
        emit(AppNewMessageReceivedState(message: sentMap));
      } else {
        // ✅ المؤقتة استُبدلت مسبقاً من الـ WebSocket — نتأكد من عدم التكرار
        final already = messages.any(
              (m) => m['id'].toString() == sentMap['id'].toString(),
        );
        if (!already) {
          messages.add(sentMap);
          emit(AppNewMessageReceivedState(message: sentMap));
        }
      }

      emit(AppSendMessageSuccessState());
    } catch (error) {
      print('❌ Send Message Error: $error');
      try {
        await _apiService.sendMessageWebSocket(content: content.trim());
        emit(AppSendMessageSuccessState());
      } catch (wsError) {
        messages.removeWhere((m) => m['id'] == tempId);
        emit(AppSendMessageErrorState(error: 'فشل إرسال الرسالة'));
      }
    }
  }

  // ─── Helpers ─────────────────────────────────
  void _updateMessages(List<ChatwootMessage> msgs) {
    for (var msg in msgs) {
      final msgMap = _messageToMap(msg);
      final exists = messages.any((m) => m['id'] == msgMap['id']);
      if (!exists) {
        messages.add(msgMap);
      }
    }
    emit(AppMessagesLoadedState());
  }

  Map<String, dynamic> _messageToMap(ChatwootMessage msg) {
    // استخراج نوع الملف الحقيقي من المرفقات
    List<Map<String, dynamic>>? attachmentMaps;
    if (msg.attachments != null && msg.attachments!.isNotEmpty) {
      attachmentMaps = msg.attachments!.map((a) {
        final fileType = a.fileType?.toLowerCase() ?? '';
        final fileName = a.fileName ?? '';
        
        // استخراج الامتداد من file_name أو file_url
        String ext = '';
        if (fileName.isNotEmpty) {
          ext = fileName.split('.').last.toLowerCase();
        } else if (a.fileUrl != null) {
          ext = a.fileUrl!.split('.').last.toLowerCase();
          if (ext.contains('?')) {
            ext = ext.split('?').first;
          }
        }

        // ✅ تحديد النوع الحقيقي من الامتداد (لأن Chatwoot يعيد file_type عام)
        bool isImage = fileType.contains('image') ||
            ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
        bool isAudio = fileType.contains('audio') ||
            ['mp3', 'm4a', 'aac', 'ogg', 'wav', 'flac'].contains(ext);
        bool isVideo = fileType.contains('video') ||
            ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);

        print('📎 Attachment: ${a.fileName} | fileType: $fileType | ext: $ext | isImage: $isImage | isAudio: $isAudio | isVideo: $isVideo');

        return {
          'id': a.id,
          'file_name': a.fileName,
          'file_type': a.fileType,
          'file_url': a.fileUrl,
          'thumb_url': a.thumbUrl,
          'is_image': isImage,
          'is_audio': isAudio,
          'is_video': isVideo,
          'is_file': !isImage && !isAudio && !isVideo,
        };
      }).toList();
    }

    return {
      'id': msg.id,
      'content': msg.content ?? '',
      'message_type': msg.messageType ?? 'text',
      'sender_type': msg.senderType ?? 'contact',
      'sender_name': msg.senderName ?? 'فريق الدعم',
      'created_at': msg.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'conversation_id': msg.conversationId,
      'inbox_id': msg.inboxId,
      'content_type': msg.contentType ?? 'text',
      'attachments': attachmentMaps,
    };
  }



  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _stopPollingFallback();
    _apiService.disconnect();
    return super.close();
  }


  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AppLoginLoadingState());

    try {
      // ✅ 1. تسجيل الدخول
      await _apiService.login(email: email, password: password);
      await CacheHelper.saveData(key: CacheHelper.keyUserEmail, value: email);
      await CacheHelper.saveData(key: CacheHelper.keyIsLoggedIn, value: true);

      // ✅ 2. فحص الاشتراك
      emit(AppSubscriptionLoadingState());

      // محاكاة تأخير (احذف في الإنتاج)
      await Future.delayed(const Duration(seconds: 1));

      // ✅ تعيين الاشتراك
      currentSubscription = ChatwootSubscription(
        plan: 'basic',
        status: 'active',
        isActive: true,
      );

      // ✅ حفظ في الكاش
      await _saveSubscriptionToCache(currentSubscription!);

      // ✅ 3. تهيئة FCM (أضيف حديثاً)
      await initializeFCM();

      // ✅ 4. اكتمال كل شيء
      emit(AppAuthCompleteState());

    } catch (error) {
      print('❌ Login/Auth Error: $error');
      emit(AppLoginErrorState(error: error.toString()));
    }
  }


  Future<void> loginWithGoogle() async {
    emit(AppLoginLoadingState());

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        emit(AppLoginErrorState(error: 'تم إلغاء تسجيل الدخول'));
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // حفظ بيانات Google
        await CacheHelper.saveData(key: kGoogleUserId, value: user.uid);
        await CacheHelper.saveData(key: kGoogleUserEmail, value: user.email ?? '');
        await CacheHelper.saveData(key: kGoogleUserName, value: user.displayName ?? '');
        await CacheHelper.saveData(key: kGoogleIdToken, value: googleAuth.idToken ?? '');
        await CacheHelper.saveData(key: kGoogleAccessToken, value: googleAuth.accessToken ?? '');

        print('✅ Google Auth Success');

        // ✅ تسجيل في Backend
        await _apiService.registerWithGoogle(
          name: user.displayName ?? '',
          email: user.email ?? '',
          googleId: user.uid,
          platform: 'chatwoot',
        );

        print('✅ Backend Registration Success');

        // ✅ تهيئة FCM بعد تسجيل الدخول
        await initializeFCM();

        // حفظ حالة تسجيل الدخول
        await CacheHelper.saveData(key: CacheHelper.keyIsLoggedIn, value: true);
        await CacheHelper.saveData(key: CacheHelper.keyUserEmail, value: user.email ?? '');

        emit(AppAuthCompleteState());
      }
    } catch (error) {
      print('❌ Google Login Error: $error');
      emit(AppLoginErrorState(error: error.toString()));
    }
  }
  Future<void> checkSubscription({required String email, bool fromCache = false}) async {
    emit(AppSubscriptionLoadingState());

    try {
      // ✅ إذا طُلب تحميل من الكاش فقط (بدون API call)
      if (fromCache) {
        await _loadSubscriptionFromCache();
        return;
      }

      // ✅ فحص الاشتراك من الـ API
      final subscription = await _apiService.checkSubscription(email: email);

      if (subscription != null && subscription.isActive) {
        currentSubscription = subscription;
        // ✅ حفظ في الكاش
        await _saveSubscriptionToCache(subscription);
        emit(AppSubscriptionActiveState(
          plan: subscription.plan ?? 'unknown',
          endsAt: subscription.endsAt,
        ));
      } else {
        currentSubscription = null;
        await _clearSubscriptionCache();
        emit(AppSubscriptionInactiveState());
      }
    } catch (error) {
      print('❌ Check Subscription Error: $error');
      // ✅ في حالة الخطأ، حاول تحميل من الكاش
      await _loadSubscriptionFromCache();
    }
  }

  // ─── Save Subscription to Cache ─────────────────────────────
  Future<void> _saveSubscriptionToCache(ChatwootSubscription subscription) async {
    await CacheHelper.saveData(key: 'subscription_plan', value: subscription.plan ?? '');
    await CacheHelper.saveData(key: 'subscription_status', value: subscription.status ?? '');
    await CacheHelper.saveData(key: 'subscription_starts_at', value: subscription.startsAt ?? '');
    await CacheHelper.saveData(key: 'subscription_ends_at', value: subscription.endsAt ?? '');
    print('✅ Subscription saved to cache');
  }

  // ─── Load Subscription from Cache ─────────────────────────────
  Future<void> _loadSubscriptionFromCache() async {
    final plan = CacheHelper.getString(key: 'subscription_plan');
    final status = CacheHelper.getString(key: 'subscription_status');

    if (plan != null && plan.isNotEmpty && status?.toLowerCase() == 'active') {
      final subscription = ChatwootSubscription(
        plan: plan,
        status: status,
        startsAt: CacheHelper.getString(key: 'subscription_starts_at'),
        endsAt: CacheHelper.getString(key: 'subscription_ends_at'),
      );
      currentSubscription = subscription;
      emit(AppSubscriptionActiveState(
        plan: subscription.plan ?? 'unknown',
        endsAt: subscription.endsAt,
      ));
      print('✅ Subscription loaded from cache');
    } else {
      currentSubscription = null;
      emit(AppSubscriptionInactiveState());
      print('⚠️ No valid subscription in cache');
    }
  }

  // ─── Clear Subscription Cache ─────────────────────────────
  Future<void> _clearSubscriptionCache() async {
    await CacheHelper.removeData(key: 'subscription_plan');
    await CacheHelper.removeData(key: 'subscription_status');
    await CacheHelper.removeData(key: 'subscription_starts_at');
    await CacheHelper.removeData(key: 'subscription_ends_at');
  }

  Future<void> fetchInboxes({int? accountId}) async {
    emit(AppFetchInboxesLoadingState());

    try {
      await _apiService.loadAuthToken();
      inboxes = await _apiService.fetchInboxes(accountId: accountId);
      emit(AppFetchInboxesSuccessState());
    } catch (error) {
      print('❌ Fetch Inboxes Error: $error');
      emit(AppFetchInboxesErrorState(error: error.toString()));
    }
  }

  void selectInbox(ChatwootInbox inbox) {
    selectedInbox = inbox;
    CacheHelper.saveData(key: CacheHelper.keyInboxId, value: inbox.inboxIdentifier ?? '');
  }


  Future<void> fetchConversations({
    int? inboxId,
    String status = 'open',
  }) async {
    emit(AppFetchConversationsLoadingState());

    try {
      await _apiService.loadAuthToken();

      final accountIdData = CacheHelper.getData(key: 'account_id');
      final accountId = accountIdData != null ? int.tryParse(accountIdData.toString()) : 4;

      if (accountId == null) {
        throw Exception('Account ID not found');
      }

      conversations = await _apiService.fetchConversations(
        accountId: accountId,
        inboxId: inboxId ?? selectedInbox?.id,
        status: status,
      );

      emit(AppFetchConversationsSuccessState());
    } catch (error) {
      print('❌ Fetch Conversations Error: $error');
      emit(AppFetchConversationsErrorState(error: error.toString()));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Select Conversation - FIXED v2.0
  // ═══════════════════════════════════════════════════════════════
  Future<void> selectConversation(ChatwootConversation conversation) async {
    // ✅ 1. التصفير المحلي لعدد الرسائل غير المقروءة في الواجهة
    final updatedConv = conversation.copyWith(unreadCount: 0);
    selectedConversation = updatedConv;

    final index = conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      conversations[index] = updatedConv;
    }

    _lastMessageTime = null;

    emit(AppFetchConversationsLoadingState());

    try {
      await _apiService.loadAuthToken();

      final accountIdData = CacheHelper.getData(key: 'account_id');
      final accountId = accountIdData != null ? int.tryParse(accountIdData.toString()) : 4;

      if (accountId == null) {
        throw Exception('Account ID not found');
      }

      // ✅ 2. إرسال تحديث للقراءة إلى السيرفر (Chatwoot API)
      _apiService.updateLastSeen(
        accountId: accountId,
        conversationId: conversation.id,
      );

      // ✅ FIXED: جلب pubsub_token الصحيح من Profile API
      await _apiService.fetchUserProfile();

      // ✅ FIXED: إعادة تهيئة WebSocket قبل الاشتراك
      _apiService.disconnect();
      await Future.delayed(const Duration(milliseconds: 300));

      // ✅ FIXED: الاتصال بالـ WebSocket ثم الاشتراك
      _apiService.connectWebSocketAdmin(
        accountId: accountId,
        conversationId: conversation.id,
      );

      // ✅ FIXED: الاستماع للرسائل الجديدة
      _listenToWebSocketMessagesAdmin();

      // جلب الرسائل الأولية
      final msgs = await _apiService.fetchMessagesAdminApi(
        accountId: accountId,
        conversationId: conversation.id,
      );

      messages.clear();
      hasMoreMessages = true; // ✅ إعادة ضبط الـ Pagination للمحادثة الجديدة
      isLoadingMoreMessages = false;
      for (var msg in msgs) {
        final msgMap = _messageToMap(msg);
        messages.add(msgMap);
      }

      if (msgs.isNotEmpty) {
        _lastMessageTime = msgs.last.createdAt;
      }

      emit(AppFetchConversationsSuccessState());
      emit(AppMessagesLoadedState());
    } catch (error) {
      print('❌ Select Conversation Error: $error');
      emit(AppFetchConversationsErrorState(error: error.toString()));
    }
  }

  void _listenToWebSocketMessagesAdmin() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();

    // ✅ مراقبة حالة اتصال WebSocket بشكل آلي وإلغاء/تشغيل الـ Polling عند اللزوم
    _connectionSubscription = _apiService.connectionStatusStream.listen((isConnected) {
      if (isConnected) {
        print('🟢 WebSocket Connected: Stopping fallback polling & fetching delta');
        _stopPollingFallback();
        _fetchDeltaMessages();
      } else {
        print('🔴 WebSocket Disconnected: Starting smart adaptive fallback polling');
        _startPollingFallback();
      }
    });

    _messageSubscription = _apiService.messageStream?.listen(
      (message) {
        print('📥 Real-time message: ${message.content}');
        final msgMap = _messageToMap(message);

        // تجاهل الرسائل من محادثات أخرى
        if (selectedConversation != null &&
            message.conversationId != null &&
            message.conversationId != selectedConversation!.id) {
          return;
        }

        // ✅ فحص التكرار بالـ ID الحقيقي
        final existsById = messages.any(
            (m) => m['id'].toString() == msgMap['id'].toString());
        if (existsById) return;

        // ✅ فحص إذا كانت هناك رسالة مؤقتة (is_temp) بنفس المحتوى
        // ملاحظة: لا نقارن sender_type لأن المؤقتة 'agent' بينما صدى WS يصل 'User'
        final tempIndex = messages.indexWhere((m) =>
            m['is_temp'] == true &&
            m['content'] == msgMap['content']);

        if (tempIndex != -1) {
          // استبدال الرسالة المؤقتة بالحقيقية (بدون إضافة نسخة جديدة)
          messages[tempIndex] = msgMap;
          emit(AppNewMessageReceivedState(message: msgMap));
        } else {
          // ✅ حماية إضافية: تجاهل صدى مكرر بنفس المحتوى خلال 15 ثانية
          // (فقط للرسائل النصية — رسائل المرفقات محتواها فارغ وقد تتشابه خطأً)
          final content = msgMap['content']?.toString() ?? '';
          final isRecentEcho = content.isNotEmpty && messages.any((m) {
            if (m['content'] != msgMap['content']) return false;
            final t1 = DateTime.tryParse(m['created_at']?.toString() ?? '');
            final t2 = DateTime.tryParse(msgMap['created_at']?.toString() ?? '');
            if (t1 == null || t2 == null) return false;
            return t2.difference(t1).inSeconds.abs() <= 15;
          });
          if (isRecentEcho) return;

          // رسالة جديدة فعلاً (من الطرف الآخر)
          messages.add(msgMap);
          _lastMessageTime = DateTime.now();
          emit(AppNewMessageReceivedState(message: msgMap));
        }
      },
      onError: (error) {
        print('❌ WS Error: $error');
        _startPollingFallback();
      },
      onDone: () {
        print('🔌 WS Closed, starting polling fallback...');
        _startPollingFallback();
      },
    );

    if (_apiService.isConnected) {
      _stopPollingFallback();
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        if (!_apiService.isConnected) {
          print('⚠️ WebSocket not connected yet, starting adaptive polling fallback...');
          _startPollingFallback();
        }
      });
    }
  }

  void _startPollingFallback() {
    if (_apiService.isConnected) {
      _stopPollingFallback();
      return;
    }
    if (_pollingTimer != null && _pollingTimer!.isActive) return;

    _pollingIntervalSeconds = 10; // بدءاً بـ 10 ثوانٍ لحفظ البطارية وخادم الشبكة
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollingIntervalSeconds),
      (_) => _pollForNewMessages(),
    );
    print('⏰ Smart Adaptive Polling fallback started (every ${_pollingIntervalSeconds}s)');
  }

  void _stopPollingFallback() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _pollingIntervalSeconds = 10;
    print('⏰ Smart Adaptive Polling fallback stopped');
  }

  void _increasePollingBackoff() {
    if (_pollingIntervalSeconds < 30) {
      _pollingIntervalSeconds = (_pollingIntervalSeconds + 5).clamp(10, 30);
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(
        Duration(seconds: _pollingIntervalSeconds),
        (_) => _pollForNewMessages(),
      );
      print('⏰ Adaptive Polling backoff increased to ${_pollingIntervalSeconds}s');
    }
  }

  void _resetPollingInterval() {
    if (_pollingIntervalSeconds != 10) {
      _pollingIntervalSeconds = 10;
      if (_pollingTimer != null) {
        _pollingTimer?.cancel();
        _pollingTimer = Timer.periodic(
          Duration(seconds: _pollingIntervalSeconds),
          (_) => _pollForNewMessages(),
        );
      }
    }
  }

  Future<void> _fetchDeltaMessages() async {
    if (selectedConversation == null) return;
    try {
      final accountIdData = CacheHelper.getData(key: 'account_id');
      final accountId = accountIdData != null ? int.tryParse(accountIdData.toString()) : 4;
      if (accountId == null) return;

      int? lastId;
      if (messages.isNotEmpty) {
        for (int i = messages.length - 1; i >= 0; i--) {
          final id = messages[i]['id'];
          if (id != null) {
            final parsed = int.tryParse(id.toString());
            if (parsed != null) {
              lastId = parsed;
              break;
            }
          }
        }
      }

      final newMsgs = await _apiService.fetchMessagesAdminApi(
        accountId: accountId,
        conversationId: selectedConversation!.id,
        afterId: lastId,
      );

      if (newMsgs.isNotEmpty) {
        print('🔄 Delta sync: ${newMsgs.length} new messages fetched after WS reconnect');
        for (var msg in newMsgs) {
          final msgMap = _messageToMap(msg);
          final exists = messages.any((m) => m['id'] == msgMap['id']);
          if (!exists) {
            messages.add(msgMap);
            emit(AppNewMessageReceivedState(message: msgMap));
          }
        }
      }
    } catch (e) {
      print('❌ Delta sync error: $e');
    }
  }

  Future<void> _pollForNewMessages() async {
    if (selectedConversation == null) return;

    if (_apiService.isConnected) {
      _stopPollingFallback();
      return;
    }

    try {
      await _apiService.loadAuthToken();
      final accountIdData = CacheHelper.getData(key: 'account_id');
      final accountId = accountIdData != null ? int.tryParse(accountIdData.toString()) : 4;
      if (accountId == null) return;

      int? lastId;
      if (messages.isNotEmpty) {
        for (int i = messages.length - 1; i >= 0; i--) {
          final id = messages[i]['id'];
          if (id != null) {
            final parsed = int.tryParse(id.toString());
            if (parsed != null) {
              lastId = parsed;
              break;
            }
          }
        }
      }

      // Delta fetch: request ONLY messages after lastId to minimize server load & bandwidth
      final newMsgs = await _apiService.fetchMessagesAdminApi(
        accountId: accountId,
        conversationId: selectedConversation!.id,
        afterId: lastId,
      );

      if (newMsgs.isNotEmpty) {
        print('📥 Smart Polling found ${newMsgs.length} new messages');
        bool addedAny = false;
        for (var msg in newMsgs) {
          final msgMap = _messageToMap(msg);
          final exists = messages.any((m) => m['id'] == msgMap['id']);
          if (!exists) {
            messages.add(msgMap);
            addedAny = true;
            emit(AppNewMessageReceivedState(message: msgMap));
          }
        }
        if (addedAny) {
          _lastMessageTime = DateTime.now();
          _resetPollingInterval();
        }
      } else {
        // No new messages - gently backoff to 15s..20s..30s to conserve battery
        _increasePollingBackoff();
      }
    } catch (e) {
      print('❌ Polling Error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Send Message via Admin API
  // ═══════════════════════════════════════════════════════════════
  Future<void> sendMessageAdminApi(String content) async {
    if (content.trim().isEmpty) {
      emit(AppSendMessageErrorState(error: 'الرسالة فارغة'));
      return;
    }

    if (selectedConversation == null) {
      emit(AppSendMessageErrorState(error: 'لم يتم اختيار محادثة'));
      return;
    }

    emit(AppSendMessageLoadingState());
    isSending = true;

    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempMessage = {
      'id': tempId,
      'content': content.trim(),
      'message_type': 'outgoing',
      'sender_type': 'agent',
      'sender_name': 'أنت',
      'created_at': DateTime.now().toIso8601String(),
      'is_temp': true,
    };

    messages.add(tempMessage);
    emit(AppNewMessageReceivedState(message: tempMessage));

    try {
      await _apiService.loadAuthToken();

      final accountIdData = CacheHelper.getData(key: 'account_id');
      final accountId = accountIdData != null ? int.tryParse(accountIdData.toString()) : 4;

      if (accountId == null) {
        throw Exception('Account ID not found');
      }

      final sentMessage = await _apiService.sendMessageAdminApi(
        accountId: accountId,
        conversationId: selectedConversation!.id,
        content: content.trim(),
        messageType: 'outgoing',
      );

      final sentMap = _messageToMap(sentMessage);

      // ✅ استبدال الرسالة المؤقتة بالحقيقية (إذا لم يستبدلها WebSocket بالفعل)
      final index = messages.indexWhere((m) => m['id'] == tempId);
      if (index != -1) {
        messages[index] = sentMap;
      } else {
        // ✅ إذا WebSocket استبدلها سابقاً، نتأكد من عدم إضافة نسخة جديدة
        final alreadyExists = messages.any(
            (m) => m['id'].toString() == sentMap['id'].toString());
        if (!alreadyExists) {
          messages.add(sentMap);
        }
      }

      isSending = false;
      emit(AppSendMessageSuccessState());
    } catch (error) {
      print('❌ Send Message Error: $error');
      messages.removeWhere((m) => m['id'] == tempId);
      isSending = false;
      emit(AppSendMessageErrorState(error: 'فشل إرسال الرسالة: $error'));
    }
  }

  Future<void> logout() async {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _stopPollingFallback();
    _apiService.disconnect();
    _apiService.clearAuth();
    currentContact = null;
    messages = [];
    inboxes = [];
    selectedInbox = null;
    conversations = [];
    selectedConversation = null;
    _lastMessageTime = null;
    currentSubscription = null;

    // ✅ حذف FCM Token من Backend
    try {
      final fcmToken = CacheHelper.getString(key: 'fcm_token');
      if (fcmToken != null) {
        // TODO: استدعاء API لحذف FCM Token
        // print('🗑️ FCM Token removed from backend');
      }
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }

    // ✅ تسجيل الخروج من Google (مرة واحدة فقط)
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    // ✅ مسح الكاش (مرة واحدة فقط)
    await CacheHelper.clear();

    emit(AppLogoutState());
  }

  bool hasMoreMessages = true;
  bool isLoadingMoreMessages = false;

  Future<int> loadMoreMessages(int accountId, int conversationId) async {
    if (isLoadingMoreMessages || !hasMoreMessages) return 0;
    isLoadingMoreMessages = true;
    try {
      await _apiService.loadAuthToken();

      int? oldestId;
      for (final m in messages) {
        if (m['is_temp'] == true) continue;
        final parsed = int.tryParse(m['id'].toString());
        if (parsed != null && (oldestId == null || parsed < oldestId)) {
          oldestId = parsed;
        }
      }

      if (oldestId == null) {
        isLoadingMoreMessages = false;
        return 0;
      }

      final olderMessages = await _apiService.fetchMessagesAdminApi(
        accountId: accountId,
        conversationId: conversationId,
        beforeId: oldestId,
      );

      if (olderMessages.isEmpty) {
        hasMoreMessages = false;
        isLoadingMoreMessages = false;
        emit(AppMoreMessagesLoadedState(addedCount: 0));
        return 0;
      }

      int addedCount = 0;
      final toInsert = <Map<String, dynamic>>[];
      for (var msg in olderMessages) {
        final msgMap = _messageToMap(msg);
        final exists = messages.any(
            (m) => m['id'].toString() == msgMap['id'].toString());
        if (!exists) {
          toInsert.add(msgMap);
          addedCount++;
        }
      }
      messages.insertAll(0, toInsert);

      if (olderMessages.length < 20) {
        hasMoreMessages = false;
      }

      isLoadingMoreMessages = false;
      emit(AppMoreMessagesLoadedState(addedCount: addedCount));
      return addedCount;
    } catch (error) {
      print('❌ Load More Messages Error: $error');
      isLoadingMoreMessages = false;
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════
// Delete Message (Admin API)
// ═══════════════════════════════════════════════════════════════
  Future<void> deleteMessage(dynamic messageId) async {
    if (messageId == null) {
      throw Exception('معرف الرسالة غير موجود');
    }

    try {
      await _apiService.loadAuthToken();

      final accountIdData = CacheHelper.getData(key: 'account_id');
      final accountId = accountIdData != null
          ? int.tryParse(accountIdData.toString())
          : 4;

      if (accountId == null) {
        throw Exception('Account ID not found');
      }

      if (selectedConversation == null) {
        throw Exception('لم يتم اختيار محادثة');
      }

      await _apiService.deleteMessageAdminApi(
        accountId: accountId,
        conversationId: selectedConversation!.id,
        messageId: messageId,
      );

      // ✅ حذف من القائمة المحلية
      messages.removeWhere((m) => m['id'] == messageId);
      emit(AppMessagesLoadedState());

      print('✅ Message $messageId deleted successfully');
    } catch (error) {
      print('❌ Delete Message Error: $error');
      throw Exception('فشل حذف الرسالة: $error');
    }
  }




  Future<void> initializeFCM() async {
    // 1. الحصول على FCM Token
    final fcmToken = await FirebaseHelper.getFCMToken();

    if (fcmToken != null) {
      // 2. إرسال للـ Backend
      await _registerFcmTokenWithBackend(fcmToken);

      // 3. الاستماع لتغيير التوكن
      FirebaseHelper.listenToTokenRefresh((newToken) async {
        await _registerFcmTokenWithBackend(newToken);
      });

      emit(AppFcmTokenLoadedState(fcmToken: fcmToken));
    } else {
      emit(AppFcmTokenErrorState(error: 'Failed to get FCM token'));
    }
  }
  Future<void> _registerFcmTokenWithBackend(String fcmToken) async {
    try {
      final deviceInfo = await _apiService.getDeviceInfo();

      await _apiService.registerFcmToken(
        fcmToken: fcmToken,
        deviceId: deviceInfo['deviceId']!,
        devicePlatform: deviceInfo['platform']!,
      );

      print('✅ FCM Token registered with backend');
    } catch (e) {
      print('❌ Failed to register FCM token: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
// Contact Details & Update
// ═══════════════════════════════════════════════════════════════

  Map<String, dynamic>? _currentContactDetails;
  Map<String, dynamic>? get currentContactDetails => _currentContactDetails;

// ─── Fetch Contact Details ────────────────────────────
  Future<void> fetchContactDetails(int contactId) async {
    emit(AppFetchContactDetailsLoadingState());

    try {
      await _apiService.loadAuthToken();

      final accountIdData = CacheHelper.getData(key: CacheHelper.keyAccountId);
      final accountId = accountIdData != null
          ? int.tryParse(accountIdData.toString())
          : 4;

      if (accountId == null) {
        throw Exception('Account ID not found');
      }

      final details = await _apiService.fetchContactDetails(
        accountId: accountId,
        contactId: contactId,
      );

      _currentContactDetails = details;

      // ✅ تحديث المحادثة المحددة بالبيانات الجديدة
      if (selectedConversation != null) {
        selectedConversation = ChatwootConversation(
          id: selectedConversation!.id,
          inboxId: selectedConversation!.inboxId,
          contactId: contactId,
          status: selectedConversation!.status,
          messagesCount: selectedConversation!.messagesCount,
          unreadCount: selectedConversation!.unreadCount,
          lastMessageContent: selectedConversation!.lastMessageContent,
          lastMessageAt: selectedConversation!.lastMessageAt,
          contactName: details['name']?.toString() ?? selectedConversation!.contactName,
          contactAvatar: details['thumbnail']?.toString() ?? selectedConversation!.contactAvatar,
          contactEmail: details['email']?.toString(),
          contactPhone: details['phone_number']?.toString(),
          accountId: selectedConversation!.accountId,
          channelType: selectedConversation!.channelType,
        );
      }

      emit(AppFetchContactDetailsSuccessState(details: details));
    } catch (error) {
      print('❌ Fetch Contact Details Error: $error');
      emit(AppFetchContactDetailsErrorState(error: error.toString()));
    }
  }

// ─── Update Contact Name ────────────────────────────
  Future<void> updateContactName(int contactId, String newName) async {
    emit(AppUpdateContactLoadingState());

    try {
      await _apiService.loadAuthToken();

      final accountIdData = CacheHelper.getData(key: CacheHelper.keyAccountId);
      final accountId = accountIdData != null
          ? int.tryParse(accountIdData.toString())
          : 4;

      if (accountId == null) {
        throw Exception('Account ID not found');
      }

      final updated = await _apiService.updateContactName(
        accountId: accountId,
        contactId: contactId,
        newName: newName,
      );

      // ✅ تحديث البيانات المحلية
      _currentContactDetails = updated;

      if (selectedConversation != null) {
        selectedConversation = ChatwootConversation(
          id: selectedConversation!.id,
          inboxId: selectedConversation!.inboxId,
          contactId: contactId,
          status: selectedConversation!.status,
          messagesCount: selectedConversation!.messagesCount,
          unreadCount: selectedConversation!.unreadCount,
          lastMessageContent: selectedConversation!.lastMessageContent,
          lastMessageAt: selectedConversation!.lastMessageAt,
          contactName: newName,
          contactAvatar: selectedConversation!.contactAvatar,
          contactEmail: selectedConversation!.contactEmail,
          contactPhone: selectedConversation!.contactPhone,
          accountId: selectedConversation!.accountId,
          channelType: selectedConversation!.channelType,
        );
      }

      emit(AppUpdateContactSuccessState(details: updated));
    } catch (error) {
      print('❌ Update Contact Error: $error');
      emit(AppUpdateContactErrorState(error: error.toString()));
    }
  }

  // ═══════════════════════════════════════════════════════════════
// Send Message with Attachment (Admin API) - NEW
// ═══════════════════════════════════════════════════════════════
  Future<void> sendMessageWithAttachment(File file, {String? content}) async {
    if (selectedConversation == null) {
      emit(AppSendMessageErrorState(error: 'لم يتم اختيار محادثة'));
      return;
    }

    emit(AppSendMessageLoadingState());
    isSending = true;

    try {
      await _apiService.loadAuthToken();

      final accountIdData = CacheHelper.getData(key: 'account_id');
      final accountId = accountIdData != null
          ? int.tryParse(accountIdData.toString())
          : 4;

      if (accountId == null) {
        throw Exception('Account ID not found');
      }

      final sentMessage = await _apiService.sendMessageWithAttachment(
        accountId: accountId,
        conversationId: selectedConversation!.id,
        content: content,
        file: file,
        messageType: 'outgoing',
      );

      final sentMap = _messageToMap(sentMessage);

      // ✅ فحص التكرار: قد يكون صدى الـ WebSocket أضافها قبل وصول رد الـ API
      // (رفع الملفات أبطأ من النص، فيسبقه الـ WS غالباً)
      final alreadyExists = messages.any(
          (m) => m['id'].toString() == sentMap['id'].toString());
      if (!alreadyExists) {
        messages.add(sentMap);
        emit(AppNewMessageReceivedState(message: sentMap));
      }

      isSending = false;
      emit(AppSendMessageSuccessState());
    } catch (error) {
      print('❌ Send Attachment Error: $error');
      isSending = false;
      emit(AppSendMessageErrorState(error: 'فشل إرسال الملف: $error'));
    }
  }


// ─── Login with Apple ────────────────────────
  Future<void> loginWithApple() async {
    emit(AppLoginLoadingState());

    try {
      // ✅ التحقق من توفر Apple Sign-In
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        emit(AppLoginErrorState(
            error: 'تسجيل الدخول بـ Apple غير متاح على هذا الجهاز'
        ));
        return;
      }

      // ✅ 1. طلب بيانات Apple
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // ⚠️ WebAuthenticationOptions مطلوب فقط على Android
        webAuthenticationOptions: Platform.isAndroid
            ? WebAuthenticationOptions(
          clientId: 'com.yourcompany.app-service', // ← Service ID من زميلك
          redirectUri: Uri.parse(
            'https://your-backend.com/callbacks/sign_in_with_apple', // ← من زميلك
          ),
        )
            : null, // ← iOS لا يحتاجه
      );

      print('🍎 Apple Credential:');
      print('   userIdentifier: [redacted]');
      print('   email: [redacted]');
      print('   givenName: [redacted]');
      print('   familyName: [redacted]');
      print('   identityToken: [redacted]');

      // ✅ 2. التحقق من البيانات
      if (credential.userIdentifier == null) {
        emit(AppLoginErrorState(error: 'فشل الحصول على معرف المستخدم'));
        return;
      }

      // ✅ 3. تسجيل في Backend
      await _apiService.registerWithApple(
        userIdentifier: credential.userIdentifier!,
        email: credential.email ?? '',
        givenName: credential.givenName,
        familyName: credential.familyName,
        identityToken: credential.identityToken ?? '',
        platform: 'social',
      );

      // ✅ 4. حفظ بيانات Apple
      await CacheHelper.saveData(
        key: 'apple_user_identifier',
        value: credential.userIdentifier!,
      );

      // ✅ 5. تهيئة FCM
      await initializeFCM();

      // ✅ 6. حفظ حالة تسجيل الدخول
      await CacheHelper.saveData(key: CacheHelper.keyIsLoggedIn, value: true);

      print('✅ Apple Login Complete');
      emit(AppAuthCompleteState());

    } catch (error) {
      print('❌ Apple Login Error: $error');

      String errorMessage = error.toString();
      if (errorMessage.contains('canceled') || errorMessage.contains('AuthorizationErrorCode.canceled')) {
        errorMessage = 'تم إلغاء تسجيل الدخول';
      } else if (errorMessage.contains('not_available') || errorMessage.contains('notAvailable')) {
        errorMessage = 'تسجيل الدخول بـ Apple غير متاح على هذا الجهاز';
      } else if (errorMessage.contains('configure')) {
        errorMessage = 'يجب إعداد Apple Developer أولاً';
      }

      emit(AppLoginErrorState(error: errorMessage));
    }
  }

  // ═══════════════════════════════════════════════════════════════
// CREATE NEW CONVERSATION & SEND FIRST MESSAGE (Admin API)
// ═══════════════════════════════════════════════════════════════
  Future<void> createNewConversation({
    required int inboxId,
    String? contactName,
    required String contactEmail,
    String? contactPhone,
    required String initialMessage,
  }) async {
    emit(AppCreateConversationLoadingState());

    try {
      await _apiService.loadAuthToken();

      final accountIdData = CacheHelper.getData(key: CacheHelper.keyAccountId);
      final accountId = accountIdData != null
          ? int.tryParse(accountIdData.toString())
          : 4;

      if (accountId == null) {
        throw Exception('Account ID not found');
      }

      final effectiveName = (contactName == null || contactName.trim().isEmpty)
          ? _extractNameFromEmail(contactEmail)
          : contactName.trim();

      int? contactId;
      String? sourceId;

      print('🔍 Searching for contact: $contactEmail');
      final existingContacts = await _apiService.searchContactsAdminApi(
        accountId: accountId,
        query: contactEmail,
      );

      if (existingContacts.isNotEmpty) {
        // ✅ Contact موجود
        final contact = existingContacts.first;
        contactId = contact['id'] is int ? contact['id'] : int.tryParse(contact['id'].toString());
        final contactInboxes = contact['contact_inboxes'] as List<dynamic>?;
        if (contactInboxes != null && contactInboxes.isNotEmpty) {
          sourceId = contactInboxes.first['source_id']?.toString();
        }
        print('✅ Found existing contact: $contactId');
      } else {
        // ✅ إنشاء Contact جديد
        print('🆕 Creating new contact...');
        final newContact = await _apiService.createContactAdminApi(
          accountId: accountId,
          inboxId: inboxId,
          name: effectiveName,
          email: contactEmail,
          phoneNumber: contactPhone,
          identifier: contactEmail,
        );

        // ✅ FIX: استخراج id بشكل آمن مع fallback
        final rawId = newContact['id'];
        contactId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

        // ✅ FIX: استخراج source_id من contact_inboxes
        final contactInboxes = newContact['contact_inboxes'] as List<dynamic>?;
        if (contactInboxes != null && contactInboxes.isNotEmpty) {
          sourceId = contactInboxes.first['source_id']?.toString();
          print('✅ Source ID from contact_inboxes: $sourceId');
        }

        // ✅ FIX: fallback - استخدام identifier كـ source_id
        if (sourceId == null || sourceId.isEmpty) {
          sourceId = contactEmail;
          print('✅ Using email as fallback source_id: $sourceId');
        }

        print('✅ New contact created: $contactId | Source: $sourceId');
      }

      if (contactId == null) {
        throw Exception('فشل الحصول على معرف جهة الاتصال');
      }

      // ✅ 3. إنشاء المحادثة
      print('💬 Creating conversation...');
      final conversation = await _apiService.createConversationAdminApi(
        accountId: accountId,
        inboxId: inboxId,
        contactId: contactId,
        sourceId: sourceId,
        status: 'open',
        initialMessage: initialMessage,
      );

      conversations.insert(0, conversation);
      selectedConversation = conversation;

      emit(AppCreateConversationSuccessState(conversation: conversation));
      await selectConversation(conversation);

    } catch (error) {
      print('❌ Create New Conversation Error: $error');
      emit(AppCreateConversationErrorState(error: error.toString()));
    }
  }

  String _extractNameFromEmail(String email) {
    if (!email.contains('@')) return 'Unknown';

    final localPart = email.split('@').first;

    // تنظيف وتحويل لاسم مقروء
    return localPart
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
        : '')
        .join(' ')
        .trim();
  }

  // ═══════════════════════════════════════════════════════════════
// Mark Conversation as Read - NEW
// ═══════════════════════════════════════════════════════════════
  Future<void> markConversationAsRead(int conversationId) async {
    try {
      await _apiService.loadAuthToken();
      final accountId = CacheHelper.getData(key: 'account_id') ?? 4;

      // ✅ استدعاء API لتحديث read status في Chatwoot
      // Chatwoot لا يوفر API مباشر لـ "mark as read"، لكن يمكن:
      // 1. تحديث محلياً فوراً
      // 2. الاعتماد على WebSocket event لاحقاً

      final index = conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        // ✅ تحديث المحادثة محلياً - تصفير unreadCount
        final updatedConversation = ChatwootConversation(
          id: conversations[index].id,
          inboxId: conversations[index].inboxId,
          contactId: conversations[index].contactId,
          status: conversations[index].status,
          messagesCount: conversations[index].messagesCount,
          unreadCount: 0, // ← تصفير!
          lastMessageContent: conversations[index].lastMessageContent,
          lastMessageAt: conversations[index].lastMessageAt,
          contactName: conversations[index].contactName,
          contactAvatar: conversations[index].contactAvatar,
          contactEmail: conversations[index].contactEmail,
          contactPhone: conversations[index].contactPhone,
          accountId: conversations[index].accountId,
          channelType: conversations[index].channelType,
        );

        conversations[index] = updatedConversation;
        emit(AppFetchConversationsSuccessState()); // إعادة بناء الـ UI
        print('✅ Conversation $conversationId marked as read locally');
      }
    } catch (e) {
      print('❌ Mark as read error: $e');
    }
  }




}

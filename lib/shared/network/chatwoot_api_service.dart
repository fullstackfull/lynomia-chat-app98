//
//
// import 'dart:async';
// import 'dart:convert';
//
// import 'package:dio/dio.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
//
// import '../../models/chatwoot_models.dart';
// import 'local/cache_helper.dart';
//
//
// class ChatwootApiService {
//   static final ChatwootApiService _instance = ChatwootApiService._internal();
//   factory ChatwootApiService() => _instance;
//   ChatwootApiService._internal();
//
//   late Dio _dio;
//   WebSocketChannel? _webSocket;
//   StreamController<ChatwootMessage>? _messageStreamController;
//
//   ChatwootContact? currentContact;
//   int? currentConversationId;
//
//   final String _baseUrl = 'https://chat.lynomia.com';
//   final String _wsUrl = 'wss://chat.lynomia.com'; // ✅ wss بدلاً من https
//
//   String? get _inboxIdentifier =>
//       CacheHelper.getString(key: CacheHelper.keyInboxId);
//
//   // ─── Initialize ──────────────────────────────
//   void init() {
//     _dio = Dio(BaseOptions(
//       baseUrl: _baseUrl,
//       // connectTimeout: const Duration(seconds: 30),
//       // receiveTimeout: const Duration(seconds: 30),
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       },
//       validateStatus: (status) => true,
//     ));
//
//     _messageStreamController = StreamController<ChatwootMessage>.broadcast();
//   }
//
//   // ─── Create Contact ──────────────────────────
//   Future<ChatwootContact> createContact({
//     required String inboxIdentifier,
//     required String name,
//     required String email,
//   }) async {
//     try {
//       final url = '/public/api/v1/inboxes/$inboxIdentifier/contacts';
//       print('POST: $_baseUrl$url');
//
//       final response = await _dio.post(
//         url,
//         data: {'name': name, 'email': email},
//       );
//
//       print('Status: ${response.statusCode}');
//       print('Response: ${response.data}');
//
//       if (response.statusCode == 404) {
//         throw Exception('Inbox not found: $inboxIdentifier');
//       }
//
//       if (response.statusCode != 200 && response.statusCode != 201) {
//         throw Exception('Error ${response.statusCode}: ${response.data}');
//       }
//
//       final contact = ChatwootContact.fromJson(response.data);
//       currentContact = contact;
//
//       await CacheHelper.saveData(
//           key: CacheHelper.keyContactId, value: contact.id.toString());
//       await CacheHelper.saveData(
//           key: CacheHelper.keyContactToken,
//           value: contact.pubsubToken ?? '');
//       await CacheHelper.saveData(
//           key: CacheHelper.keyInboxId, value: inboxIdentifier);
//
//       return contact;
//     } catch (e) {
//       print('Create Contact Error: $e');
//       throw Exception('Failed to create contact: $e');
//     }
//   }
//
//   // ─── Get or Create Conversation ──────────────
//   Future<int> getOrCreateConversation() async {
//     if (currentContact == null) {
//       throw Exception('No contact available');
//     }
//
//     try {
//       final inboxId = _inboxIdentifier;
//       if (inboxId == null) throw Exception('Inbox ID not found');
//
//       // ✅ محاولة جلب المحادثات الموجودة
//       final url = '/public/api/v1/inboxes/$inboxId/contacts/${currentContact!.id}/conversations';
//       print('GET: $_baseUrl$url');
//
//       final response = await _dio.get(url);
//       print('Get Conv Status: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         final payload = response.data['payload'] ?? response.data ?? [];
//         if (payload is List && payload.isNotEmpty) {
//           final convId = payload.first['id'];
//           if (convId != null) {
//             currentConversationId = convId;
//             print('Found conversation: $convId');
//             return convId;
//           }
//         }
//       }
//
//       // ✅ إذا ما لقينا، ننشئ محادثة جديدة
//       print('No conversation found, creating new one...');
//
//       // ✅ محاولة إنشاء محادثة
//       try {
//         final createUrl = '/public/api/v1/inboxes/$inboxId/conversations';
//         print('POST: $_baseUrl$createUrl');
//
//         final createResponse = await _dio.post(
//           createUrl,
//           data: {
//             'contact_id': currentContact!.id,
//             'status': 'open',
//           },
//         );
//
//         print('Create Conv Status: ${createResponse.statusCode}');
//
//         if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
//           final convId = createResponse.data['id'] ?? createResponse.data['payload']?['id'];
//           if (convId != null) {
//             currentConversationId = convId;
//             return convId;
//           }
//         }
//       } catch (e) {
//         print('Create conversation failed: $e');
//       }
//
//       // ✅ إذا فشل كل شيء، نستخدم source_id كـ conversation_id
//       print('Using contact ID as conversation ID');
//       currentConversationId = currentContact!.id;
//       return currentContact!.id;
//
//     } catch (e) {
//       print('Get/Create Conversation Error: $e');
//       // ✅ fallback
//       currentConversationId = currentContact!.id;
//       return currentContact!.id;
//     }
//   }
//
//   // ─── Send Message ────────────────────────────
//   Future<ChatwootMessage> sendMessage({required String content}) async {
//     if (currentContact == null) throw Exception('No contact');
//
//     final inboxId = _inboxIdentifier;
//     if (inboxId == null) throw Exception('Inbox ID not found');
//
//     try {
//       // ✅ التأكد من وجود conversation
//       if (currentConversationId == null) {
//         await getOrCreateConversation();
//       }
//
//       final contactId = currentContact!.id;
//       final convId = currentConversationId!;
//
//       // ✅ محاولة 1: إرسال مباشرة
//       final msgUrl = '/public/api/v1/inboxes/$inboxId/contacts/$contactId/conversations/$convId/messages';
//       print('POST message: $_baseUrl$msgUrl');
//
//       final response = await _dio.post(
//         msgUrl,
//         data: {
//           'content': content,
//           'message_type': 'incoming',
//           'private': false,
//         },
//       );
//
//       print('Send Status: ${response.statusCode}');
//       print('Send Response: ${response.data}');
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return ChatwootMessage.fromJson(response.data);
//       }
//
//       // ✅ محاولة 2: إذا فشلت، نجرب endpoint مختلف
//       if (response.statusCode == 404) {
//         print('Trying alternative endpoint...');
//
//         final altUrl = '/api/v1/accounts/1/conversations/$convId/messages';
//         print('POST alt: $_baseUrl$altUrl');
//
//         final altResponse = await _dio.post(
//           altUrl,
//           data: {
//             'content': content,
//             'message_type': 'incoming',
//             'private': false,
//             'sender_type': 'Contact',
//           },
//         );
//
//         print('Alt Status: ${altResponse.statusCode}');
//
//         if (altResponse.statusCode == 200 || altResponse.statusCode == 201) {
//           return ChatwootMessage.fromJson(altResponse.data);
//         }
//       }
//
//       throw Exception('Failed to send: ${response.statusCode}');
//
//     } catch (e) {
//       print('Send Message Error: $e');
//       throw Exception('Failed to send message: $e');
//     }
//   }
//
//   // ─── Get Messages ────────────────────────────
//   Future<List<ChatwootMessage>> getMessages() async {
//     if (currentContact == null) throw Exception('No contact');
//
//     final inboxId = _inboxIdentifier;
//     if (inboxId == null) throw Exception('Inbox ID not found');
//
//     try {
//       final contactId = currentContact!.id;
//
//       // ✅ جلب المحادثات أولاً
//       final convUrl = '/public/api/v1/inboxes/$inboxId/contacts/$contactId/conversations';
//       print('GET conv: $_baseUrl$convUrl');
//
//       final convResponse = await _dio.get(convUrl);
//       print('Conv Status: ${convResponse.statusCode}');
//
//       if (convResponse.statusCode == 200) {
//         final payload = convResponse.data['payload'] ?? convResponse.data ?? [];
//         if (payload is List && payload.isNotEmpty) {
//           final convId = payload.first['id'];
//           currentConversationId = convId;
//
//           // ✅ جلب رسائل المحادثة
//           final msgUrl = '/public/api/v1/inboxes/$inboxId/contacts/$contactId/conversations/$convId/messages';
//           print('GET messages: $_baseUrl$msgUrl');
//
//           final msgResponse = await _dio.get(msgUrl);
//
//           final List<dynamic> messagesJson = msgResponse.data['payload'] ?? msgResponse.data ?? [];
//           return messagesJson.map((json) => ChatwootMessage.fromJson(json)).toList();
//         }
//       }
//
//       return [];
//     } catch (e) {
//       print('Get Messages Error: $e');
//       return [];
//     }
//   }
//
//   // ─── WebSocket ───────────────────────────────
//   void connectWebSocket() {
//     if (_webSocket != null) return;
//
//     final pubsubToken = CacheHelper.getString(key: CacheHelper.keyContactToken);
//     if (pubsubToken == null || pubsubToken.isEmpty) {
//       print('No pubsub token');
//       return;
//     }
//
//     try {
//       // ✅ استخدام wss:// بدلاً من https://
//       final wsUrl = '$_wsUrl/cable?pubsub_token=$pubsubToken';
//       print('WS: $wsUrl');
//
//       _webSocket = WebSocketChannel.connect(Uri.parse(wsUrl));
//
//       _webSocket!.stream.listen(
//             (message) => _handleWebSocketMessage(message),
//         onError: (error) => print('WS error: $error'),
//         onDone: () {
//           print('WS closed');
//           _webSocket = null;
//         },
//       );
//
//       _subscribeToConversation();
//     } catch (e) {
//       print('WS failed: $e');
//     }
//   }
//
//   void _subscribeToConversation() {
//     if (_webSocket == null || currentConversationId == null) return;
//
//     _webSocket!.sink.add(jsonEncode({
//       'command': 'subscribe',
//       'identifier': jsonEncode({
//         'channel': 'RoomChannel',
//         'pubsub_token': CacheHelper.getString(key: CacheHelper.keyContactToken),
//         'account_id': currentContact?.id,
//         'conversation_id': currentConversationId,
//       }),
//     }));
//   }
//
//   void _handleWebSocketMessage(dynamic message) {
//     try {
//       final data = jsonDecode(message);
//       if (data['type'] == 'ping') return;
//
//       if (data['message'] != null) {
//         final messageData = data['message'];
//         if (messageData['event'] == 'message.created') {
//           final newMessage = ChatwootMessage.fromJson(messageData['data']);
//           _messageStreamController?.add(newMessage);
//         }
//       }
//     } catch (e) {
//       print('WS message error: $e');
//     }
//   }
//
//   Stream<ChatwootMessage>? get messageStream => _messageStreamController?.stream;
//
//   void disconnect() {
//     _webSocket?.sink.close();
//     _webSocket = null;
//     _messageStreamController?.close();
//     _messageStreamController = null;
//   }
//
//   void dispose() => disconnect();
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/chatwoot_models.dart';
import '../../models/terms.dart';
import 'local/cache_helper.dart';

class ChatwootApiService {
static final ChatwootApiService _instance = ChatwootApiService._internal();
factory ChatwootApiService() => _instance;
ChatwootApiService._internal();

late Dio _dio;
WebSocketChannel? _webSocket;
StreamController<ChatwootMessage>? _messageStreamController;
StreamController<bool>? _connectionStatusController;
Timer? _presenceTimer;

ChatwootContact? currentContact;
String? currentConversationId;
bool _isConnected = false;

final String _baseUrl = 'https://chat.lynomia.com';
final String _wsUrl = 'wss://chat.lynomia.com';

String? get _inboxIdentifier =>
CacheHelper.getString(key: CacheHelper.keyInboxId);

Stream<bool> get connectionStatusStream {
  _connectionStatusController ??= StreamController<bool>.broadcast();
  return _connectionStatusController!.stream;
}

void _setConnectedStatus(bool status) {
  _isConnected = status;
  if (_connectionStatusController != null && !_connectionStatusController!.isClosed) {
    _connectionStatusController!.add(status);
  }
}

// ─── Initialize ──────────────────────────────
void init() {
_dio = Dio(BaseOptions(
baseUrl: _baseUrl,
headers: {
'Content-Type': 'application/json',
'Accept': 'application/json',
},
validateStatus: (status) => true,
));

_messageStreamController = StreamController<ChatwootMessage>.broadcast();
_connectionStatusController = StreamController<bool>.broadcast();
}
// ═══════════════════════════════════════════════════════════════
// REST API - Contact Management (Public API)
// ═══════════════════════════════════════════════════════════════

// ─── Create Contact ──────────────────────────
Future<ChatwootContact> createContact({
required String inboxIdentifier,
required String name,
required String email,
}) async {
try {
final url = '/public/api/v1/inboxes/$inboxIdentifier/contacts';
print('📤 POST: $_baseUrl$url');

final response = await _dio.post(
url,
data: {'name': name, 'email': email},
);

print('📥 Status: ${response.statusCode}');
print('📥 Response: ${response.data}');

if (response.statusCode == 404) {
throw Exception('Inbox not found: $inboxIdentifier');
}

if (response.statusCode != 200 && response.statusCode != 201) {
throw Exception('Error ${response.statusCode}: ${response.data}');
}

final contact = ChatwootContact.fromJson(response.data);
currentContact = contact;

await CacheHelper.saveData(
key: CacheHelper.keyContactId, value: contact.id.toString());
await CacheHelper.saveData(
key: CacheHelper.keyContactToken,
value: contact.pubsubToken ?? '');
await CacheHelper.saveData(
key: CacheHelper.keySourceId,
value: contact.sourceId ?? '');
await CacheHelper.saveData(
key: CacheHelper.keyInboxId, value: inboxIdentifier);

print('✅ Contact created: ${contact.id} | Token: ${contact.pubsubToken}');
return contact;
} catch (e) {
print('❌ Create Contact Error: $e');
throw Exception('Failed to create contact: $e');
}
}

// ─── Get or Create Conversation ──────────────
Future<String> getOrCreateConversation() async {
final sourceId = currentContact?.sourceId ??
CacheHelper.getString(key: CacheHelper.keySourceId);
final inboxId = _inboxIdentifier;

if (sourceId == null || sourceId.isEmpty) {
throw Exception('Contact identifier (source_id) not found');
}
if (inboxId == null || inboxId.isEmpty) {
throw Exception('Inbox ID not found');
}

try {
final url = '/public/api/v1/inboxes/$inboxId/contacts/$sourceId/conversations';
print('📤 GET: $_baseUrl$url');

final response = await _dio.get(url);
print('📥 Get Conv Status: ${response.statusCode}');

if (response.statusCode == 200) {
dynamic payload = response.data;
if (payload is Map && payload.containsKey('payload')) {
payload = payload['payload'];
}

if (payload is List && payload.isNotEmpty) {
final firstConv = payload.first;
if (firstConv is Map) {
final convId = firstConv['id']?.toString();
if (convId != null && convId.isNotEmpty) {
currentConversationId = convId;
await CacheHelper.saveData(
key: CacheHelper.keyConversationId, value: convId);
print('✅ Found conversation: $convId');
return convId;
}
}
}
}

final createUrl = '/public/api/v1/inboxes/$inboxId/contacts/$sourceId/conversations';
print('📤 POST: $_baseUrl$createUrl');

final createResponse = await _dio.post(createUrl, data: {});
print('📥 Create Conv Status: ${createResponse.statusCode}');

if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
dynamic payload = createResponse.data;
if (payload is Map && payload.containsKey('payload')) {
payload = payload['payload'];
}

String? convId;
if (payload is Map) {
convId = payload['id']?.toString();
} else if (payload is List && payload.isNotEmpty) {
final first = payload.first;
if (first is Map) convId = first['id']?.toString();
}

if (convId != null && convId.isNotEmpty) {
currentConversationId = convId;
await CacheHelper.saveData(
key: CacheHelper.keyConversationId, value: convId);
print('✅ Created conversation: $convId');
return convId;
}
}

throw Exception('Failed to get or create conversation');
} catch (e, stackTrace) {
print('❌ Get/Create Conversation Error: $e');
print(stackTrace);
rethrow;
}
}
// ─── Send Message (Public API) ─────────────
Future<ChatwootMessage> sendMessage({required String content}) async {
final sourceId = currentContact?.sourceId ??
CacheHelper.getString(key: CacheHelper.keySourceId);
final inboxId = _inboxIdentifier;

if (sourceId == null || sourceId.isEmpty) throw Exception('No contact source_id');
if (inboxId == null || inboxId.isEmpty) throw Exception('Inbox ID not found');

if (currentConversationId == null) {
final cachedConvId = CacheHelper.getString(key: CacheHelper.keyConversationId);
if (cachedConvId != null && cachedConvId.isNotEmpty) {
currentConversationId = cachedConvId;
} else {
await getOrCreateConversation();
}
}

final convId = currentConversationId!;

try {
final msgUrl = '/public/api/v1/inboxes/$inboxId/contacts/$sourceId/conversations/$convId/messages';
print('📤 POST message: $_baseUrl$msgUrl');

final response = await _dio.post(
msgUrl,
data: {'content': content, 'message_type': 'incoming'},
);

print('📥 Send Status: ${response.statusCode}');

if (response.statusCode == 200 || response.statusCode == 201) {
dynamic payload = response.data;
if (payload is Map && payload.containsKey('payload')) {
payload = payload['payload'];
}
return ChatwootMessage.fromJson(
payload is Map<String, dynamic> ? payload : Map<String, dynamic>.from(payload),
);
}
throw Exception('Failed to send: ${response.statusCode}');
} catch (e) {
print('❌ Send Message Error: $e');
rethrow;
}
}

// ─── Get Messages (Public API) ───────────────
Future<List<ChatwootMessage>> getMessages() async {
final sourceId = currentContact?.sourceId ??
CacheHelper.getString(key: CacheHelper.keySourceId);
final inboxId = _inboxIdentifier;

if (sourceId == null || sourceId.isEmpty) throw Exception('No contact source_id');
if (inboxId == null || inboxId.isEmpty) throw Exception('Inbox ID not found');

if (currentConversationId == null) {
final cachedConvId = CacheHelper.getString(key: CacheHelper.keyConversationId);
if (cachedConvId != null && cachedConvId.isNotEmpty) {
currentConversationId = cachedConvId;
} else {
await getOrCreateConversation();
}
}

final convId = currentConversationId!;

try {
final msgUrl = '/public/api/v1/inboxes/$inboxId/contacts/$sourceId/conversations/$convId/messages';
print('📤 GET messages: $_baseUrl$msgUrl');

final response = await _dio.get(msgUrl);
print('📥 Get Messages Status: ${response.statusCode}');

if (response.statusCode == 200) {
dynamic payload = response.data;
if (payload is Map && payload.containsKey('payload')) {
payload = payload['payload'];
}
if (payload is List) {
return payload.map((json) {
final map = json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json);
return ChatwootMessage.fromJson(map);
}).toList();
}
}
return [];
} catch (e) {
print('❌ Get Messages Error: $e');
return [];
}
}
// ═══════════════════════════════════════════════════════════════
// WebSocket - Real-time Messaging (ActionCable) - FIXED v2.0
// ═══════════════════════════════════════════════════════════════

String? _pubsubToken;
int? _userId;

// ─── Connect WebSocket for Admin API ───────────────────────
void connectWebSocketAdmin({int? accountId, int? conversationId}) {
if (_webSocket != null) {
disconnect();
}

final pubsubToken = _pubsubToken ?? currentContact?.pubsubToken;
if (pubsubToken == null || pubsubToken.isEmpty) {
print('❌ No pubsub token available for WebSocket');
return;
}

try {
// ✅ FIXED: URL بدون أي query parameters
final wsUrl = '$_wsUrl/cable';
print('🔌 Connecting Admin WS: $wsUrl');
print('🔌 Using pubsub_token: $pubsubToken');
print('🔌 Using user_id: ${_userId ?? "not set"}');

_webSocket = WebSocketChannel.connect(Uri.parse(wsUrl));

_webSocket!.stream.listen(
(message) => _handleWebSocketMessage(message),
onError: (error) {
print('❌ WS Error: $error');
_setConnectedStatus(false);
},
onDone: () {
print('🔌 WS Closed');
_setConnectedStatus(false);
_webSocket = null;
Future.delayed(const Duration(seconds: 5), () {
if (pubsubToken != null) {
connectWebSocketAdmin(accountId: accountId, conversationId: conversationId);
}
});
},
);

// الاشتراك بعد فترة قصيرة
Future.delayed(const Duration(milliseconds: 800), () {
_subscribeToRoomChannel(accountId: accountId, conversationId: conversationId);
});

} catch (e) {
print('❌ WS Connection Failed: $e');
}
}


  void _subscribeToRoomChannel({int? accountId, int? conversationId}) {
    if (_webSocket == null) return;

    final targetAccountId = accountId ?? _accountId ?? 4;
    final pubsubToken = _pubsubToken ?? currentContact?.pubsubToken ?? '';
    final userId = _userId ?? CacheHelper.getData(key: 'user_id');

    // ✅ Chatwoot يتوقع identifier بدون user_id للـ Agent
    final identifier = jsonEncode({
      'channel': 'RoomChannel',
      'pubsub_token': pubsubToken,
      'account_id': targetAccountId,
      'user_id': userId, // مهم جداً للـ Admin API
    });

    final subscribePayload = jsonEncode({
      'command': 'subscribe',
      'identifier': identifier,
    });

    print('📡 Subscribing: $identifier');
    _webSocket!.sink.add(subscribePayload);
  }
void _subscribeToRoomChannelWithoutUserId({int? accountId}) {
if (_webSocket == null) return;

final targetAccountId = accountId ?? _accountId ?? 4;
final pubsubToken = _pubsubToken ?? currentContact?.pubsubToken ?? '';

final identifier = jsonEncode({
'channel': 'RoomChannel',
'pubsub_token': pubsubToken,
'account_id': targetAccountId,
});

final subscribePayload = jsonEncode({
'command': 'subscribe',
'identifier': identifier,
});

print('📡 Subscribing without user_id...');
print('📡 Identifier: $identifier');
_webSocket!.sink.add(subscribePayload);
}

// ─── Re-subscribe after conversation change ─────────────────
void subscribeToConversation({required int conversationId, int? accountId}) {
final targetAccountId = accountId ?? _accountId ?? 4;

if (_webSocket == null) {
connectWebSocketAdmin(accountId: targetAccountId, conversationId: conversationId);
return;
}

// لا تحتاج unsubscribe - فقط subscribe للمحادثة الجديدة
_subscribeToRoomChannel(accountId: targetAccountId, conversationId: conversationId);
}
// ─── Legacy: Connect WebSocket (for public API) ───────────────────────
void connectWebSocket() {
if (_webSocket != null || currentContact == null) return;

final pubsubToken = currentContact!.pubsubToken;
if (pubsubToken == null || pubsubToken.isEmpty) {
print('❌ No pubsub token available');
return;
}

try {
final wsUrl = '$_wsUrl/cable';
print('🔌 Connecting WS: $wsUrl');

_webSocket = WebSocketChannel.connect(Uri.parse(wsUrl));

_webSocket!.stream.listen(
(message) => _handleWebSocketMessage(message),
onError: (error) {
print('❌ WS Error: $error');
_isConnected = false;
},
onDone: () {
print('🔌 WS Closed');
_isConnected = false;
_webSocket = null;
Future.delayed(const Duration(seconds: 5), () {
if (currentContact != null) connectWebSocket();
});
},
);

Future.delayed(const Duration(milliseconds: 500), () {
_subscribeToConversationLegacy();
});

_startPresenceTimer();

} catch (e) {
print('❌ WS Connection Failed: $e');
}
}

// ─── Subscribe to RoomChannel (Legacy - for public API) ────────────────
void _subscribeToConversationLegacy() {
if (_webSocket == null || currentContact == null) return;

final pubsubToken = currentContact!.pubsubToken;

final identifier = jsonEncode({
'channel': 'RoomChannel',
'pubsub_token': pubsubToken,
});

final subscribePayload = jsonEncode({
'command': 'subscribe',
'identifier': identifier,
});

print('📡 Subscribing to RoomChannel (Legacy)...');
_webSocket!.sink.add(subscribePayload);
}

// ─── Send Message via WebSocket ──────────────
Future<void> sendMessageWebSocket({required String content}) async {
if (currentContact == null) {
throw Exception('No contact available. Please login first.');
}
if (_webSocket == null || !_isConnected) {
throw Exception('WebSocket not connected. Please wait...');
}

try {
final pubsubToken = currentContact!.pubsubToken;

final identifier = jsonEncode({
'channel': 'RoomChannel',
'pubsub_token': pubsubToken,
});

final messagePayload = jsonEncode({
'command': 'message',
'identifier': identifier,
'data': jsonEncode({
'action': 'send_message',
'content': content,
'message_type': 'incoming',
}),
});

print('📤 Sending message via WS: $content');
_webSocket!.sink.add(messagePayload);

} catch (e) {
print('❌ Send Message WS Error: $e');
throw Exception('Failed to send message: $e');
}
}

// ─── Send Typing Indicator ───────────────────
void sendTypingIndicator(bool isTyping) {
if (_webSocket == null || currentContact == null || !_isConnected) return;

final pubsubToken = currentContact!.pubsubToken;

final identifier = jsonEncode({
'channel': 'RoomChannel',
'pubsub_token': pubsubToken,
});

final typingPayload = jsonEncode({
'command': 'message',
'identifier': identifier,
'data': jsonEncode({
'action': 'toggle_typing',
'typing_status': isTyping ? 'on' : 'off',
}),
});

_webSocket!.sink.add(typingPayload);
}

// ─── Update Presence (Keep Online) ───────────
void _sendPresence() {
if (_webSocket == null || currentContact == null) return;

final pubsubToken = currentContact!.pubsubToken;

final identifier = jsonEncode({
'channel': 'RoomChannel',
'pubsub_token': pubsubToken,
});

final presencePayload = jsonEncode({
'command': 'message',
'identifier': identifier,
'data': jsonEncode({
'action': 'update_presence',
}),
});

_webSocket!.sink.add(presencePayload);
}

void _startPresenceTimer() {
_presenceTimer?.cancel();
_presenceTimer = Timer.periodic(
const Duration(seconds: 30),
(_) => _sendPresence(),
);
}

// ─── Handle Incoming WS Messages ─────────────
void _handleWebSocketMessage(dynamic message) {
try {
final data = jsonDecode(message.toString());
print('📥 WS Raw: $data');

// تجاهل ping messages
if (data['type'] == 'ping') return;

// ✅ تأكيد الاشتراك
if (data['type'] == 'confirm_subscription') {
print('✅✅✅ Subscribed to RoomChannel successfully! ✅✅✅');
_setConnectedStatus(true);
return;
}

// ✅ رفض الاشتراك - محاولة fallback
if (data['type'] == 'reject_subscription') {
print('❌❌❌ Subscription rejected! Trying fallback... ❌❌❌');
_setConnectedStatus(false);
Future.delayed(const Duration(milliseconds: 500), () {
_subscribeToRoomChannelWithoutUserId();
});
return;
}

// رسالة ترحيب
if (data['type'] == 'welcome') {
print('👋 WebSocket connected (welcome received)');
return;
}

// معالجة الرسائل الواردة
if (data['message'] != null) {
final messageData = data['message'];

if (messageData is Map) {
final event = messageData['event'];

if (event == 'message.created' || event == 'message.updated') {
final msgData = messageData['data'];
if (msgData != null) {
final newMessage = ChatwootMessage.fromJson(
msgData is Map<String, dynamic> ? msgData : Map<String, dynamic>.from(msgData),
);
print('✅✅✅ New message received via WS: ${newMessage.content} ✅✅✅');
_messageStreamController?.add(newMessage);
}
}

else if (event == 'conversation.typing_on' || event == 'conversation.typing_off') {
print('⌨️ Typing status: $event');
}

else if (event == 'presence.update') {
print('🟢 Presence updated');
}

// رسالة مباشرة (بدون event wrapper)
else if (messageData['id'] != null && messageData['content'] != null) {
final newMessage = ChatwootMessage.fromJson(
messageData is Map<String, dynamic> ? messageData : Map<String, dynamic>.from(messageData),
);
print('✅ Direct message received: ${newMessage.content}');
_messageStreamController?.add(newMessage);
}
}
}
} catch (e, stackTrace) {
print('❌ WS Message Parse Error: $e');
print(stackTrace);
}
}

// ─── Stream Getter ───────────────────────────
Stream<ChatwootMessage>? get messageStream => _messageStreamController?.stream;

bool get isConnected => _isConnected;

// ═══════════════════════════════════════════════════════════════
// Private API - Admin Login & Inboxes
// ═══════════════════════════════════════════════════════════════

String? _authToken;
int? _accountId;

// ─── Set Auth Token ───────────────────────────
Future<void> setAuthToken(String token, {String? client, String? uid}) async {
_authToken = token;
_dio.options.headers['access-token'] = _authToken;
if (client != null) {
  _dio.options.headers['client'] = client;
}
if (uid != null) {
  _dio.options.headers['uid'] = uid;
}
await CacheHelper.saveData(key: CacheHelper.keyAuthToken, value: _authToken ?? '');
print('✅ Auth token set');
}

  Future<ChatwootLoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = '/auth/sign_in';
      print('📤 POST Login: $_baseUrl$url');

      final response = await _dio.post(
        url,
        data: {'email': email, 'password': password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('📥 Login Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];

        final accessToken = data['access_token'];
        final accountId = data['account_id'];
        final pubsubToken = data['pubsub_token'];
        final userId = data['id'];

        _authToken = accessToken;
        _accountId = accountId;
        _pubsubToken = pubsubToken;
        _userId = userId;

        // ✅ حفظ في الكاش
        await CacheHelper.saveData(key: CacheHelper.keyAuthToken, value: _authToken ?? '');
        await CacheHelper.saveData(key: CacheHelper.keyAccountId, value: _accountId ?? 0);
        await CacheHelper.saveData(key: CacheHelper.keyUserId, value: _userId ?? 0);
        if (pubsubToken != null) {
          await CacheHelper.saveData(key: CacheHelper.keyContactToken, value: pubsubToken);
        }

        _dio.options.headers['api_access_token'] = _authToken;

        print('✅ Access token saved: $_authToken');
        print('✅ Account ID saved: $_accountId');
        print('✅ User ID saved: $_userId');
        print('✅ PubSub token saved: $_pubsubToken');

        return ChatwootLoginResponse(authToken: _authToken, accountId: _accountId);
      }

      throw Exception('فشل تسجيل الدخول: ${response.statusCode}');
    } catch (e) {
      print('❌ Login Error: $e');
      throw Exception('فشل تسجيل الدخول: تأكد من صحة البريد وكلمة المرور');
    }
  }

  // ─── Register/Login with Google ─────────────────
  Future<ChatwootLoginResponse> registerWithGoogle({
    required String idToken,
  }) async {
    try {
      final url = '/api/v1/mobile/auth/google';
      print('📤 POST Register with Google: $_baseUrl$url');
      print('📤 Data: id_token=${idToken.substring(0, 20)}...');

      final response = await _dio.post(
        url,
        data: {'id_token': idToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('📥 Register with Google Status: ${response.statusCode}');
      print('📥 Register with Google Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];

        final accessToken = data['access_token'];
        final accountId = data['accounts'][0]['id'];
        final userId = data['id'];
        final pubsubToken = data['pubsub_token'];

        _authToken = accessToken;
        _accountId = accountId;
        _userId = userId;
        _pubsubToken = pubsubToken;

        // ✅ حفظ في الكاش
        await CacheHelper.saveData(key: CacheHelper.keyAuthToken, value: _authToken ?? '');
        await CacheHelper.saveData(key: CacheHelper.keyAccountId, value: _accountId ?? 0);
        await CacheHelper.saveData(key: CacheHelper.keyUserId, value: _userId ?? 0);
        if (pubsubToken != null) {
          await CacheHelper.saveData(key: CacheHelper.keyContactToken, value: pubsubToken);
        }

        _dio.options.headers['api_access_token'] = _authToken;

        print('✅ Access token saved: $_authToken');
        print('✅ Account ID saved: $_accountId');
        print('✅ User ID saved: $_userId');
        print('✅ PubSub token saved: $_pubsubToken');

        return ChatwootLoginResponse(authToken: _authToken, accountId: _accountId);
      }

      throw Exception('فشل تسجيل الدخول بـ Google: ${response.statusCode}');
    } catch (e) {
      print('❌ Register with Google Error: $e');
      throw Exception('فشل تسجيل الدخول بـ Google: تأكد من صحة البيانات');
    }
  }

  // ─── Register/Login with Apple ─────────────────
  Future<ChatwootLoginResponse> registerWithApple({
    required String identityToken,
    String? name,
  }) async {
    try {
      final url = '/api/v1/mobile/auth/apple';
      print('📤 POST Register with Apple: $_baseUrl$url');
      print('📤 Data: identity_token=${identityToken.substring(0, 20)}..., name=$name');

      final Map<String, dynamic> data = {'identity_token': identityToken};
      if (name != null && name.isNotEmpty) {
        data['name'] = name;
      }

      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('📥 Register with Apple Status: ${response.statusCode}');
      print('📥 Register with Apple Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];

        final accessToken = data['access_token'];
        final accountId = data['accounts'][0]['id'];
        final userId = data['id'];
        final pubsubToken = data['pubsub_token'];

        _authToken = accessToken;
        _accountId = accountId;
        _userId = userId;
        _pubsubToken = pubsubToken;

        // ✅ حفظ في الكاش
        await CacheHelper.saveData(key: CacheHelper.keyAuthToken, value: _authToken ?? '');
        await CacheHelper.saveData(key: CacheHelper.keyAccountId, value: _accountId ?? 0);
        await CacheHelper.saveData(key: CacheHelper.keyUserId, value: _userId ?? 0);
        if (pubsubToken != null) {
          await CacheHelper.saveData(key: CacheHelper.keyContactToken, value: pubsubToken);
        }

        _dio.options.headers['api_access_token'] = _authToken;

        print('✅ Access token saved: $_authToken');
        print('✅ Account ID saved: $_accountId');
        print('✅ User ID saved: $_userId');
        print('✅ PubSub token saved: $_pubsubToken');

        return ChatwootLoginResponse(authToken: _authToken, accountId: _accountId);
      }

      throw Exception('فشل تسجيل الدخول بـ Apple: ${response.statusCode}');
    } catch (e) {
      print('❌ Register with Apple Error: $e');
      throw Exception('فشل تسجيل الدخول بـ Apple: تأكد من صحة البيانات');
    }
  }

// ─── Fetch Inboxes ────────────────────────────
Future<List<ChatwootInbox>> fetchInboxes({int? accountId}) async {
if (_authToken == null || _authToken!.isEmpty) {
throw Exception('Not logged in');
}

final targetAccountId = accountId ?? _accountId ?? 4;

try {
final url = '/api/v1/accounts/$targetAccountId/inboxes';
print('📤 GET Inboxes: $_baseUrl$url');

final response = await _dio.get(
url,
options: Options(
headers: {
'Authorization': 'Bearer $_authToken',
'api_access_token': _authToken,
},
),
);
print('📥 Inboxes Status: ${response.statusCode}');

if (response.statusCode == 200) {
dynamic payload = response.data;
if (payload is Map && payload.containsKey('payload')) {
payload = payload['payload'];
}
if (payload is List) {
final inboxes = payload.map((json) {
final map = json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json);
return ChatwootInbox.fromJson(map);
}).toList();
print('✅ Fetched ${inboxes.length} inboxes');
return inboxes;
}
}
return [];
} catch (e) {
print('❌ Fetch Inboxes Error: $e');
throw Exception('فشل جلب Inboxes');
}
}
// ─── Fetch User Profile ────────────────────────────
Future<String?> fetchUserProfile() async {
if (_authToken == null || _authToken!.isEmpty) {
print('❌ Not logged in - cannot fetch profile');
return null;
}

try {
final url = '/api/v1/profile';
print('📤 GET Profile: $_baseUrl$url');

final response = await _dio.get(
url,
options: Options(
headers: {
'api_access_token': _authToken,
'Content-Type': 'application/json',
},
),
);
print('📥 Profile Status: ${response.statusCode}');

if (response.statusCode == 200) {
final data = response.data['data'] ?? response.data;
final pubsubToken = data['pubsub_token'];
final userId = data['id'];

if (pubsubToken != null && pubsubToken.toString().isNotEmpty) {
_pubsubToken = pubsubToken.toString();
await CacheHelper.saveData(key: CacheHelper.keyContactToken, value: _pubsubToken!);
print('✅ PubSub token from profile: $_pubsubToken');
}

if (userId != null) {
_userId = userId is int ? userId : int.tryParse(userId.toString());
await CacheHelper.saveData(key: 'user_id', value: _userId ?? 0);
print('✅ User ID from profile: $_userId');
}

return _pubsubToken;
}
print('⚠️ No pubsub_token in profile response');
return null;
} catch (e) {
print('❌ Fetch Profile Error: $e');
return null;
}
}

// ─── Check Subscription (External API) - DEPRECATED ────────────────────────────
// ⚠️ تم استبدال هذه الدالة بـ entitlements API الجديد
// تم الاحتفاظ بها للتوافق مع الكود القديم
Future<ChatwootSubscription?> checkSubscription({required String email}) async {
try {
final url = 'https://lynomia.com/api/chat/subscription?email=$email';
print('📤 GET Subscription: $url');

// استخدام Dio مباشرة بدون auth headers لهذه API
final response = await Dio().get(
url,
options: Options(
headers: {
'Content-Type': 'application/json',
},
validateStatus: (status) => true,
),
);
print('📥 Subscription Status: ${response.statusCode}');
print('📥 Subscription Data: ${response.data}');

if (response.statusCode == 200) {
final data = response.data;
if (data is Map) {
  if (data.containsKey('plan')) {
    return ChatwootSubscription.fromJson(data as Map<String, dynamic>);
  }
} else if (data is String && data.contains('user dosent have Subscription')) {
print('❌ User does not have subscription');
return null;
}
}

return null;
} catch (e) {
print('❌ Check Subscription Error: $e');
return null;
}
}

// ─── Fetch Conversations (Admin API) ────────────────────────────
Future<List<ChatwootConversation>> fetchConversations({
required int accountId,
int? inboxId,
String status = 'open',
}) async {
if (_authToken == null || _authToken!.isEmpty) {
throw Exception('Not logged in');
}

try {
String url = '/api/v1/accounts/$accountId/conversations?status=$status';
if (inboxId != null) url += '&inbox_id=$inboxId';
print('📤 GET Conversations: $_baseUrl$url');

final response = await _dio.get(
url,
options: Options(
headers: {
'api_access_token': _authToken,
'Content-Type': 'application/json',
},
),
);
print('📥 Conversations Status: ${response.statusCode}');

if (response.statusCode == 200) {
dynamic payload = response.data;
if (payload is Map && payload.containsKey('data')) {
payload = payload['data'];
}
if (payload is Map && payload.containsKey('payload')) {
payload = payload['payload'];
}
if (payload is List) {
final conversations = payload.map((json) {
final map = json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json);
return ChatwootConversation.fromJson(map);
}).toList();
print('✅ Fetched ${conversations.length} conversations');
return conversations;
}
}
return [];
} catch (e) {
print('❌ Fetch Conversations Error: $e');
throw Exception('فشل جلب المحادثات:');
}
}

  List<ChatwootMessage> _allMessages = [];


  Future<List<ChatwootMessage>> fetchMessagesAdminApi({
    required int accountId,
    required int conversationId,
    int? beforeId, // ✅ Pagination: جلب 20 رسالة أقدم من هذا الـ id
    int? afterId, // ✅ جديد: للـ Polling الذكي
  }) async {
    if (_authToken == null) throw Exception('Not logged in');

    try {
      String url = '/api/v1/accounts/$accountId/conversations/$conversationId/messages';

      final queryParams = <String>[];

      // ✅ جلب الرسائل الأقدم (للتحميل الإضافي عند السحب للأعلى)
      if (beforeId != null) {
        queryParams.add('before=$beforeId');
      }

      // ✅ جديد: جلب الرسائل بعد آخر رسالة معروفة
      if (afterId != null) {
        queryParams.add('after=$afterId');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('📤 GET: $_baseUrl$url');

      final response = await _dio.get(
        url,
        options: Options(headers: {
          'api_access_token': _authToken,
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        dynamic payload = response.data;
        if (payload is Map && payload.containsKey('payload')) {
          payload = payload['payload'];
        }
        if (payload is List) {
          return payload.map((json) {
            final map = json is Map<String, dynamic>
                ? json
                : Map<String, dynamic>.from(json);
            return ChatwootMessage.fromJson(map);
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Fetch Messages Error: $e');
      return [];
    }
  }

Future<ChatwootMessage> sendMessageAdminApi({
required int accountId,
required int conversationId,
required String content,
String messageType = 'outgoing',
bool isPrivate = false,
}) async {
if (_authToken == null || _authToken!.isEmpty) {
throw Exception('Not logged in');
}

try {
final url = '/api/v1/accounts/$accountId/conversations/$conversationId/messages';
print('📤 POST Message: $_baseUrl$url');

final response = await _dio.post(
url,
data: {
'content': content,
'message_type': messageType,
'private': isPrivate,
},
options: Options(
headers: {
'api_access_token': _authToken,
'Content-Type': 'application/json',
},
),
);
print('📥 Send Status: ${response.statusCode}');

if (response.statusCode == 200 || response.statusCode == 201) {
dynamic payload = response.data;
if (payload is Map && payload.containsKey('payload')) {
payload = payload['payload'];
}
return ChatwootMessage.fromJson(
payload is Map<String, dynamic> ? payload : Map<String, dynamic>.from(payload),
);
}
throw Exception('Failed to send: ${response.statusCode}');
} catch (e) {
print('❌ Send Message Error: $e');
throw Exception('فشل إرسال الرسالة: $e');
}
}

  // ─── Set Account ID ───────────────────────────
  void setAccountId(int accountId) {
    _accountId = accountId;
  }

  Future<void> loadAuthToken() async {
    _authToken = CacheHelper.getString(key: CacheHelper.keyAuthToken);
    final accountId = CacheHelper.getData(key: CacheHelper.keyAccountId);
    final userId = CacheHelper.getData(key: CacheHelper.keyUserId);

    if (_authToken != null && _authToken!.isNotEmpty) {
      _dio.options.headers['api_access_token'] = _authToken;
      _dio.options.headers['Authorization'] = 'Bearer $_authToken';
      print('✅ Auth token loaded from cache');
    }

    if (accountId != null) {
      _accountId = accountId is int ? accountId : int.tryParse(accountId.toString());
      print('✅ Account ID loaded from cache: $_accountId');
    }

    if (userId != null) {
      _userId = userId is int ? userId : int.tryParse(userId.toString());
      print('✅ User ID loaded from cache: $_userId');
    }
  }

  // ─── Clear Auth ────────────────────────────────
  Future<void> clearAuth() async {
    _authToken = null;
    _accountId = null;
    _userId = null;
    _pubsubToken = null;
    await CacheHelper.removeData(key: CacheHelper.keyAuthToken);
    await CacheHelper.removeData(key: CacheHelper.keyAccountId);
    await CacheHelper.removeData(key: CacheHelper.keyUserId);
    await CacheHelper.removeData(key: CacheHelper.keyContactToken);
    await CacheHelper.removeData(key: CacheHelper.keyIsLoggedIn);
    _dio.options.headers.remove('access-token');
    _dio.options.headers.remove('client');
    _dio.options.headers.remove('uid');
    _dio.options.headers.remove('api_access_token');
    _dio.options.headers.remove('Authorization');
    print('✅ Auth cleared');
  }

  // ─── Disconnect & Cleanup ────────────────────
  void disconnect() {
    print('🔌 Disconnecting...');
    _presenceTimer?.cancel();
    _presenceTimer = null;

    _webSocket?.sink.close();
    _webSocket = null;
    _setConnectedStatus(false);

    // ✅ لا تقم بإغلاق الـ StreamController هنا
    if (_messageStreamController == null || _messageStreamController!.isClosed) {
      _messageStreamController = StreamController<ChatwootMessage>.broadcast();
    }
  }

  void dispose() => disconnect();

  // ═══════════════════════════════════════════════════════════════
// Delete Message (Admin API)
// ═══════════════════════════════════════════════════════════════
  Future<void> deleteMessageAdminApi({
    required int accountId,
    required int conversationId,
    required dynamic messageId,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Not logged in');
    }

    try {
      final url = '/api/v1/accounts/$accountId/conversations/$conversationId/messages/$messageId';
      print('🗑️ DELETE Message: $_baseUrl$url');

      final response = await _dio.delete(
        url,
        options: Options(
          headers: {
            'api_access_token': _authToken,
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📥 Delete Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Message deleted successfully');
        return;
      }

      throw Exception('Failed to delete: ${response.statusCode}');
    } catch (e) {
      print('❌ Delete Message Error: $e');
      throw Exception('فشل حذف الرسالة: $e');
    }
  }



// ─── Register FCM Token ────────────────────────────
  Future<void> registerFcmToken({
    required String fcmToken,
    required String deviceId,
    required String devicePlatform,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Not logged in');
    }

    try {
      final url = '/api/v1/notification_subscriptions';
      print('📤 POST FCM Token: $_baseUrl$url');
      print(' ✅ FCM Token : ${fcmToken.toString()}');

      final response = await _dio.post(
        url,
        data: {
          'notification_subscription': {
            'subscription_type': 'fcm',
            'subscription_attributes': {
              'push_token': fcmToken,
              'device_id': deviceId,
              'devicePlatform': devicePlatform,
            },
          },
        },
        options: Options(
          headers: {
            'api_access_token': _authToken,
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📥 FCM Register Status: ${response.statusCode}');
      print('📥 FCM Register Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ FCM Token registered successfully');
      } else {
        throw Exception('Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Register FCM Token Error: $e');
      throw Exception('فشل تسجيل FCM Token: $e');
    }
  }

// ─── Get Device Info ────────────────────────────
  Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown';
    String platform = 'android';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? 'android_${DateTime.now().millisecondsSinceEpoch}';
        platform = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'ios_${DateTime.now().millisecondsSinceEpoch}';
        platform = 'ios';
      }
    } catch (e) {
      print('❌ Device Info Error: $e');
      deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }

    return {
      'deviceId': deviceId,
      'platform': platform,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // Fetch Terms & Conditions (Public API)
  // ═══════════════════════════════════════════════════════════════
  Future<Map<String, String>> fetchTerms({required String lang}) async {
    try {
      final url = 'https://lynomia.com/api/term/chat?lang=$lang';
      print('📤 GET Terms: $url');

      final response = await Dio().get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
        ),
      );

      print('📥 Terms Status: ${response.statusCode}');
      print('📥 Terms Response: ${response.data}');

      if (response.statusCode == 200) {
        final model = TermsModel.fromJson(response.data);
        return model.toMap();
      }
      throw Exception('Failed to fetch terms: ${response.statusCode}');
    } catch (e) {
      print('❌ Fetch Terms Error: $e');
      throw Exception('فشل جلب الشروط والأحكام: $e');
    }
  }


  // ═══════════════════════════════════════════════════════════════
// Contact Details & Update (Admin API)
// ═══════════════════════════════════════════════════════════════

// ─── Fetch Contact Details ────────────────────────────
  Future<Map<String, dynamic>> fetchContactDetails({
    required int accountId,
    required int contactId,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Not logged in');
    }

    try {
      final url = '/api/v1/accounts/$accountId/contacts/$contactId';
      print('📤 GET Contact Details: $_baseUrl$url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'api_access_token': _authToken,
            'Content-Type': 'application/json',
          },
        ),
      );
      print('📥 Contact Details Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final payload = response.data['payload'] ?? response.data;
        print('✅ Contact fetched: ${payload['name']}');
        return payload is Map<String, dynamic> ? payload : {};
      }
      throw Exception('Failed to fetch contact: ${response.statusCode}');
    } catch (e) {
      print('❌ Fetch Contact Details Error: $e');
      throw Exception('فشل جلب بيانات المستخدم: $e');
    }
  }

// ─── Update Contact Name ────────────────────────────
  Future<Map<String, dynamic>> updateContactName({
    required int accountId,
    required int contactId,
    required String newName,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Not logged in');
    }

    try {
      final url = '/api/v1/accounts/$accountId/contacts/$contactId';
      print('📤 PUT Update Contact Name: $_baseUrl$url');

      final response = await _dio.put(
        url,
        data: {
          'name': newName,
        },
        options: Options(
          headers: {
            'api_access_token': _authToken,
            'Content-Type': 'application/json',
          },
        ),
      );
      print('📥 Update Contact Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final payload = response.data['payload'] ?? response.data;
        print('✅ Contact updated: ${payload['name']}');
        return payload is Map<String, dynamic> ? payload : {};
      }
      throw Exception('Failed to update contact: ${response.statusCode}');
    } catch (e) {
      print('❌ Update Contact Error: $e');
      throw Exception('فشل تحديث اسم المستخدم: $e');
    }
  }



// ✅ دالة مساعدة لتحديد MIME type
  String _getMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'mp3': return 'audio/mpeg';
      case 'm4a': return 'audio/mp4';
      case 'aac': return 'audio/aac';
      case 'ogg': return 'audio/ogg';
      case 'wav': return 'audio/wav';
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }

  // في ملف ChatwootApiService - داخل sendMessageWithAttachment
  Future<ChatwootMessage> sendMessageWithAttachment({
    required int accountId,
    required int conversationId,
    String? content,
    required File file,
    String messageType = 'outgoing',
    bool isPrivate = false,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Not logged in');
    }

    try {
      final url = '/api/v1/accounts/$accountId/conversations/$conversationId/messages';
      print('📤 POST Message with Attachment: $_baseUrl$url');

      // ✅ تحديد الامتداد والنوع الحقيقي
      final ext = file.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(ext);

      // ✅ تحديد file_type للـ Chatwoot (image, audio, video, file)
      String chatwootFileType = 'file';
      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
        chatwootFileType = 'image';
      } else if (['mp3', 'm4a', 'aac', 'ogg', 'wav', 'flac'].contains(ext)) {
        chatwootFileType = 'audio';
      } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
        chatwootFileType = 'video';
      }

      print('📎 File: ${file.path} | Ext: $ext | MIME: $mimeType | ChatwootType: $chatwootFileType');

      // ✅ إنشاء FormData مع النوع الصحيح
      // A captionless voice note used to be sent with '🎵 تسجيل صوتي' as its BODY -- an Arabic
      // string on every send whatever the sender's locale, and a non-empty body makes the dashboard
      // render a text bubble instead of its audio player. An attachment-only message is the normal
      // shape here; every other file type already sends ''.
      final formData = FormData.fromMap({
        'content': content ?? '',
        'message_type': messageType,
        'private': isPrivate.toString(),
      });

      // ✅ إضافة الملف مع النوع الصحيح
      formData.files.add(
        MapEntry(
          'attachments[]',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );

      // ✅ إضافة file_type كمعامل منفصل إذا كان Chatwoot يدعمه
      if (chatwootFileType != 'file') {
        formData.fields.add(MapEntry('file_type', chatwootFileType));
      }

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'api_access_token': _authToken,
          },
        ),
      );
      print('📥 Send Attachment Status: ${response.statusCode}');
      print('📥 Send Attachment Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic payload = response.data;
        if (payload is Map && payload.containsKey('payload')) {
          payload = payload['payload'];
        }
        final message = ChatwootMessage.fromJson(
          payload is Map<String, dynamic> ? payload : Map<String, dynamic>.from(payload),
        );
        print('✅ Sent attachment: ${message.attachments?.length} attachments');
        return message;
      }
      throw Exception('Failed to send: ${response.statusCode}');
    } catch (e) {
      print('❌ Send Attachment Error: $e');
      throw Exception('فشل إرسال الملف: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
// CREATE CONTACT (Admin API) - NEW
// ═══════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> createContactAdminApi({
    required int accountId,
    required int inboxId,
    required String name,
    required String email,
    String? phoneNumber,
    String? identifier,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Not logged in');
    }

    try {
      final url = '/api/v1/accounts/$accountId/contacts';
      print('📤 POST Create Contact: $_baseUrl$url');

      final response = await _dio.post(
        url,
        data: {
          'inbox_id': inboxId,
          'name': name,
          'email': email,
          if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
          if (identifier != null && identifier.isNotEmpty) 'identifier': identifier,
        },
        options: Options(
          headers: {
            'api_access_token': _authToken,
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📥 Create Contact Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ FIX: Chatwoot يرجع { payload: { contact: {...}, contact_inboxes: [...] } }
        final payload = response.data['payload'] ?? response.data;

        // استخراج contact_data (قد يكون مباشرة أو داخل contact)
        final contactData = payload['contact'] ?? payload;

        print('✅ Contact created: ${contactData['id']} | ${contactData['email']}');
        print('✅ Contact inboxes: ${contactData['contact_inboxes']}');

        return contactData is Map<String, dynamic> ? contactData : {};
      }
      throw Exception('Failed to create contact: ${response.statusCode}');
    } catch (e) {
      print('❌ Create Contact Error: $e');
      throw Exception('فشل إنشاء جهة الاتصال: $e');
    }
  }

// ═══════════════════════════════════════════════════════════════
// SEARCH CONTACTS (Admin API) - NEW
// ═══════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> searchContactsAdminApi({
    required int accountId,
    required String query,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Not logged in');
    }

    try {
      final url = '/api/v1/accounts/$accountId/contacts/search?q=${Uri.encodeComponent(query)}';
      print('📤 GET Search Contacts: $_baseUrl$url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'api_access_token': _authToken,
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📥 Search Contacts Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        dynamic payload = response.data;
        if (payload is Map && payload.containsKey('payload')) {
          payload = payload['payload'];
        }
        if (payload is List) {
          return payload.map((json) {
            return json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json);
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Search Contacts Error: $e');
      return [];
    }
  }

// ═══════════════════════════════════════════════════════════════
// CREATE CONVERSATION (Admin API) - NEW ⭐⭐⭐
// ═══════════════════════════════════════════════════════════════
  Future<ChatwootConversation> createConversationAdminApi({
    required int accountId,
    required int inboxId,
    required int contactId,
    String? sourceId,
    String status = 'open',
    String? initialMessage,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Not logged in');
    }

    try {
      final url = '/api/v1/accounts/$accountId/conversations';
      print('📤 POST Create Conversation: $_baseUrl$url');

      final Map<String, dynamic> data = {
        'inbox_id': inboxId,
        'contact_id': contactId,
        'status': status,
        if (sourceId != null && sourceId.isNotEmpty) 'source_id': sourceId,
        // ✅ إذا أردت إرسال رسالة أولى مباشرة مع إنشاء المحادثة
        if (initialMessage != null && initialMessage.isNotEmpty)
          'message': {
            'content': initialMessage,
            'message_type': 'outgoing',
          },
      };

      final response = await _dio.post(
        url,
        data: data,
        options: Options(
          headers: {
            'api_access_token': _authToken,
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📥 Create Conversation Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic payload = response.data;
        if (payload is Map && payload.containsKey('payload')) {
          payload = payload['payload'];
        }
        final conversation = ChatwootConversation.fromJson(
          payload is Map<String, dynamic> ? payload : {},
        );
        print('✅ Conversation created: ${conversation.id}');
        return conversation;
      }
      throw Exception('Failed to create conversation: ${response.statusCode}');
    } catch (e) {
      print('❌ Create Conversation Error: $e');
      throw Exception('فشل إنشاء المحادثة: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UPDATE LAST SEEN (Mark as Read - Admin API)
  // ═══════════════════════════════════════════════════════════════
  Future<void> updateLastSeen({
    required int accountId,
    required int conversationId,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) return;
    try {
      final url = '/api/v1/accounts/$accountId/conversations/$conversationId/update_last_seen';
      print('📤 POST update_last_seen: $_baseUrl$url');
      final response = await _dio.post(
        url,
        data: {
          'agent_last_seen_at': DateTime.now().toUtc().toIso8601String(),
        },
        options: Options(
          headers: {
            'api_access_token': _authToken,
            'Content-Type': 'application/json',
          },
        ),
      );
      print('📥 update_last_seen Status: ${response.statusCode}');
    } catch (e) {
      print('❌ update_last_seen Error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WHATSAPP TEMPLATES (Admin API) - NEW ⭐⭐⭐
  // ═══════════════════════════════════════════════════════════════
  Future<List<WhatsAppTemplate>> fetchWhatsAppTemplates({
    required int accountId,
    required int inboxId,
    int? conversationId,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Not logged in');
    }

    final endpoints = [
      '/api/v1/accounts/$accountId/inboxes/$inboxId/message_templates',
      '/api/v1/accounts/$accountId/inboxes/$inboxId/templates',
      if (conversationId != null) '/api/v1/accounts/$accountId/conversations/$conversationId/templates',
      '/api/v1/accounts/$accountId/inboxes/$inboxId',
    ];

    for (final url in endpoints) {
      try {
        print('📤 Trying GET WhatsApp Templates: $_baseUrl$url');
        final response = await _dio.get(
          url,
          options: Options(
            headers: {
              'api_access_token': _authToken,
              'Content-Type': 'application/json',
            },
          ),
        );

        print('📥 Status for $url: ${response.statusCode}');

        if (response.statusCode == 200) {
          dynamic rawData = response.data;
          dynamic payload = rawData;

          if (rawData is Map) {
            if (rawData.containsKey('payload')) {
              payload = rawData['payload'];
            } else if (rawData.containsKey('message_templates')) {
              payload = rawData['message_templates'];
            } else if (rawData.containsKey('channel') && rawData['channel'] is Map && (rawData['channel'] as Map).containsKey('message_templates')) {
              payload = rawData['channel']['message_templates'];
            }
          }

          if (payload is List && payload.isNotEmpty) {
            final templates = payload.map((json) {
              final map = json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json);
              return WhatsAppTemplate.fromJson(map);
            }).toList();
            print('✅ Fetched ${templates.length} WhatsApp templates from $url');
            return templates;
          }
        }
      } catch (e) {
        print('⚠️ Failed fetching templates from $url: $e');
      }
    }
    print('❌ All WhatsApp template endpoints returned empty or failed');
    return [];
  }

  Future<ChatwootMessage> sendWhatsAppTemplateAdminApi({
    required int accountId,
    required int conversationId,
    required String templateName,
    required String language,
    String? category,
    Map<String, String>? parameters,
    required String messageContent,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Not logged in');
    }

    try {
      final url = '/api/v1/accounts/$accountId/conversations/$conversationId/messages';
      print('📤 POST WhatsApp Template Message: $_baseUrl$url');

      final Map<String, dynamic> templateParams = {
        'name': templateName,
        'category': category ?? 'MARKETING',
        'language': language,
      };

      if (parameters != null && parameters.isNotEmpty) {
        templateParams['processed_params'] = parameters;
      }

      final response = await _dio.post(
        url,
        data: {
          'content': messageContent,
          'template_params': templateParams,
          'message_type': 'outgoing',
        },
        options: Options(
          headers: {
            'api_access_token': _authToken,
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📥 Send WhatsApp Template Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic payload = response.data;
        if (payload is Map && payload.containsKey('payload')) {
          payload = payload['payload'];
        }
        final message = ChatwootMessage.fromJson(
          payload is Map<String, dynamic> ? payload : Map<String, dynamic>.from(payload),
        );
        print('✅ Sent WhatsApp Template message: ${message.id}');
        return message;
      }
      throw Exception('Failed to send template: ${response.statusCode}');
    } catch (e) {
      print('❌ Send WhatsApp Template Error: $e');
      throw Exception('فشل إرسال قالب الواتس أب: $e');
    }
  }
}

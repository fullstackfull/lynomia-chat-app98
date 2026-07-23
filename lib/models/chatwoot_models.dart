// import 'package:equatable/equatable.dart';
//
// class ChatwootContact extends Equatable {
//   final int id;
//   final String? name;
//   final String? email;
//   final String? pubsubToken;
//
//   const ChatwootContact({
//     required this.id,
//     this.name,
//     this.email,
//     this.pubsubToken,
//   });
//
//   factory ChatwootContact.fromJson(Map<String, dynamic> json) {
//     return ChatwootContact(
//       id: json['id'] ?? 0,
//       name: json['name'],
//       email: json['email'],
//       pubsubToken: json['pubsub_token'],
//     );
//   }
//
//   @override
//   List<Object?> get props => [id, name, email, pubsubToken];
// }
//
// class ChatwootMessage extends Equatable {
//   final int id;
//   final String? content;
//   final String? messageType;
//   final String? senderType;
//   final String? senderName;
//   final DateTime? createdAt;
//
//   const ChatwootMessage({
//     required this.id,
//     this.content,
//     this.messageType,
//     this.senderType,
//     this.senderName,
//     this.createdAt,
//   });
//
//   factory ChatwootMessage.fromJson(Map<String, dynamic> json) {
//     return ChatwootMessage(
//       id: json['id'] ?? 0,
//       content: json['content'],
//       messageType: json['message_type'],
//       senderType: json['sender_type'],
//       senderName: json['sender']?['name'],
//       createdAt: json['created_at'] != null
//           ? DateTime.parse(json['created_at'].toString())
//           : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'content': content,
//     'message_type': messageType,
//     'sender_type': senderType,
//     'sender': {'name': senderName},
//     'created_at': createdAt?.toIso8601String(),
//   };
//
//   @override
//   List<Object?> get props => [id, content, senderType, createdAt];
// }


import 'package:equatable/equatable.dart';

class ChatwootContact extends Equatable {
  final dynamic id;
  final String? name;
  final String? email;
  final String? pubsubToken;
  final String? sourceId;

  const ChatwootContact({
    required this.id,
    this.name,
    this.email,
    this.pubsubToken,
    this.sourceId,
  });

  factory ChatwootContact.fromJson(Map<String, dynamic> json) {
    return ChatwootContact(
      id: json['id'],         // ✅ لا نحول إلى int
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      pubsubToken: json['pubsub_token']?.toString(),
      sourceId: json['source_id']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, email, pubsubToken, sourceId];
}

class ChatwootMessage extends Equatable {
  final dynamic id;           // ✅ String أو int من Chatwoot
  final String? content;
  final String? messageType;
  final String? senderType;
  final String? senderName;
  final DateTime? createdAt;
  final int? conversationId;
  final int? inboxId;
  final List<ChatwootAttachment>? attachments;  // ✅ جديد
  final String? contentType;

  const ChatwootMessage({
    required this.id,
    this.content,
    this.messageType,
    this.senderType,
    this.senderName,
    this.createdAt,
    this.conversationId,
    this.inboxId,
    this.attachments,  // ✅
    this.contentType,
  });

  factory ChatwootMessage.fromJson(Map<String, dynamic> json) {
    // استخراج المرفقات
    List<ChatwootAttachment>? attachments;
    if (json['attachments'] != null && json['attachments'] is List) {
      attachments = (json['attachments'] as List)
          .map((a) => ChatwootAttachment.fromJson(a))
          .toList();
    }


    DateTime? parsedDate;
    if (json['created_at'] != null) {
      final rawCreatedAt = json['created_at'];
      if (rawCreatedAt is int) {
        if (rawCreatedAt.toString().length == 10) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt * 1000);
        } else {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
        }
      } else if (rawCreatedAt is double) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt.toInt());
      } else {
        parsedDate = DateTime.tryParse(rawCreatedAt.toString());
      }
    }

    return ChatwootMessage(
      id: json['id'],         // ✅ لا نحول إلى int
      content: json['content']?.toString(),
      messageType: json['message_type']?.toString(),
      senderType: json['sender_type']?.toString(),
      senderName: json['sender']?['name']?.toString() ?? json['sender_name']?.toString(),
      createdAt: parsedDate,
      conversationId: json['conversation_id'],
      inboxId: json['inbox_id'],
      attachments: attachments,  // ✅
      contentType: json['content_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'message_type': messageType,
    'sender_type': senderType,
    'sender': {'name': senderName},
    'created_at': createdAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, content, senderType,attachments ,createdAt];
}

// ✅ نموذج Inbox لجلب القائمة من Chatwoot
class ChatwootInbox extends Equatable {
  final int id;
  final String? name;
  final String? inboxIdentifier;
  final String? channelType;
  final String? avatarUrl;
  final bool? enabled;

  const ChatwootInbox({
    required this.id,
    this.name,
    this.inboxIdentifier,
    this.channelType,
    this.avatarUrl,
    this.enabled,
  });

  factory ChatwootInbox.fromJson(Map<String, dynamic> json) {
    return ChatwootInbox(
      id: json['id'] ?? 0,
      name: json['name']?.toString(),
      inboxIdentifier: json['inbox_identifier']?.toString() ?? json['identifier']?.toString(),
      channelType: json['channel_type']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      enabled: json['enabled'] ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, inboxIdentifier, channelType, avatarUrl, enabled];
}

// ✅ نموذج تسجيل الدخول
class ChatwootLoginResponse extends Equatable {
  final String? authToken;
  final int? userId;
  final int? accountId;
  final String? message;

  const ChatwootLoginResponse({
    this.authToken,
    this.userId,
    this.accountId,
    this.message,
  });

  factory ChatwootLoginResponse.fromJson(Map<String, dynamic> json) {
    return ChatwootLoginResponse(
      authToken: json['auth_token']?.toString(),
      userId: json['user_id'] ?? json['id'],
      accountId: json['account_id'],
      message: json['message']?.toString(),
    );
  }

  @override
  List<Object?> get props => [authToken, userId, accountId, message];
}

// ✅ نموذج المحادثة (Conversation)
class ChatwootConversation extends Equatable {
  final int id;
  final int? inboxId;
  final int? contactId;        // ✅ جديد: معرف العميل
  final String? status;
  final int? messagesCount;
  final int? unreadCount;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final String? contactName;
  final String? contactAvatar;  // ✅ جديد: رابط الصورة
  final String? contactEmail;   // ✅ جديد: البريد
  final String? contactPhone;   // ✅ جديد: الهاتف
  final int? accountId;
  final String? channelType;

  const ChatwootConversation({
    required this.id,
    this.inboxId,
    this.contactId,           // ✅
    this.status,
    this.messagesCount,
    this.unreadCount,
    this.lastMessageContent,
    this.lastMessageAt,
    this.contactName,
    this.contactAvatar,        // ✅
    this.contactEmail,         // ✅
    this.contactPhone,         // ✅
    this.accountId,
    this.channelType,
  });

  factory ChatwootConversation.fromJson(Map<String, dynamic> json) {
    // استخراج بيانات الـ contact من الـ sender
    final sender = json['meta']?['sender'] ?? json['sender'];
    final contact = json['meta']?['contact'] ?? json['contact'];
    // Response من Chatwoot API يكون:
    // { meta: { sender: {...}, channel: "...", assignee: {...} }, id: 23, messages: [...], ... }
    // أو قد يكون مباشرة: { id: 23, contact: {...}, ... }

    DateTime? parsedLastAt;
    final lastActivityAt = json['last_activity_at'] ?? json['last_message_at'];
    if (lastActivityAt != null) {
      if (lastActivityAt is int) {
        // Unix timestamp
        if (lastActivityAt.toString().length == 10) {
          parsedLastAt = DateTime.fromMillisecondsSinceEpoch(lastActivityAt * 1000);
        } else {
          parsedLastAt = DateTime.fromMillisecondsSinceEpoch(lastActivityAt);
        }
      } else if (lastActivityAt is String) {
        parsedLastAt = DateTime.tryParse(lastActivityAt);
      }
    }

    // استخراج معلومات المرسل من meta.sender
    ChatwootContact? senderContact;
    String? senderName;
    String? senderAvatar;

    if (json['meta'] != null && json['meta']['sender'] != null) {
      senderContact = ChatwootContact.fromJson(json['meta']['sender']);
      senderName = json['meta']['sender']['name']?.toString();
      senderAvatar = json['meta']['sender']['thumbnail']?.toString();
    } else if (json['contact'] != null) {
      senderContact = ChatwootContact.fromJson(json['contact']);
      senderName = json['contact']['name']?.toString();
      senderAvatar = json['contact']['thumbnail']?.toString();
    }

    // استخراج آخر رسالة
    String? lastMsg;
    if (json['messages'] != null && json['messages'] is List && (json['messages'] as List).isNotEmpty) {
      final messages = json['messages'] as List;
      lastMsg = messages.last['content']?.toString();
    } else if (json['last_message'] != null) {
      lastMsg = json['last_message']['content']?.toString();
    } else if (json['last_non_activity_message'] != null) {
      lastMsg = json['last_non_activity_message']['content']?.toString();
    }

    // استخراج نوع القناة
    String? channel;
    if (json['meta'] != null && json['meta']['channel'] != null) {
      channel = json['meta']['channel'].toString();
    }

    return ChatwootConversation(
      id: json['id'] ?? 0,
      inboxId: json['inbox_id'],
      contactId: contact?['id'] ?? sender?['id'],  // ✅
      status: json['status']?.toString(),
      messagesCount: json['messages_count'],
      unreadCount: json['unread_count'],
      lastMessageContent: json['last_non_activity_message']?['content']?.toString() ??
          json['messages']?.last?['content']?.toString(),
      lastMessageAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'].toString())
          : null,
      contactName: contact?['name']?.toString() ??
          sender?['name']?.toString() ??
          sender?['available_name']?.toString() ??
          'مجهول',
      contactAvatar: contact?['thumbnail']?.toString() ??
          sender?['thumbnail']?.toString() ??
          sender?['avatar_url']?.toString(),  // ✅
      contactEmail: contact?['email']?.toString() ??
          sender?['email']?.toString(),  // ✅
      contactPhone: contact?['phone_number']?.toString() ??
          sender?['phone_number']?.toString(),  // ✅
      accountId: json['account_id'],
      channelType: json['channel_type']?.toString() ?? json['inbox']?['channel_type']?.toString(),
    );
  }

  @override
  // List<Object?> get props => [id, inboxId, status, messagesCount, lastMessageAt];
  List<Object?> get props => [id, inboxId, status, unreadCount, lastMessageAt];
}

// ✅ نموذج الاشتراك (Subscription)
class ChatwootSubscription extends Equatable {
  final String? plan;
  final String? status;
  final String? startsAt;
  final String? endsAt;
  final bool isActive;

  const ChatwootSubscription({
    this.plan,
    this.status,
    this.startsAt,
    this.endsAt,
    this.isActive = false,
  });



  factory ChatwootSubscription.fromJson(Map<String, dynamic> json) {
    return ChatwootSubscription(
      plan: json['plan']?.toString(),
      status: json['status']?.toString(),
      startsAt: json['starts_at']?.toString(),
      endsAt: json['ends_at']?.toString(),
      isActive: json['is_active'] == true || json['status']?.toString().toLowerCase() == 'active',
    );
  }
  Map<String, dynamic> toJson() => {
    'plan': plan,
    'status': status,
    'starts_at': startsAt,
    'ends_at': endsAt,
    'is_active': isActive,  // ✅
  };

  @override
  List<Object?> get props => [plan, status, isActive, endsAt];
}

class ChatwootAttachment extends Equatable {
  final int id;
  final String? fileName;
  final String? fileType;  // image, audio, video, file
  final String? fileUrl;   // رابط الملف الكامل
  final String? thumbUrl;  // رابط الصورة المصغرة
  final int? fileSize;
  final double? width;
  final double? height;

  const ChatwootAttachment({
    required this.id,
    this.fileName,
    this.fileType,
    this.fileUrl,
    this.thumbUrl,
    this.fileSize,
    this.width,
    this.height,
  });

  factory ChatwootAttachment.fromJson(Map<String, dynamic> json) {
    // استخراج fileType من الـ API أو تحديده من الامتداد
    String? fileType = json['file_type']?.toString();
    
    // استخراج الامتداد من extension أو data_url أو file_name
    String ext = '';
    if (json['extension'] != null && json['extension'].toString().isNotEmpty) {
      ext = json['extension'].toString().toLowerCase();
    } else if (json['data_url'] != null || json['file_url'] != null) {
      final url = (json['data_url']?.toString() ?? json['file_url']?.toString() ?? '');
      ext = url.split('.').last.toLowerCase();
      // إزالة معاملات الاستعلام من الامتداد
      if (ext.contains('?')) {
        ext = ext.split('?').first;
      }
    } else {
      ext = json['file_name']?.toString().split('.').last.toLowerCase() ?? '';
    }

    // استخدام content_type أيضاً لتحديد النوع
    final contentType = json['content_type']?.toString().toLowerCase() ?? '';

    // إذا لم يكن file_type محدداً، حدده من الامتداد أو content_type
    if (fileType == null || fileType.isEmpty || fileType == 'file') {
      if (contentType.contains('audio') || ['mp3', 'm4a', 'aac', 'ogg', 'wav', 'flac'].contains(ext)) {
        fileType = 'audio';
      } else if (contentType.contains('image') || ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
        fileType = 'image';
      } else if (contentType.contains('video') || ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
        fileType = 'video';
      } else {
        fileType = 'file';
      }
    }

    return ChatwootAttachment(
      id: json['id'] ?? 0,
      fileName: json['file_name']?.toString() ?? (ext.isNotEmpty ? 'audio.$ext' : 'audio.m4a'),
      fileType: fileType,
      fileUrl: json['data_url']?.toString() ?? json['file_url']?.toString(),
      thumbUrl: json['thumb_url']?.toString(),
      fileSize: json['file_size'] is int ? json['file_size'] : null,
      width: json['width'] is double ? json['width'] : null,
      height: json['height'] is double ? json['height'] : null,
    );
  }

  bool get isImage => fileType?.toLowerCase().contains('image') ?? false;
  bool get isAudio => fileType?.toLowerCase().contains('audio') ?? false;
  bool get isVideo => fileType?.toLowerCase().contains('video') ?? false;
  bool get isFile => !isImage && !isAudio && !isVideo;

  @override
  List<Object?> get props => [id, fileName, fileType, fileUrl];
}
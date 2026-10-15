



import 'package:equatable/equatable.dart';

import '../../models/chatwoot_models.dart';

abstract class AppStates extends Equatable {
  const AppStates();
  @override
  List<Object?> get props => [];
}

class AppInitialState extends AppStates {}
class AppChangeThemeState extends AppStates {
  final bool isDark;
  const AppChangeThemeState(this.isDark);
  @override
  List<Object?> get props => [isDark];
}

class AppCreateContactLoadingState extends AppStates {}
class AppCreateContactSuccessState extends AppStates {}
class AppCreateContactErrorState extends AppStates {
  final String error;
  const AppCreateContactErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}

class AppLoadSessionLoadingState extends AppStates {}
class AppLoadSessionSuccessState extends AppStates {}
class AppLoadSessionErrorState extends AppStates {
  final String error;
  const AppLoadSessionErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}
class AppNoSessionState extends AppStates {}

class AppMessagesLoadedState extends AppStates {}
class AppMoreMessagesLoadedState extends AppStates {
  final int addedCount;
  const AppMoreMessagesLoadedState({required this.addedCount});
  @override
  List<Object?> get props => [addedCount];
}
class AppNewMessageReceivedState extends AppStates {
  final Map<String, dynamic> message;
  const AppNewMessageReceivedState({required this.message});
  @override
  List<Object?> get props => [message];
}

class AppTypingStatusState extends AppStates {
  final bool isTyping;
  const AppTypingStatusState({required this.isTyping});
  @override
  List<Object?> get props => [isTyping];
}

class AppSendMessageLoadingState extends AppStates {}
class AppSendMessageSuccessState extends AppStates {}
class AppSendMessageErrorState extends AppStates {
  final String error;
  const AppSendMessageErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}

class AppLogoutState extends AppStates {}

// ─── Login States ───────────────────────────────
class AppLoginLoadingState extends AppStates {}
class AppLoginSuccessState extends AppStates {}
/// A login failure, as a localization KEY rather than a sentence.
///
/// It used to carry `error.toString()`, which the login screen showed verbatim. So an
/// English-locale user whose sign-in failed got an Arabic sentence, and the ones that came from the
/// catch block arrived with Dart's own `Exception: ` prefix glued to the front. A key translates at
/// the point of display, which is the only place that knows the user's locale -- the same shape
/// `AppPaymentHistoryErrorState` already relies on.
class AppLoginErrorState extends AppStates {
  final String messageKey;
  const AppLoginErrorState({required this.messageKey});
  @override
  List<Object?> get props => [messageKey];
}

// ─── Fetch Inboxes States ─────────────────────
class AppFetchInboxesLoadingState extends AppStates {}
class AppFetchInboxesSuccessState extends AppStates {}
class AppFetchInboxesErrorState extends AppStates {
  final String error;
  const AppFetchInboxesErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}

// ─── Fetch Conversations States ─────────────────────
class AppFetchConversationsLoadingState extends AppStates {}
class AppFetchConversationsSuccessState extends AppStates {}
class AppFetchConversationsErrorState extends AppStates {
  final String error;
  const AppFetchConversationsErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}

// ─── Subscription States ─────────────────────
class AppSubscriptionLoadingState extends AppStates {}
class AppSubscriptionActiveState extends AppStates {
  final String plan;
  final String? endsAt;
  const AppSubscriptionActiveState({required this.plan, this.endsAt});
  @override
  List<Object?> get props => [plan, endsAt];
}
class AppSubscriptionInactiveState extends AppStates {}
class AppSubscriptionErrorState extends AppStates {
  final String error;
  const AppSubscriptionErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}

class AppSubscriptionCheckCompleteState extends AppStates {}
// في نهاية الملف، أضف:
class AppAuthCompleteState extends AppStates {}

// ─── FCM Token States ─────────────────────
class AppFcmTokenLoadedState extends AppStates {
  final String fcmToken;
  const AppFcmTokenLoadedState({required this.fcmToken});
  @override
  List<Object?> get props => [fcmToken];
}

class AppFcmTokenErrorState extends AppStates {
  final String error;
  const AppFcmTokenErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}

class AppFetchTermsLoadingState extends AppStates {}
class AppFetchTermsSuccessState extends AppStates {
  final Map<String, String> termsData;
  final bool isOffline;
  const AppFetchTermsSuccessState({required this.termsData,this.isOffline = false,});
  @override   List<Object?> get props => [termsData, isOffline];
}
class AppFetchTermsErrorState extends AppStates {
  final String error;
  const AppFetchTermsErrorState({required this.error});
  @override List<Object?> get props => [error];
}

// في ملف states.dart - أضف في النهاية:

// ─── Contact Details States ─────────────────────
class AppFetchContactDetailsLoadingState extends AppStates {}
class AppFetchContactDetailsSuccessState extends AppStates {
  final Map<String, dynamic> details;
  const AppFetchContactDetailsSuccessState({required this.details});
  @override
  List<Object?> get props => [details];
}
class AppFetchContactDetailsErrorState extends AppStates {
  final String error;
  const AppFetchContactDetailsErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}

// ─── Update Contact States ─────────────────────
class AppUpdateContactLoadingState extends AppStates {}
class AppUpdateContactSuccessState extends AppStates {
  final Map<String, dynamic> details;
  const AppUpdateContactSuccessState({required this.details});
  @override
  List<Object?> get props => [details];
}
class AppUpdateContactErrorState extends AppStates {
  final String error;
  const AppUpdateContactErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}

// ─── Create New Conversation States ─────────────────────
class AppCreateConversationLoadingState extends AppStates {}
class AppCreateConversationSuccessState extends AppStates {
  final ChatwootConversation conversation;
  const AppCreateConversationSuccessState({required this.conversation});
  @override
  List<Object?> get props => [conversation];
}
class AppCreateConversationErrorState extends AppStates {
  final String error;
  const AppCreateConversationErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}

// ─── Create Contact States ─────────────────────
class AppCreateContactAdminLoadingState extends AppStates {}
class AppCreateContactAdminSuccessState extends AppStates {
  final Map<String, dynamic> contactData;
  const AppCreateContactAdminSuccessState({required this.contactData});
  @override
  List<Object?> get props => [contactData];
}
class AppCreateContactAdminErrorState extends AppStates {
  final String error;
  const AppCreateContactAdminErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}

// ─── WhatsApp Templates States ─────────────────────
class AppFetchWhatsAppTemplatesLoadingState extends AppStates {}
class AppFetchWhatsAppTemplatesSuccessState extends AppStates {
  final List<WhatsAppTemplate> templates;
  const AppFetchWhatsAppTemplatesSuccessState({required this.templates});
  @override
  List<Object?> get props => [templates];
}
class AppFetchWhatsAppTemplatesErrorState extends AppStates {
  final String error;
  const AppFetchWhatsAppTemplatesErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}

class AppSendWhatsAppTemplateLoadingState extends AppStates {}
class AppSendWhatsAppTemplateSuccessState extends AppStates {}
class AppSendWhatsAppTemplateErrorState extends AppStates {
  final String error;
  const AppSendWhatsAppTemplateErrorState({required this.error});
  @override
  List<Object?> get props => [error];
}





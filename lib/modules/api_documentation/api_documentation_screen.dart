import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../layout/cubit/cubit.dart';
import '../../modules/language/cubit/cubit.dart';
import '../../shared/app_localizations.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';
import 'api_reference.dart';

class ApiDocumentationScreen extends StatefulWidget {
  const ApiDocumentationScreen({super.key});

  @override
  State<ApiDocumentationScreen> createState() => _ApiDocumentationScreenState();
}

class _ApiDocumentationScreenState extends State<ApiDocumentationScreen> {
  final Set<String> _expandedCards = {};
  final TextEditingController _search = TextEditingController();

  /// What is in the search box, and how many cards survived it. `_shown` is tallied while the list
  /// of children is constructed, which finishes before anything reads it.
  String _query = '';
  int _shown = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleCard(String cardId) {
    setState(() {
      if (_expandedCards.contains(cardId)) {
        _expandedCards.remove(cardId);
      } else {
        _expandedCards.add(cardId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppCubit.get(context).isDark;
    final localeCubit = context.read<LocaleCubit>();
    final isArabic = localeCubit.isArabic;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: LynSurface.surface(isDark),
        iconTheme: IconThemeData(
          color: LynSurface.textPrimary(isDark),
        ),
        title: Text(
          AppLocalizations.tr(context, 'api_documentation'),
          style: LynType.headline,
        ),
        centerTitle: true,
      ),
      body: Container(
        color: LynSurface.canvas(isDark),
        child: Builder(builder: (context) {
          _shown = 0;
          final cards = <Widget>[
            // ═══════════════════════════════════════════════════════
            // Header - API Base URL
            // ═══════════════════════════════════════════════════════
            _buildApiHeader(context, isDark, isArabic),
            
            const SizedBox(height: 24),
            
            // ═══════════════════════════════════════════════════════
            // Authentication API Documentation
            // ═══════════════════════════════════════════════════════
            _buildSectionHeader(context, isDark, 'Lynomia Chat API'),
            
            // Login API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'POST',
              title: isArabic ? 'تسجيل الدخول' : 'Login',
              description: isArabic 
                ? 'تسجيل الدخول للحصول على توكن الوصول ومعرف الحساب'
                : 'Login to get access token and account ID',
              endpoint: '/auth/sign_in',
              bodyType: 'JSON',
              parameters: [
                ApiParameter(
                  name: 'email',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'البريد الإلكتروني' : 'Email address',
                  example: 'user@example.com',
                ),
                ApiParameter(
                  name: 'password',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'كلمة المرور' : 'Password',
                  example: 'password123',
                ),
              ],
              response: isArabic 
                ? '''{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "account_id": 123,
    "pubsub_token": "abc123xyz",
    "id": 456
  }
}'''
                : '''{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "account_id": 123,
    "pubsub_token": "abc123xyz",
    "id": 456
  }
}''',
            ),
            
            // Google Login API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'POST',
              title: isArabic ? 'تسجيل الدخول بـ Google' : 'Google Login',
              description: isArabic 
                ? 'التسجيل أو تسجيل الدخول باستخدام حساب Google'
                : 'Register or login using Google account',
              endpoint: '/api/v1/mobile/auth/google',
              bodyType: 'JSON',
              parameters: [
                ApiParameter(
                  name: 'id_token',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'رمز معرف Google' : 'Google ID token',
                  example: 'eyJhbGciOiJSUzI1NiIs...',
                ),
              ],
              response: isArabic 
                ? '''{
  "data": {
    "id": 99,
    "name": "Ali",
    "email": "ali@gmail.com",
    "access_token": "me2VdirpCgHw...",
    "pubsub_token": "kGiaB2RdxcKy...",
    "new_user": false,
    "accounts": [
      { "id": 114, "name": "Ali Company", "role": "administrator" }
    ]
  }
}'''
                : '''{
  "data": {
    "id": 99,
    "name": "Ali",
    "email": "ali@gmail.com",
    "access_token": "me2VdirpCgHw...",
    "pubsub_token": "kGiaB2RdxcKy...",
    "new_user": false,
    "accounts": [
      { "id": 114, "name": "Ali Company", "role": "administrator" }
    ]
  }
}''',
            ),
            
            // Apple Login API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'POST',
              title: isArabic ? 'تسجيل الدخول بـ Apple' : 'Apple Login',
              description: isArabic 
                ? 'التسجيل أو تسجيل الدخول باستخدام حساب Apple'
                : 'Register or login using Apple account',
              endpoint: '/api/v1/mobile/auth/apple',
              bodyType: 'JSON',
              parameters: [
                ApiParameter(
                  name: 'identity_token',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'رمز معرف Apple' : 'Apple identity token',
                  example: 'eyJhbGciOiJSUzI1NiIs...',
                ),
                ApiParameter(
                  name: 'name',
                  type: 'String',
                  required: false,
                  description: isArabic ? 'اسم المستخدم (اختياري)' : 'User name (optional)',
                  example: 'Ali Ahmad',
                ),
              ],
              response: isArabic 
                ? '''{
  "data": {
    "id": 99,
    "name": "Ali",
    "email": "ali@gmail.com",
    "access_token": "me2VdirpCgHw...",
    "pubsub_token": "kGiaB2RdxcKy...",
    "new_user": false,
    "accounts": [
      { "id": 114, "name": "Ali Company", "role": "administrator" }
    ]
  }
}'''
                : '''{
  "data": {
    "id": 99,
    "name": "Ali",
    "email": "ali@gmail.com",
    "access_token": "me2VdirpCgHw...",
    "pubsub_token": "kGiaB2RdxcKy...",
    "new_user": false,
    "accounts": [
      { "id": 114, "name": "Ali Company", "role": "administrator" }
    ]
  }
}''',
            ),
            
            // Logout API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'POST',
              title: isArabic ? 'تسجيل الخروج' : 'Logout',
              description: isArabic 
                ? 'تسجيل الخروج من الجلسة الحالية وإلغاء صلاحية التوكن'
                : 'Logout from current session and invalidate the token',
              endpoint: '/auth/sign_out',
              bodyType: 'JSON',
              parameters: [
                ApiParameter(
                  name: 'api_access_token',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'رمز الوصول من تسجيل الدخول' : 'API access token from login',
                  example: 'me2VdirpCgHwV8meBSC8jn9k',
                ),
              ],
              response: isArabic 
                ? '''{
  "success": true,
  "message": "تم تسجيل الخروج بنجاح"
}'''
                : '''{
  "success": true,
  "message": "Logout successful"
}''',
            ),
            
            const SizedBox(height: 24),
            
            // ═══════════════════════════════════════════════════════
            // Chatwoot API Documentation
            // ═══════════════════════════════════════════════════════
            // _buildSectionHeader(context, isDark, 'Chatwoot API', isArabic),
            // const SizedBox(height: 16),
            
            // Create Contact API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'POST',
              title: isArabic ? 'إنشاء جهة اتصال' : 'Create Contact',
              description: isArabic 
                ? 'إنشاء جهة اتصال جديدة في النظام للحصول على معرف الاتصال وتوكن الاشتراك'
                : 'Create a new contact in the system to get contact ID and subscription token',
              endpoint: '/public/api/v1/inboxes/{inbox_identifier}/contacts',
              bodyType: 'JSON',
              parameters: [
                ApiParameter(
                  name: 'inbox_identifier',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'معرف صندوق الوارد' : 'Inbox identifier',
                  example: 'inbox_123',
                ),
                ApiParameter(
                  name: 'name',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'اسم جهة الاتصال' : 'Contact name',
                  example: 'John Doe',
                ),
                ApiParameter(
                  name: 'email',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'البريد الإلكتروني' : 'Email address',
                  example: 'john@example.com',
                ),
              ],
              response: isArabic 
                ? '''{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com",
  "pubsub_token": "abc123xyz",
  "source_id": "source_456"
}'''
                : '''{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com",
  "pubsub_token": "abc123xyz",
  "source_id": "source_456"
}''',
            ),
            
            // Get Conversations API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'GET',
              title: isArabic ? 'جلب المحادثات' : 'Get Conversations',
              description: isArabic 
                ? 'جلب جميع المحادثات لجهة اتصال محددة'
                : 'Retrieve all conversations for a specific contact',
              endpoint: '/public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations',
              parameters: [
                ApiParameter(
                  name: 'inbox_identifier',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'معرف صندوق الوارد' : 'Inbox identifier',
                  example: 'inbox_123',
                ),
                ApiParameter(
                  name: 'contact_identifier',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'معرف جهة الاتصال' : 'Contact identifier',
                  example: 'source_456',
                ),
              ],
              response: isArabic 
                ? '''[
  {
    "id": 789,
    "status": "open",
    "created_at": "2024-01-15T10:30:00Z"
  }
]'''
                : '''[
  {
    "id": 789,
    "status": "open",
    "created_at": "2024-01-15T10:30:00Z"
  }
]''',
            ),
            
            // Create Conversation API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'POST',
              title: isArabic ? 'إنشاء محادثة' : 'Create Conversation',
              description: isArabic 
                ? 'إنشاء محادثة جديدة لجهة اتصال محددة'
                : 'Create a new conversation for a specific contact',
              endpoint: '/public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations',
              bodyType: 'JSON',
              parameters: [
                ApiParameter(
                  name: 'inbox_identifier',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'معرف صندوق الوارد' : 'Inbox identifier',
                  example: 'inbox_123',
                ),
                ApiParameter(
                  name: 'contact_identifier',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'معرف جهة الاتصال' : 'Contact identifier',
                  example: 'source_456',
                ),
              ],
              response: isArabic 
                ? '''{
  "id": 789,
  "status": "open",
  "created_at": "2024-01-15T10:30:00Z"
}'''
                : '''{
  "id": 789,
  "status": "open",
  "created_at": "2024-01-15T10:30:00Z"
}''',
            ),
            
            // Send Message API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'POST',
              title: isArabic ? 'إرسال رسالة' : 'Send Message',
              description: isArabic 
                ? 'إرسال رسالة إلى محادثة محددة'
                : 'Send a message to a specific conversation',
              endpoint: '/public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}/messages',
              bodyType: 'JSON',
              parameters: [
                ApiParameter(
                  name: 'inbox_identifier',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'معرف صندوق الوارد' : 'Inbox identifier',
                  example: 'inbox_123',
                ),
                ApiParameter(
                  name: 'contact_identifier',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'معرف جهة الاتصال' : 'Contact identifier',
                  example: 'source_456',
                ),
                ApiParameter(
                  name: 'conversation_id',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'معرف المحادثة' : 'Conversation ID',
                  example: '789',
                ),
                ApiParameter(
                  name: 'content',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'محتوى الرسالة' : 'Message content',
                  example: 'Hello, how can I help you?',
                ),
                ApiParameter(
                  name: 'message_type',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'نوع الرسالة' : 'Message type',
                  example: 'incoming',
                ),
              ],
              response: isArabic 
                ? '''{
  "id": 101,
  "content": "Hello, how can I help you?",
  "message_type": "incoming",
  "created_at": "2024-01-15T10:35:00Z"
}'''
                : '''{
  "id": 101,
  "content": "Hello, how can I help you?",
  "message_type": "incoming",
  "created_at": "2024-01-15T10:35:00Z"
}''',
            ),
            
            // Get Messages API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'GET',
              title: isArabic ? 'جلب الرسائل' : 'Get Messages',
              description: isArabic 
                ? 'جلب جميع الرسائل في محادثة محددة'
                : 'Retrieve all messages in a specific conversation',
              endpoint: '/public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}/messages',
              parameters: [
                ApiParameter(
                  name: 'inbox_identifier',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'معرف صندوق الوارد' : 'Inbox identifier',
                  example: 'inbox_123',
                ),
                ApiParameter(
                  name: 'contact_identifier',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'معرف جهة الاتصال' : 'Contact identifier',
                  example: 'source_456',
                ),
                ApiParameter(
                  name: 'conversation_id',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'معرف المحادثة' : 'Conversation ID',
                  example: '789',
                ),
              ],
              response: isArabic 
                ? '''[
  {
    "id": 101,
    "content": "Hello",
    "message_type": "outgoing",
    "created_at": "2024-01-15T10:30:00Z"
  },
  {
    "id": 102,
    "content": "Hi there!",
    "message_type": "incoming",
    "created_at": "2024-01-15T10:31:00Z"
  }
]'''
                : '''[
  {
    "id": 101,
    "content": "Hello",
    "message_type": "outgoing",
    "created_at": "2024-01-15T10:30:00Z"
  },
  {
    "id": 102,
    "content": "Hi there!",
    "message_type": "incoming",
    "created_at": "2024-01-15T10:31:00Z"
  }
]''',
            ),
            
            const SizedBox(height: 24),
            
            // ═══════════════════════════════════════════════════════
            // Billing API Documentation
            // ═══════════════════════════════════════════════════════
            _buildSectionHeader(context, isDark, isArabic ? 'توثيق الفوترة' : 'Billing API'),
            
            // Fetch Plans API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'GET',
              title: isArabic ? 'جلب الخطط' : 'Fetch Plans',
              description: isArabic 
                ? 'جلب جميع خطط الاشتراك المتاحة'
                : 'Retrieve all available subscription plans',
              endpoint: '/api/v1/accounts/{accountId}/billing/plans',
              parameters: [
                ApiParameter(
                  name: 'api_access_token',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'رمز الوصول من تسجيل الدخول' : 'API access token from login',
                  example: 'me2VdirpCgHwV8meBSC8jn9k',
                ),
              ],
              response: isArabic 
                ? '''{
  "mobile_checkout_enabled": true,
  "plans": [
    {
      "id": 1,
      "name": "Starter",
      "description": "For small teams",
      "price": 19.99,
      "currency": "usd",
      "interval": "month",
      "pricing_type": "flat",
      "limits": { "agents": 10, "inboxes": 5 },
      "features": [
        { "name": "help_center", "display_name": "Help Center" },
        { "name": "reports", "display_name": "Reports" }
      ],
      "is_current": true
    }
  ]
}'''
                : '''{
  "mobile_checkout_enabled": true,
  "plans": [
    {
      "id": 1,
      "name": "Starter",
      "description": "For small teams",
      "price": 19.99,
      "currency": "usd",
      "interval": "month",
      "pricing_type": "flat",
      "limits": { "agents": 10, "inboxes": 5 },
      "features": [
        { "name": "help_center", "display_name": "Help Center" },
        { "name": "reports", "display_name": "Reports" }
      ],
      "is_current": true
    }
  ]
}''',
            ),
            
            // Fetch Entitlements API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'GET',
              title: isArabic ? 'جلب الحقوق والاشتراك' : 'Fetch Entitlements',
              description: isArabic 
                ? 'جلب الخطة الحالية، الحالة، والميزات المتاحة'
                : 'Retrieve current plan, status, and available features',
              endpoint: '/api/v1/accounts/{accountId}/billing/entitlements',
              parameters: [
                ApiParameter(
                  name: 'api_access_token',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'رمز الوصول من تسجيل الدخول' : 'API access token from login',
                  example: 'me2VdirpCgHwV8meBSC8jn9k',
                ),
              ],
              response: isArabic 
                ? '''{
  "active": true,
  "status": "trialing",
  "plan": { "id": 1, "name": "Starter" },
  "ends_at": "2026-10-12T07:43:32Z",
  "cancel_at_period_end": false,
  "is_admin": true,
  "mobile_checkout_enabled": true,
  "features": {
    "campaigns": false,
    "reports": true,
    "help_center": true
  },
  "limits": {
    "agents": { "used": 2, "limit": 10 },
    "inboxes": { "used": 4, "limit": 5 }
  }
}'''
                : '''{
  "active": true,
  "status": "trialing",
  "plan": { "id": 1, "name": "Starter" },
  "ends_at": "2026-10-12T07:43:32Z",
  "cancel_at_period_end": false,
  "is_admin": true,
  "mobile_checkout_enabled": true,
  "features": {
    "campaigns": false,
    "reports": true,
    "help_center": true
  },
  "limits": {
    "agents": { "used": 2, "limit": 10 },
    "inboxes": { "used": 4, "limit": 5 }
  }
}''',
            ),
            
            // Create Checkout URL API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'POST',
              title: isArabic ? 'إنشاء رابط الدفع' : 'Create Checkout URL',
              description: isArabic 
                ? 'إنشاء رابط الدفع للمتصفح الخارجي'
                : 'Create checkout URL for external browser',
              endpoint: '/api/v1/accounts/{accountId}/billing/checkout',
              bodyType: 'JSON',
              parameters: [
                ApiParameter(
                  name: 'api_access_token',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'رمز الوصول من تسجيل الدخول' : 'API access token from login',
                  example: 'me2VdirpCgHwV8meBSC8jn9k',
                ),
                ApiParameter(
                  name: 'plan_id',
                  type: 'Integer',
                  required: true,
                  description: isArabic ? 'معرف الخطة' : 'Plan ID',
                  example: '1',
                ),
                ApiParameter(
                  name: 'mobile',
                  type: 'Boolean',
                  required: true,
                  description: isArabic ? 'من الموبايل' : 'From mobile',
                  example: 'true',
                ),
              ],
              response: isArabic 
                ? '''{
  "url": "https://checkout.stripe.com/c/pay/cs_..."
}'''
                : '''{
  "url": "https://checkout.stripe.com/c/pay/cs_..."
}''',
            ),
            
            // Create Billing Portal URL API
            _buildApiCard(
              context: context,
              isDark: isDark,
              isArabic: isArabic,
              method: 'POST',
              title: isArabic ? 'إنشاء رابط إدارة الفوترة' : 'Create Billing Portal URL',
              description: isArabic 
                ? 'إنشاء رابط إدارة الفوترة للمتصفح الخارجي'
                : 'Create billing portal URL for external browser',
              endpoint: '/api/v1/accounts/{accountId}/billing/portal',
              bodyType: 'JSON',
              parameters: [
                ApiParameter(
                  name: 'mobile',
                  type: 'Boolean',
                  required: true,
                  description: isArabic ? 'من الموبايل' : 'From mobile',
                  example: 'true',
                ),
                ApiParameter(
                  name: 'api_access_token',
                  type: 'String',
                  required: true,
                  description: isArabic ? 'رمز الوصول من تسجيل الدخول' : 'API access token from login',
                  example: 'me2VdirpCgHwV8meBSC8jn9k',
                ),
              ],
              response: isArabic 
                ? '''{
  "url": "https://billing.stripe.com/..."
}'''
                : '''{
  "url": "https://billing.stripe.com/..."
}''',
            ),
            
          ];

          return ListView(
            padding: const EdgeInsets.all(LynSpace.lg),
            children: [
              _buildApiHeader(context, isDark, isArabic),
              const SizedBox(height: LynSpace.lg),
              _buildSearchField(isDark, isArabic),
              const SizedBox(height: LynSpace.lg),
              ...cards,
              if (_shown == 0) _buildNoMatches(isDark, isArabic),
              const SizedBox(height: LynSpace.xxl),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSearchField(bool isDark, bool isArabic) {
    return TextField(
      controller: _search,
      onChanged: (value) => setState(() => _query = value),
      style: LynType.body.copyWith(color: LynSurface.textPrimary(isDark)),
      decoration: InputDecoration(
        isDense: true,
        hintText: isArabic ? 'ابحث عن نقطة نهاية' : 'Search endpoints',
        hintStyle: LynType.body.copyWith(color: LynSurface.textTertiary(isDark)),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: LynSurface.textSecondary(isDark)),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: LynSurface.textSecondary(isDark)),
                onPressed: () {
                  _search.clear();
                  setState(() => _query = '');
                },
              ),
        filled: true,
        fillColor: LynSurface.surface(isDark),
        contentPadding: const EdgeInsets.symmetric(vertical: LynSpace.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LynSpace.md),
          borderSide: BorderSide(color: LynSurface.border(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LynSpace.md),
          borderSide: BorderSide(color: LynSurface.border(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LynSpace.md),
          borderSide: const BorderSide(color: LynPalette.indigo, width: 2),
        ),
      ),
    );
  }

  Widget _buildNoMatches(bool isDark, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LynSpace.xxl),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: LynSurface.textTertiary(isDark)),
          const SizedBox(height: LynSpace.md),
          Text(
            isArabic ? 'لا توجد نقطة نهاية بهذا الاسم' : 'No endpoint matches that',
            textAlign: TextAlign.center,
            style: LynType.body.copyWith(color: LynSurface.textSecondary(isDark)),
          ),
        ],
      ),
    );
  }

  /// Where the API lives.
  ///
  /// The gradient branched on `isDark` into two IDENTICAL stop pairs, and set white text and a
  /// white-tinted chip over the brand indigo — which the base URL then sat in at 70% white, under a
  /// monospace family that does not exist on iOS. The band is still the brand's; the URL is now
  /// copyable, which is the one thing anyone wants from it.
  Widget _buildApiHeader(BuildContext context, bool isDark, bool isArabic) {
    const url = 'https://chat.lynomia.com';

    return Container(
      padding: const EdgeInsets.all(LynSpace.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LynPalette.indigo, LynPalette.indigoDeep],
        ),
        borderRadius: BorderRadius.circular(LynSpace.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.api_rounded, color: Colors.white, size: 24),
              const SizedBox(width: LynSpace.md),
              Expanded(
                child: Text('Lynomia API',
                    style: LynType.headline.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: LynSpace.md),
          Material(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(LynSpace.sm),
            child: InkWell(
              borderRadius: BorderRadius.circular(LynSpace.sm),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.tr(context, 'Copied')),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(LynSpace.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        url,
                        // A URL is Latin in both languages and must not be reordered.
                        textDirection: TextDirection.ltr,
                        style: LynType.caption.copyWith(
                          // Was white at 70%: 3.7:1 on the indigo. Full white measures 5.3:1.
                          color: Colors.white,
                          fontFamily: kMonoFamily, fontFamilyFallback: kMonoFallback,
                        ),
                      ),
                    ),
                    const SizedBox(width: LynSpace.sm),
                    const Icon(Icons.copy_rounded, color: Colors.white, size: 15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: LynPalette.indigo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: LynType.headline.copyWith(
              color: LynSurface.textPrimary(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Does this endpoint answer what was typed into the search box?
  ///
  /// The reference is fifteen collapsed cards in one flat list with nothing to navigate by, so
  /// finding "the one that creates a conversation" meant opening them one at a time.
  bool _matches(String title, String endpoint, String description) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        endpoint.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q);
  }

  Widget _buildApiCard({
    required BuildContext context,
    required bool isDark,
    required bool isArabic,
    required String method,
    required String title,
    required String description,
    required String endpoint,
    String? bodyType,
    required List<ApiParameter> parameters,
    String? response,
  }) {
    if (!_matches(title, endpoint, description)) return const SizedBox.shrink();
    _shown++;

    final cardId = '$method-$title';
    final isExpanded = _expandedCards.contains(cardId);

    return Container(
      // The spacer between cards lives here rather than between the call sites, so a card the search
      // has filtered out leaves no gap behind it.
      margin: const EdgeInsets.only(bottom: LynSpace.md),
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        borderRadius: BorderRadius.circular(LynSpace.md),
        border: Border.all(color: LynSurface.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleCard(cardId),
            borderRadius: BorderRadius.circular(LynSpace.md),
            child: Padding(
              padding: const EdgeInsets.all(LynSpace.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ApiMethodBadge(method: method, isDark: isDark),
                  const SizedBox(width: LynSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: LynType.subtitle
                                .copyWith(color: LynSurface.textPrimary(isDark))),
                        const SizedBox(height: 2),
                        Text(
                          endpoint,
                          // The path is the thing a reader scans for, and it is Latin in both
                          // languages. It was only visible once the card was opened.
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LynType.caption.copyWith(
                            color: LynSurface.textSecondary(isDark),
                            fontFamily: kMonoFamily, fontFamilyFallback: kMonoFallback,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: LynSpace.sm),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: LynSurface.textSecondary(isDark),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, thickness: 1, color: LynSurface.border(isDark)),
            Padding(
              padding: const EdgeInsets.all(LynSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      style: LynType.body.copyWith(color: LynSurface.textSecondary(isDark))),
                  const SizedBox(height: LynSpace.lg),
                  if (bodyType != null) ...[
                    _buildSection(
                      isDark: isDark,
                      title: isArabic ? 'نوع الطلب' : 'Request type',
                      child: Text(bodyType,
                          textDirection: TextDirection.ltr,
                          style: LynType.caption.copyWith(
                            color: LynSurface.textPrimary(isDark),
                            fontFamily: kMonoFamily, fontFamilyFallback: kMonoFallback,
                          )),
                    ),
                    const SizedBox(height: LynSpace.lg),
                  ],
                  if (parameters.isNotEmpty) ...[
                    _buildSection(
                      isDark: isDark,
                      title: isArabic ? 'المعاملات' : 'Parameters',
                      child: Column(
                        children: [
                          for (final param in parameters)
                            ApiParameterRow(param: param, isDark: isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: LynSpace.lg),
                  ],
                  if (response != null)
                    _buildSection(
                      isDark: isDark,
                      title: isArabic ? 'الاستجابة' : 'Response',
                      child: ApiCodeBlock(code: response, isDark: isDark),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: LynType.micro.copyWith(color: LynSurface.textTertiary(isDark))),
        const SizedBox(height: LynSpace.sm),
        child,
      ],
    );
  }
}

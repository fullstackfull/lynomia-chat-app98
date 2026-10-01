import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../layout/cubit/cubit.dart';
import '../../modules/language/cubit/cubit.dart';
import '../../shared/app_localizations.dart';

class ApiDocumentationScreen extends StatefulWidget {
  const ApiDocumentationScreen({super.key});

  @override
  State<ApiDocumentationScreen> createState() => _ApiDocumentationScreenState();
}

class _ApiDocumentationScreenState extends State<ApiDocumentationScreen> {
  final Set<String> _expandedCards = {};

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
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF334155),
        ),
        title: Text(
          AppLocalizations.tr(context, 'api_documentation'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ═══════════════════════════════════════════════════════
            // Header - API Base URL
            // ═══════════════════════════════════════════════════════
            _buildApiHeader(context, isDark, isArabic),
            
            const SizedBox(height: 24),
            
            // ═══════════════════════════════════════════════════════
            // Authentication API Documentation
            // ═══════════════════════════════════════════════════════
            _buildSectionHeader(context, isDark, 'Lynomia Chat API'),
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 16),
            
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
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildApiHeader(BuildContext context, bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.api,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Lynomia API',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'https://chat.lynomia.com',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
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
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
    final cardId = '$method-$title';
    final isExpanded = _expandedCards.contains(cardId);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildMethodBadge(method),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  onPressed: () => _toggleCard(cardId),
                ),
              ],
            ),
          ),
          
          // Expanded content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Endpoint
                  _buildSection(
                    context: context,
                    isDark: isDark,
                    isArabic: isArabic,
                    title: isArabic ? 'نقطة النهاية' : 'Endpoint',
                    content: endpoint,
                    isCode: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Body Type (if applicable)
                  if (bodyType != null) ...[
                    _buildSection(
                      context: context,
                      isDark: isDark,
                      isArabic: isArabic,
                      title: isArabic ? 'نوع الطلب' : 'Request Type',
                      content: bodyType,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Parameters
                  _buildSection(
                    context: context,
                    isDark: isDark,
                    isArabic: isArabic,
                    title: isArabic ? 'المعاملات' : 'Parameters',
                    child: Column(
                      children: parameters.map((param) => _buildParameterItem(context, isDark, isArabic, param)).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Response (if applicable)
                  if (response != null) ...[
                    _buildSection(
                      context: context,
                      isDark: isDark,
                      isArabic: isArabic,
                      title: isArabic ? 'الاستجابة' : 'Response',
                      content: response,
                      isCode: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodBadge(String method) {
    Color bgColor;
    Color textColor;
    
    switch (method.toUpperCase()) {
      case 'GET':
        bgColor = const Color(0xFF10B981);
        textColor = Colors.white;
        break;
      case 'POST':
        bgColor = const Color(0xFFF59E0B);
        textColor = Colors.white;
        break;
      case 'PUT':
        bgColor = const Color(0xFF3B82F6);
        textColor = Colors.white;
        break;
      case 'DELETE':
        bgColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        break;
      default:
        bgColor = const Color(0xFF6B7280);
        textColor = Colors.white;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        method.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required bool isDark,
    required bool isArabic,
    required String title,
    String? content,
    Widget? child,
    bool isCode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (content != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCode
                  ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))
                  : (isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              content,
              style: TextStyle(
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                fontSize: isCode ? 12 : 14,
                fontFamily: isCode ? 'monospace' : null,
              ),
            ),
          ),
        if (child != null) child,
      ],
    );
  }

  Widget _buildParameterItem(BuildContext context, bool isDark, bool isArabic, ApiParameter param) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155).withOpacity(0.3) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                param.name,
                style: TextStyle(
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  param.type,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (param.required) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isArabic ? 'مطلوب' : 'required',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            param.description,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          if (param.example != null) ...[
            const SizedBox(height: 4),
            Text(
              '${isArabic ? 'مثال' : 'Example'}: ${param.example}',
              style: TextStyle(
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ApiParameter {
  final String name;
  final String type;
  final bool required;
  final String description;
  final String? example;

  ApiParameter({
    required this.name,
    required this.type,
    required this.required,
    required this.description,
    this.example,
  });
}
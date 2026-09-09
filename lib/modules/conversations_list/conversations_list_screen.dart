

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart' as intl;

import '../../layout/cubit/cubit.dart';
import '../../layout/cubit/states.dart';
import '../../models/chatwoot_models.dart';
import '../../shared/app_localizations.dart';
import '../../shared/components/components.dart';
import '../../shared/network/local/cache_helper.dart';
import '../chat/chat_screen.dart';
import '../login/login_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ جلب المحادثات عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppCubit>().fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is AppFetchConversationsErrorState) {
          CustomToast.show(
            context: context,
            message: state.error,
            state: ToastStates.error,
          );
        }
      },
      builder: (context, state) {
        final cubit = AppCubit.get(context);
        final isDark = cubit.isDark;
        final conversations = cubit.conversations;

        // ✅ إظهار زر إنشاء محادثة جديدة للبريد الإلكتروني والواتساب
        final selectedChannelType = cubit.selectedInbox?.channelType?.toLowerCase() ?? '';
        final isEmailInbox = selectedChannelType.contains('email') ||
            selectedChannelType.contains('gmail') ||
            selectedChannelType.contains('microsoft');
        final isWhatsAppInbox = selectedChannelType.contains('whatsapp');

        return Scaffold(
          backgroundColor: isDark ? HexColor('#0F172A') : HexColor('#F8FAFC'),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? HexColor('#1E293B') : HexColor('#FFFFFF'),
            title: Text(AppLocalizations.tr(context, 'conversations'),
              style: TextStyle(
                color: isDark ? Colors.white : HexColor('#1E293B'),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: state is AppFetchConversationsLoadingState && conversations.isEmpty
              ? _buildLoadingState()
              : conversations.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
            onRefresh: () => cubit.fetchConversations(),
            color: HexColor('#6366F1'),
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ConversationItem(
                  conversation: conversation,
                  isSelected: cubit.selectedConversation?.id == conversation.id,
                  isDark: isDark,
                  onTap: () {
                    cubit.selectConversation(conversation);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          floatingActionButton: isEmailInbox
              ? FloatingActionButton.extended(
            onPressed: () => _showNewConversationDialog(context),
            backgroundColor: HexColor('#6366F1'),
            icon: const Icon(Icons.edit, color: Colors.white),
            label: Text(
              AppLocalizations.tr(context, 'New Conversation'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          )
              : (isWhatsAppInbox
              ? FloatingActionButton.extended(
            onPressed: () => _showNewWhatsAppConversationDialog(context),
            backgroundColor: HexColor('#25D366'),
            icon: const Icon(Icons.chat, color: Colors.white),
            label: Text(
              AppLocalizations.tr(context, 'New WhatsApp Chat'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          )
              : null),
        );
      },
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final isDark = cubit.isDark;
    final inboxes = cubit.inboxes;

    if (inboxes.isEmpty) {
      cubit.fetchInboxes();
    }

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final messageController = TextEditingController();

    ChatwootInbox? selectedInbox;
    final formKey = GlobalKey<FormState>();

    // ✅ جديد: استخراج الاسم تلقائياً من الإيميل
    emailController.addListener(() {
      final email = emailController.text.trim();
      if (email.isNotEmpty && nameController.text.trim().isEmpty) {
        // استخراج الجزء قبل @
        final autoName = email.split('@').first;
        // تحويل النقاط والشرطات لمسافات وجعل الحرف الأول كبير
        final formattedName = autoName
            .replaceAll('.', ' ')
            .replaceAll('_', ' ')
            .replaceAll('-', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
            .join(' ')
            .trim();

        nameController.text = formattedName;
        // نقل المؤشر لنهاية النص
        nameController.selection = TextSelection.fromPosition(
          TextPosition(offset: nameController.text.length),
        );
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return BlocListener<AppCubit, AppStates>(
            listener: (context, state) {
              if (state is AppCreateConversationSuccessState) {
                Navigator.pop(context); // إغلاق الـ BottomSheet
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                );
              }
              if (state is AppCreateConversationErrorState) {
                CustomToast.show(
                  context: context,
                  message: state.error,
                  state: ToastStates.error,
                );
              }
            },
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? HexColor('#1E293B') : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? HexColor('#475569') : HexColor('#CBD5E1'),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                
                      Text(
                        AppLocalizations.tr(context, 'New Conversation'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : HexColor('#1E293B'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.tr(context, 'Start a new conversation via email'),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? HexColor('#94A3B8') : HexColor('#64748B'),
                        ),
                      ),
                      const SizedBox(height: 20),
                
                      // ✅ اختيار الـ Inbox (Email فقط)
                      if (inboxes.isNotEmpty)
                        DropdownButtonFormField<ChatwootInbox>(
                          value: selectedInbox,
                          isExpanded: true,
                          dropdownColor: isDark ? HexColor('#1E293B') : Colors.white,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.tr(context, 'Select Inbox'),
                            labelStyle: TextStyle(color: isDark ? HexColor('#94A3B8') : HexColor('#64748B')),
                            filled: true,
                            fillColor: isDark ? HexColor('#0F172A') : HexColor('#F8FAFC'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: inboxes.where((i) {
                            // ✅ نعرض فقط Email inboxes أو كلها حسب رغبتك
                            final type = i.channelType?.toLowerCase() ?? '';
                            return type.contains('email') || type.contains('gmail') || type.contains('microsoft');
                          }).map((inbox) {
                            return DropdownMenuItem(
                              value: inbox,
                              child: Text(
                                inbox.name ?? 'Inbox ${inbox.id}',
                                style: TextStyle(color: isDark ? Colors.white : HexColor('#1E293B')),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setModalState(() => selectedInbox = value),
                          validator: (value) => value == null
                              ? AppLocalizations.tr(context, 'Please select an inbox')
                              : null,
                        ),
                      if (inboxes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? HexColor('#334155') : HexColor('#F1F5F9'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircularProgressIndicator(color: HexColor('#6366F1'), strokeWidth: 2),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.tr(context, 'Loading inboxes...'),
                                style: TextStyle(color: isDark ? HexColor('#94A3B8') : HexColor('#64748B')),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                
                      // ✅ الاسم
                      TextFormField(
                        controller: nameController,
                        textAlign: TextAlign.right,
                        style: TextStyle(color: isDark ? Colors.white : HexColor('#1E293B')),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.tr(context, 'Contact Name'),
                          labelStyle: TextStyle(color: isDark ? HexColor('#94A3B8') : HexColor('#64748B')),
                          filled: true,
                          fillColor: isDark ? HexColor('#0F172A') : HexColor('#F8FAFC'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: HexColor('#6366F1'), width: 2),
                          ),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? AppLocalizations.tr(context, 'Name is required')
                            : null,
                      ),
                      const SizedBox(height: 12),
                
                      // ✅ البريد الإلكتروني
                      TextFormField(
                        controller: emailController,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: isDark ? Colors.white : HexColor('#1E293B')),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.tr(context, 'Email Address'),
                          labelStyle: TextStyle(color: isDark ? HexColor('#94A3B8') : HexColor('#64748B')),
                          filled: true,
                          fillColor: isDark ? HexColor('#0F172A') : HexColor('#F8FAFC'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: HexColor('#6366F1'), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.tr(context, 'Email is required');
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return AppLocalizations.tr(context, 'Invalid email');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                
                      // ✅ الهاتف (اختياري)
                      // TextFormField(
                      //   controller: phoneController,
                      //   textAlign: TextAlign.right,
                      //   keyboardType: TextInputType.phone,
                      //   style: TextStyle(color: isDark ? Colors.white : HexColor('#1E293B')),
                      //   decoration: InputDecoration(
                      //     labelText: '${AppLocalizations.tr(context, 'Phone')} (${AppLocalizations.tr(context, 'Optional')})',
                      //     labelStyle: TextStyle(color: isDark ? HexColor('#94A3B8') : HexColor('#64748B')),
                      //     filled: true,
                      //     fillColor: isDark ? HexColor('#0F172A') : HexColor('#F8FAFC'),
                      //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //       borderSide: BorderSide(color: HexColor('#6366F1'), width: 2),
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(height: 16),
                
                      // ✅ الرسالة الأولى
                      TextFormField(
                        controller: messageController,
                        textAlign: TextAlign.right,
                        maxLines: 4,
                        style: TextStyle(color: isDark ? Colors.white : HexColor('#1E293B')),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.tr(context, 'Message'),
                          labelStyle: TextStyle(color: isDark ? HexColor('#94A3B8') : HexColor('#64748B')),
                          filled: true,
                          fillColor: isDark ? HexColor('#0F172A') : HexColor('#F8FAFC'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: HexColor('#6366F1'), width: 2),
                          ),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? AppLocalizations.tr(context, 'Message is required')
                            : null,
                      ),
                      const SizedBox(height: 24),
                
                      // ✅ زر الإرسال
                      SizedBox(
                        width: double.infinity,
                        child: BlocBuilder<AppCubit, AppStates>(
                          builder: (context, state) {
                            final isLoading = state is AppCreateConversationLoadingState;
                            return ElevatedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                if (formKey.currentState!.validate() && selectedInbox != null) {
                                  cubit.createNewConversation(
                                    inboxId: selectedInbox!.id,
                                    contactName: nameController.text.trim(),
                                    contactEmail: emailController.text.trim(),
                                    contactPhone: phoneController.text.trim().isEmpty
                                        ? null
                                        : phoneController.text.trim(),
                                    initialMessage: messageController.text.trim(),
                                  );
                                }
                              },
                              icon: isLoading
                                  ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(Icons.send, color: Colors.white),
                              label: Text(
                                isLoading
                                    ? AppLocalizations.tr(context, 'Sending...')
                                    : AppLocalizations.tr(context, 'Send Message'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HexColor('#6366F1'),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNewWhatsAppConversationDialog(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final isDark = cubit.isDark;
    final inboxes = cubit.inboxes;

    if (inboxes.isEmpty) {
      cubit.fetchInboxes();
    }

    final whatsappInboxes = inboxes.where((i) {
      final type = i.channelType?.toLowerCase() ?? '';
      return type.contains('whatsapp');
    }).toList();

    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    ChatwootInbox? selectedInbox = cubit.selectedInbox != null &&
            (cubit.selectedInbox!.channelType?.toLowerCase().contains('whatsapp') ?? false)
        ? cubit.selectedInbox
        : (whatsappInboxes.isNotEmpty ? whatsappInboxes.first : null);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: isDark ? HexColor('#1E293B') : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HexColor('#25D366').withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chat, color: HexColor('#25D366'), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.tr(context, 'New WhatsApp Chat'),
                  style: TextStyle(
                    color: isDark ? Colors.white : HexColor('#1E293B'),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.tr(context, 'Select the sender WhatsApp number and recipient details'),
                    style: TextStyle(
                      color: isDark ? HexColor('#94A3B8') : HexColor('#64748B'),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (whatsappInboxes.isNotEmpty) ...[
                    DropdownButtonFormField<ChatwootInbox>(
                      value: selectedInbox,
                      isExpanded: true,
                      dropdownColor: isDark ? HexColor('#1E293B') : Colors.white,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.tr(context, 'Send From WhatsApp Number'),
                        labelStyle: TextStyle(color: HexColor('#25D366')),
                        prefixIcon: Icon(Icons.phone_android, color: HexColor('#25D366')),
                        filled: true,
                        fillColor: isDark ? HexColor('#0F172A') : HexColor('#F8FAFC'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: whatsappInboxes.map((inbox) {
                        return DropdownMenuItem(
                          value: inbox,
                          child: Text(
                            inbox.name ?? 'WhatsApp (${inbox.id})',
                            style: TextStyle(color: isDark ? Colors.white : HexColor('#1E293B')),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() => selectedInbox = value);
                        if (value != null) {
                          cubit.fetchWhatsAppTemplates(inboxId: value.id);
                        }
                      },
                      validator: (value) => value == null
                          ? AppLocalizations.tr(context, 'Please select an inbox')
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: isDark ? Colors.white : HexColor('#1E293B')),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.tr(context, 'WhatsApp Number (with country code)'),
                      hintText: '+1234567890',
                      prefixIcon: Icon(Icons.send_to_mobile, color: HexColor('#25D366')),
                      filled: true,
                      fillColor: isDark ? HexColor('#0F172A') : HexColor('#F8FAFC'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppLocalizations.tr(context, 'Please enter a valid phone number');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    style: TextStyle(color: isDark ? Colors.white : HexColor('#1E293B')),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.tr(context, 'Contact Name (Optional)'),
                      prefixIcon: Icon(Icons.person, color: HexColor('#64748B')),
                      filled: true,
                      fillColor: isDark ? HexColor('#0F172A') : HexColor('#F8FAFC'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? HexColor('#451A1A') : HexColor('#FEE2E2'),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: HexColor('#FCA5A5'), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: HexColor('#EF4444'), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.tr(context, 'Starting a new WhatsApp chat requires sending a WhatsApp template message first.'),
                            style: TextStyle(
                              color: isDark ? HexColor('#FCA5A5') : HexColor('#991B1B'),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                AppLocalizations.tr(context, 'cancel'),
                style: TextStyle(color: isDark ? HexColor('#94A3B8') : HexColor('#64748B')),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate() || selectedInbox == null) return;
                Navigator.pop(dialogContext);

                await cubit.createNewWhatsAppConversation(
                  inboxId: selectedInbox!.id,
                  contactPhone: phoneController.text.trim(),
                  contactName: nameController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                }
              },
              icon: const Icon(Icons.send, size: 18),
              label: Text(AppLocalizations.tr(context, 'Select Template & Send')),
              style: ElevatedButton.styleFrom(
                backgroundColor: HexColor('#25D366'),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: HexColor('#6366F1'),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: isDark ? HexColor('#334155') : HexColor('#CBD5E1'),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.tr(context, 'No conversations'),
            style: TextStyle(
              color: isDark ? HexColor('#64748B') : HexColor('#94A3B8'),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

}


class ConversationItem extends StatelessWidget {
  final ChatwootConversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const ConversationItem({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final contactName = conversation.contactName ?? AppLocalizations.tr(context, 'Unknown');
    final lastMessage = conversation.lastMessageContent ?? '';
    final lastAt = conversation.lastMessageAt;
    final timeText = lastAt != null
        ? _formatTime(context, lastAt)
        : '';
    final unreadCount = conversation.unreadCount ?? 0;
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? HexColor('#6366F1').withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isDark ? HexColor('#1E293B') : HexColor('#E2E8F0'),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // ✅ صورة الملف الشخصي مع مؤشر الاتصال
            Stack(
              children: [
                _buildAvatar(conversation.contactAvatar, contactName, isDark),
                // ✅ مؤشر الاتصال (Online)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: HexColor('#22C55E'),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? HexColor('#1E293B') : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // ✅ معلومات المحادثة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // اسم المرسل - bold إذا غير مقروء
                      Expanded(
                        child: Text(
                          contactName,
                          style: TextStyle(
                            color: isDark ? Colors.white : HexColor('#1E293B'),
                            fontSize: 16,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // الوقت - أزرق إذا غير مقروء
                      Text(
                        timeText,
                        style: TextStyle(
                          color: hasUnread
                              ? HexColor('#6366F1')
                              : isDark
                              ? HexColor('#64748B')
                              : HexColor('#94A3B8'),
                          fontSize: 12,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // ✅ آخر رسالة - semi-bold إذا غير مقروء
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            color: hasUnread
                                ? (isDark ? Colors.white : HexColor('#1E293B'))
                                : (isDark ? HexColor('#94A3B8') : HexColor('#64748B')),
                            fontSize: 14,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // ✅ عدد الرسائل غير المقروءة
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: HexColor('#6366F1'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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
  // Avatar Widget - مع دعم الصورة من URL
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAvatar(String? avatarUrl, String contactName, bool isDark) {
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: hasAvatar ? null : HexColor('#6366F1').withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey,width: 2),
        image: hasAvatar
            ? DecorationImage(
          image: NetworkImage(avatarUrl),
          fit: BoxFit.contain,
          onError: (_, __) {},
        )
            : null,
      ),
      child: !hasAvatar
          ? Center(
        child: Text(
          contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
          style: TextStyle(
            color: HexColor('#6366F1'),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      )
          : null,
    );
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(localDate.year, localDate.month, localDate.day);
    final diffDays = today.difference(msgDate).inDays;

    if (diffDays == 0) {
      final hour = localDate.hour.toString().padLeft(2, '0');
      final minute = localDate.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diffDays == 1) {
      return AppLocalizations.tr(context, 'Yesterday');
    } else if (diffDays < 7 && diffDays > 0) {
      final days = [
        AppLocalizations.tr(context, 'Monday'),
        AppLocalizations.tr(context, 'Tuesday'),
        AppLocalizations.tr(context, 'Wednesday'),
        AppLocalizations.tr(context, 'Thursday'),
        AppLocalizations.tr(context, 'Friday'),
        AppLocalizations.tr(context, 'Saturday'),
        AppLocalizations.tr(context, 'Sunday'),
      ];
      final dayIndex = (localDate.weekday - 1) % 7;
      return days[dayIndex];
    } else {
      final day = localDate.day.toString().padLeft(2, '0');
      final month = localDate.month.toString().padLeft(2, '0');
      return '$day/$month/${localDate.year}';
    }
  }
}

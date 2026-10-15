

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart' as intl;

import '../../layout/cubit/cubit.dart';
import '../../layout/cubit/states.dart';
import '../../models/chatwoot_models.dart';
import '../../shared/app_localizations.dart';
import '../../shared/components/components.dart';
import '../chat/chat_screen.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';

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
          backgroundColor: LynSurface.canvas(isDark),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: LynSurface.surface(isDark),
            scrolledUnderElevation: 0,
            shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
            title: Text(
              cubit.selectedInbox?.name ?? AppLocalizations.tr(context, 'conversations'),
              style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
            ),
          ),
          body: state is AppFetchConversationsLoadingState && conversations.isEmpty
              ? _buildLoadingState()
              : conversations.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
            onRefresh: () => cubit.fetchConversations(),
            color: LynPalette.indigo,
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
            backgroundColor: LynPalette.indigo,
            icon: const Icon(Icons.edit, color: Colors.white),
            label: Text(
              AppLocalizations.tr(context, 'New Conversation'),
              style: LynType.callout.copyWith(color: Colors.white),
            ),
          )
              : (isWhatsAppInbox
              ? FloatingActionButton.extended(
            onPressed: () => _showNewWhatsAppConversationDialog(context),
            backgroundColor: HexColor('#25D366'),
            icon: const Icon(Icons.chat, color: Colors.white),
            label: Text(
              AppLocalizations.tr(context, 'New WhatsApp Chat'),
              style: LynType.callout.copyWith(color: Colors.white),
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
                color: LynSurface.surface(isDark),
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
                            color: LynSurface.borderStrong(isDark),
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
                          color: LynSurface.textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.tr(context, 'Start a new conversation via email'),
                        style: TextStyle(
                          fontSize: 14,
                          color: LynSurface.textSecondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 20),
                
                      // ✅ اختيار الـ Inbox (Email فقط)
                      if (inboxes.isNotEmpty)
                        DropdownButtonFormField<ChatwootInbox>(
                          value: selectedInbox,
                          isExpanded: true,
                          dropdownColor: LynSurface.surface(isDark),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.tr(context, 'Select Inbox'),
                            labelStyle: TextStyle(color: LynSurface.textSecondary(isDark)),
                            filled: true,
                            fillColor: LynSurface.canvas(isDark),
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
                                style: TextStyle(color: LynSurface.textPrimary(isDark)),
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
                            color: LynSurface.surfaceMuted(isDark),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircularProgressIndicator(color: LynPalette.indigo, strokeWidth: 2),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.tr(context, 'Loading inboxes...'),
                                style: TextStyle(color: LynSurface.textSecondary(isDark)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                
                      // ✅ الاسم
                      TextFormField(
                        controller: nameController,
                        textAlign: TextAlign.right,
                        style: TextStyle(color: LynSurface.textPrimary(isDark)),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.tr(context, 'Contact Name'),
                          labelStyle: TextStyle(color: LynSurface.textSecondary(isDark)),
                          filled: true,
                          fillColor: LynSurface.canvas(isDark),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: LynPalette.indigo, width: 2),
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
                        style: TextStyle(color: LynSurface.textPrimary(isDark)),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.tr(context, 'Email Address'),
                          labelStyle: TextStyle(color: LynSurface.textSecondary(isDark)),
                          filled: true,
                          fillColor: LynSurface.canvas(isDark),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: LynPalette.indigo, width: 2),
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
                      //   style: TextStyle(color: LynSurface.textPrimary(isDark)),
                      //   decoration: InputDecoration(
                      //     labelText: '${AppLocalizations.tr(context, 'Phone')} (${AppLocalizations.tr(context, 'Optional')})',
                      //     labelStyle: TextStyle(color: LynSurface.textSecondary(isDark)),
                      //     filled: true,
                      //     fillColor: LynSurface.canvas(isDark),
                      //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //       borderSide: BorderSide(color: LynPalette.indigo, width: 2),
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(height: 16),
                
                      // ✅ الرسالة الأولى
                      TextFormField(
                        controller: messageController,
                        textAlign: TextAlign.right,
                        maxLines: 4,
                        style: TextStyle(color: LynSurface.textPrimary(isDark)),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.tr(context, 'Message'),
                          labelStyle: TextStyle(color: LynSurface.textSecondary(isDark)),
                          filled: true,
                          fillColor: LynSurface.canvas(isDark),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: LynPalette.indigo, width: 2),
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
                                backgroundColor: LynPalette.indigo,
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
          backgroundColor: LynSurface.surface(isDark),
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
                    color: LynSurface.textPrimary(isDark),
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
                      color: LynSurface.textSecondary(isDark),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (whatsappInboxes.isNotEmpty) ...[
                    DropdownButtonFormField<ChatwootInbox>(
                      value: selectedInbox,
                      isExpanded: true,
                      dropdownColor: LynSurface.surface(isDark),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.tr(context, 'Send From WhatsApp Number'),
                        labelStyle: TextStyle(color: HexColor('#25D366')),
                        prefixIcon: Icon(Icons.phone_android, color: HexColor('#25D366')),
                        filled: true,
                        fillColor: LynSurface.canvas(isDark),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: whatsappInboxes.map((inbox) {
                        return DropdownMenuItem(
                          value: inbox,
                          child: Text(
                            inbox.name ?? 'WhatsApp (${inbox.id})',
                            style: TextStyle(color: LynSurface.textPrimary(isDark)),
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
                    style: TextStyle(color: LynSurface.textPrimary(isDark)),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.tr(context, 'WhatsApp Number (with country code)'),
                      hintText: '+1234567890',
                      prefixIcon: Icon(Icons.send_to_mobile, color: HexColor('#25D366')),
                      filled: true,
                      fillColor: LynSurface.canvas(isDark),
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
                    style: TextStyle(color: LynSurface.textPrimary(isDark)),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.tr(context, 'Contact Name (Optional)'),
                      prefixIcon: Icon(Icons.person, color: HexColor('#64748B')),
                      filled: true,
                      fillColor: LynSurface.canvas(isDark),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: LynSurface.dangerSurface(isDark),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LynPalette.dangerSoft, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: LynPalette.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.tr(context, 'Starting a new WhatsApp chat requires sending a WhatsApp template message first.'),
                            style: TextStyle(
                              color: LynSurface.dangerText(isDark),
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
                style: TextStyle(color: LynSurface.textSecondary(isDark)),
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
        color: LynPalette.indigo,
      ),
    );
  }

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
            child: Icon(Icons.forum_outlined, size: 32, color: LynPalette.indigo),
          ),
          const SizedBox(height: LynSpace.xl),
          Text(
            AppLocalizations.tr(context, 'No conversations'),
            style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
          ),
          const SizedBox(height: LynSpace.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LynSpace.xxl),
            child: Text(
              AppLocalizations.tr(context, 'no_conversations_hint'),
              textAlign: TextAlign.center,
              style: LynType.callout.copyWith(color: LynSurface.textSecondary(isDark)),
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
        padding: const EdgeInsets.symmetric(horizontal: LynSpace.lg, vertical: LynSpace.md),
        decoration: BoxDecoration(
          color: isSelected ? LynPalette.indigo.withOpacity(0.08) : Colors.transparent,
          border: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
        ),
        child: Row(
          children: [
            // There used to be a green dot on the corner of every avatar here, unconditionally. It
            // looked like presence and it was a constant: nothing in `ChatwootConversation` carries
            // whether a contact is online, so it told every agent that every customer was available,
            // always. The conversation's own `status` IS real and was shown nowhere, so that is what
            // the row carries now.
            _buildAvatar(conversation.contactAvatar, contactName, isDark),
            const SizedBox(width: LynSpace.md),

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
                          style: LynType.subtitle.copyWith(
                            color: LynSurface.textPrimary(isDark),
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: LynSpace.sm),
                      Text(
                        timeText,
                        style: LynType.caption.copyWith(
                          // The unread time used to measure 3.1:1 against the row; the secondary tone
                          // is 5.9:1 and the indigo carries the unread signal on its own.
                          color: hasUnread ? LynPalette.indigo : LynSurface.textSecondary(isDark),
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: LynType.callout.copyWith(
                            color: hasUnread
                                ? (LynSurface.textPrimary(isDark))
                                : (LynSurface.textSecondary(isDark)),
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ..._statusChip(context),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsetsDirectional.only(start: LynSpace.sm),
                          padding: const EdgeInsets.symmetric(
                              horizontal: LynSpace.sm, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 20),
                          decoration: BoxDecoration(
                            color: LynPalette.indigo,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            textAlign: TextAlign.center,
                            style: LynType.micro.copyWith(color: Colors.white),
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

  /// The conversation's own state, shown only when it is not the ordinary one.
  ///
  /// "Open" is what almost every row is, so chipping it would put the same word down the whole list
  /// and say nothing. Resolved, pending and snoozed are the ones an agent needs to see at a glance.
  List<Widget> _statusChip(BuildContext context) {
    final status = conversation.status?.toLowerCase();
    if (status == null || status.isEmpty || status == 'open') return const <Widget>[];

    final Color surface;
    final Color ink;
    switch (status) {
      case 'resolved':
        surface = LynSurface.successSurface(isDark);
        ink = LynSurface.successText(isDark);
        break;
      case 'pending':
      case 'snoozed':
        surface = LynPalette.warning.withOpacity(isDark ? 0.18 : 0.12);
        ink = isDark ? LynPalette.warningSoft : LynPalette.warningInk;
        break;
      default:
        surface = LynSurface.surfaceMuted(isDark);
        ink = LynSurface.textSecondary(isDark);
    }

    return <Widget>[
      Container(
        margin: const EdgeInsetsDirectional.only(start: LynSpace.sm),
        padding: const EdgeInsets.symmetric(horizontal: LynSpace.sm, vertical: 1),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(999)),
        child: Text(
          AppLocalizations.tr(context, 'conversation_status_$status'),
          style: LynType.micro.copyWith(color: ink),
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════
  // Avatar Widget - مع دعم الصورة من URL
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAvatar(String? avatarUrl, String contactName, bool isDark) {
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: hasAvatar ? null : LynPalette.indigo.withOpacity(isDark ? 0.22 : 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: LynSurface.border(isDark)),
        image: hasAvatar
            ? DecorationImage(
          // `contain` letterboxed a rectangular photo inside the circle, leaving bars; `cover` fills
          // it. The cached provider is the one the chat screen's avatars already use, so scrolling
          // this list does not re-fetch the same faces.
          image: CachedNetworkImageProvider(avatarUrl),
          fit: BoxFit.cover,
          onError: (_, __) {},
        )
            : null,
      ),
      child: !hasAvatar
          ? Center(
        child: Text(
          contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
          style: LynType.subtitle.copyWith(color: LynPalette.indigo, height: 1),
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

    // `intl` already has every locale's clock, weekday and date order; the hand-rolled versions of
    // these printed a 24-hour clock to an English user and dd/MM/yyyy to everyone, in both scripts.
    final locale = Localizations.localeOf(context).toString();
    if (diffDays == 0) return intl.DateFormat.jm(locale).format(localDate);
    if (diffDays == 1) return AppLocalizations.tr(context, 'Yesterday');
    if (diffDays > 0 && diffDays < 7) return intl.DateFormat.EEEE(locale).format(localDate);
    return intl.DateFormat.yMd(locale).format(localDate);
  }
}

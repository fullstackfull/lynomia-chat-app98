import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../layout/cubit/cubit.dart';
import '../../layout/cubit/states.dart';
import '../../models/chatwoot_models.dart';
import '../../shared/app_localizations.dart';
import '../../shared/components/components.dart';
import '../../shared/components/custom_toast.dart';
import '../chat/chat_screen.dart';
import '../conversations_list/conversations_list_screen.dart';
import '../login/login_screen.dart';
import '../../shared/styles/lyn_palette.dart';

class InboxSelectionScreen extends StatefulWidget {
  const InboxSelectionScreen({super.key});

  @override
  State<InboxSelectionScreen> createState() => _InboxSelectionScreenState();
}

class _InboxSelectionScreenState extends State<InboxSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // جلب inboxes عند فتح الشاشة (سيتم استخدام account_id من login response)
    Future.delayed(Duration.zero, () {
      context.read<AppCubit>().fetchInboxes();
    });
  }

  void _selectInbox(ChatwootInbox inbox) {
    context.read<AppCubit>().selectInbox(inbox);


    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConversationsScreen()),
    );
  }

  void _showLogoutDialog(BuildContext context, AppCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LynSurface.surface(cubit.isDark),
        title: Text(
          'تسجيل الخروج',
          style: TextStyle(
            color: LynSurface.textPrimary(cubit.isDark),
          ),
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: TextStyle(
            color: LynSurface.textSecondary(cubit.isDark),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: HexColor('#64748B')),
            ),
          ),
          TextButton(
            onPressed: () {
              cubit.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            child: Text(
              'تسجيل الخروج',
              style: TextStyle(color: LynPalette.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is AppFetchInboxesErrorState) {
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
        final inboxes = cubit.inboxes;

        return RefreshIndicator(
          onRefresh: ()=> context.read<AppCubit>().fetchInboxes(),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: LynSurface.canvas(isDark),
              elevation: 0,
              centerTitle: true,
              title: Text(
                AppLocalizations.tr(context, 'Select Inbox'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: LynSurface.textPrimary(isDark),
                ),
              ),
            ),
            body: state is AppFetchInboxesLoadingState
                ? Center(
                    child: CircularProgressIndicator(
                      color: LynPalette.indigo,
                    ),
                  )
                : inboxes.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildInboxList(inboxes, isDark),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: LynSurface.borderStrong(isDark),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.tr(context, 'No Inboxes'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: LynSurface.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(AppLocalizations.tr(context, 'Make sure you have access permissions'),
            style: TextStyle(
              fontSize: 14,
              color: LynSurface.textTertiary(isDark),
            ),
          ),
          const SizedBox(height: 24),
          defaultButton(
            function: () {
              context.read<AppCubit>().fetchInboxes();
            },
            text: AppLocalizations.tr(context, 'Retry'),
            isUpperCase: false,
            radius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildInboxList(List<ChatwootInbox> inboxes, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inboxes.length,
      itemBuilder: (context, index) {
        final inbox = inboxes[index];
        return _buildInboxCard(inbox, isDark);
      },
    );
  }

  Widget _buildInboxCard(ChatwootInbox inbox, bool isDark) {
    // ✅ عرض فقط inboxes المفعلة
    if (inbox.enabled == false) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: LynSurface.surface(isDark),
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: LynSurface.border(isDark),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectInbox(inbox),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getChannelColor(inbox.channelType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getChannelIcon(inbox.channelType),
                  size: 28,
                  color: _getChannelColor(inbox.channelType),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inbox.name ?? 'Inbox ${inbox.id}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: LynSurface.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getChannelIcon(inbox.channelType),
                          size: 14,
                          color: LynSurface.textSecondary(isDark),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getChannelDisplayName(context, inbox.channelType),
                          style: TextStyle(
                            fontSize: 14,
                            color: LynSurface.textSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new,
                color: LynSurface.textTertiary(isDark),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getChannelIcon(String? channelType) {
    switch (channelType?.toLowerCase()) {
      case 'web':
      case 'website':
        return Icons.language;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.alternate_email;
      case 'whatsapp':
        return Icons.message;
      case 'email':
        return Icons.email;
      case 'telegram':
        return Icons.send;
      case 'line':
        return Icons.chat;
      case 'sms':
        return Icons.sms;
      case 'api':
        return Icons.api;
      default:
        return Icons.inbox;
    }
  }

  Color _getChannelColor(String? channelType) {
    switch (channelType?.toLowerCase()) {
      case 'web':
      case 'website':
        return HexColor('#3B82F6'); // Blue
      case 'facebook':
        return HexColor('#1877F2'); // Facebook Blue
      case 'twitter':
        return HexColor('#1DA1F2'); // Twitter Blue
      case 'whatsapp':
        return HexColor('#25D366'); // WhatsApp Green
      case 'email':
        return LynPalette.warning; // Amber
      case 'telegram':
        return HexColor('#0088CC'); // Telegram Blue
      case 'line':
        return HexColor('#00B900'); // LINE Green
      case 'sms':
        return HexColor('#8B5CF6'); // Purple
      case 'api':
        return LynPalette.indigo; // Indigo
      default:
        return HexColor('#64748B'); // Gray
    }
  }

  String _getChannelDisplayName(BuildContext context, String? channelType) {
    switch (channelType?.toLowerCase()) {
      case 'web': case 'website': return AppLocalizations.tr(context, 'Website');
      case 'facebook': return AppLocalizations.tr(context, 'Facebook');
      case 'twitter': return AppLocalizations.tr(context, 'Twitter');
      case 'whatsapp': return AppLocalizations.tr(context, 'WhatsApp');
      case 'email': return AppLocalizations.tr(context, 'Email');
      case 'telegram': return AppLocalizations.tr(context, 'Telegram');
      case 'line': return AppLocalizations.tr(context, 'LINE');
      case 'sms': return AppLocalizations.tr(context, 'SMS');
      case 'api': return AppLocalizations.tr(context, 'API');
      default: return channelType ?? AppLocalizations.tr(context, 'Unknown');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout/cubit/cubit.dart';
import '../../layout/cubit/states.dart';
import '../../models/chatwoot_models.dart';
import '../../shared/app_localizations.dart';
import '../../shared/components/components.dart';
import '../../shared/components/custom_toast.dart';
import '../conversations_list/conversations_list_screen.dart';
import '../../shared/styles/lyn_channel.dart';
import '../../shared/styles/lyn_controls.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';

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
              backgroundColor: LynSurface.surface(isDark),
              elevation: 0,
              scrolledUnderElevation: 0,
              shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
              centerTitle: true,
              iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
              title: Text(
                AppLocalizations.tr(context, 'Select Inbox'),
                style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: LynPalette.indigo.withOpacity(isDark ? 0.16 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_rounded, size: 32, color: LynPalette.indigo),
          ),
          const SizedBox(height: LynSpace.xl),
          Text(AppLocalizations.tr(context, 'No Inboxes'),
            style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
          ),
          const SizedBox(height: LynSpace.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LynSpace.xxl),
            child: Text(AppLocalizations.tr(context, 'Make sure you have access permissions'),
              textAlign: TextAlign.center,
              style: LynType.callout.copyWith(color: LynSurface.textSecondary(isDark)),
            ),
          ),
          const SizedBox(height: LynSpace.xl),
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
    // Disabled inboxes are dropped BEFORE the builder. Returning a zero-height widget from inside it,
    // as this did, still produced an item: the list reported a count it did not draw, and the
    // separators and scroll extent counted rows nobody could see.
    final visible = inboxes.where((inbox) => inbox.enabled != false).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(LynSpace.lg),
      itemCount: visible.length,
      itemBuilder: (context, index) => _buildInboxCard(visible[index], isDark),
    );
  }

  Widget _buildInboxCard(ChatwootInbox inbox, bool isDark) {
    final accent = LynChannel.color(inbox.channelType);

    return Padding(
      padding: const EdgeInsets.only(bottom: LynSpace.md),
      child: Material(
        color: LynSurface.surface(isDark),
        borderRadius: BorderRadius.circular(LynSpace.lg),
        child: InkWell(
          onTap: () => _selectInbox(inbox),
          borderRadius: BorderRadius.circular(LynSpace.lg),
          child: Container(
            padding: const EdgeInsets.all(LynSpace.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LynSpace.lg),
              border: Border.all(color: LynSurface.border(isDark)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(LynSpace.md),
                  ),
                  child: Icon(LynChannel.icon(inbox.channelType), size: 24, color: accent),
                ),
                const SizedBox(width: LynSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        inbox.name ?? 'Inbox ${inbox.id}',
                        style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // The channel icon used to be repeated here at 14px beside its own name, under
                      // the 28px version of itself. One is enough.
                      Text(
                        LynChannel.label(context, inbox.channelType),
                        style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: LynSpace.sm),
                // Was `Icons.arrow_back_ios_new`: a "go to this inbox" affordance pointing backwards.
                LynChevron(color: LynSurface.borderStrong(isDark), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }



}

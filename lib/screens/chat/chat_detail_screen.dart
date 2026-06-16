import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/user_avatar.dart';

class ChatDetailScreen extends StatefulWidget {
  final int conversationId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final content = TextEditingController();
  final scrollController = ScrollController();

  Timer? timer;
  bool polling = false;
  bool sending = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadMessages();
      _scrollToBottom();

      if (!mounted) return;

      final data = context.read<AppDataProvider>();
      final conversation = _findConversation(data);

      if (conversation != null) {
        for (final id in conversation.userIds) {
          data.loadUserName(id);
        }
      }
    });

    timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    content.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (polling) return;

    polling = true;

    try {
      await context.read<AppDataProvider>().loadMessages(widget.conversationId);

      if (!mounted) return;

      _scrollToBottom();
    } catch (_) {
      final warning = context.read<AppDataProvider>().error;

      if (mounted && warning == AppDataProvider.restrictedChatWarning) {
        final t = AppStrings.of(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.restrictedChatWarning),
          ),
        );
      }
    } finally {
      polling = false;
    }
  }

  Future<void> _sendMessage() async {
    final text = content.text.trim();

    if (text.isEmpty || sending) return;

    setState(() {
      sending = true;
    });

    try {
      final data = context.read<AppDataProvider>();
      final conversation = _findConversation(data);
      final shouldBlock = await data.shouldBlockRestrictedChatMessage(
        conversation: conversation,
        content: text,
      );

      if (shouldBlock) {
        data.showRestrictedChatWarning();

        if (mounted) {
          final t = AppStrings.of(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.restrictedChatWarning),
            ),
          );
        }

        return;
      }

      await data.sendMessage(
        widget.conversationId,
        text,
      );

      if (!mounted) return;

      content.clear();
      _scrollToBottom();
    } catch (_) {
      // ErrorBanner will show provider error.
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  ConversationModel? _findConversation(AppDataProvider data) {
    for (final conversation in data.conversations) {
      if (conversation.conversationId == widget.conversationId) {
        return conversation;
      }
    }

    return null;
  }

  String _conversationTitle(
    AppDataProvider data,
    ConversationModel? conversation,
  ) {
    if (conversation == null) {
      return 'Conversation #${widget.conversationId}';
    }

    if (conversation.otherUserName.trim().isNotEmpty) {
      return conversation.otherUserName.trim();
    }

    final otherIds =
        conversation.userIds.where((id) => id != data.profile?.userId).toList();

    if (otherIds.isEmpty) {
      return 'Conversation #${widget.conversationId}';
    }

    return otherIds.map((id) => data.userName(id)).join(', ');
  }

  String? _otherAvatarUrl(ConversationModel? conversation) {
    final value = conversation?.otherUserAvatarUrl?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final auth = context.watch<AuthProvider>();

    final conversation = _findConversation(data);
    final titleName = _conversationTitle(data, conversation);
    final otherRole = conversation?.otherUserRole.trim() ?? '';
    final otherAvatarUrl = _otherAvatarUrl(conversation);

    final messages = data.messages[widget.conversationId] ?? [];
    final formatter = DateFormat('HH:mm');

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              imageUrl: otherAvatarUrl,
              name: titleName,
              radius: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (otherRole.isNotEmpty)
                    Text(
                      t.role(otherRole),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.outlined(
              onPressed: data.loading ? null : () => _loadMessages(),
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(
                side: BorderSide(
                  color: colors.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(
            height: 0.5,
            thickness: 0.5,
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: Column(
        children: [
          ErrorBanner(data.error),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadMessages(),
              child: messages.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 160),
                        Column(
                          children: [
                            UserAvatar(
                              imageUrl: otherAvatarUrl,
                              name: titleName,
                              radius: 34,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t.noMessagesYet,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Start the conversation 👋',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];

                        final mine = auth.userId != null &&
                            message.userId == auth.userId;

                        final senderName = mine
                            ? t.you
                            : _senderName(
                                data: data,
                                conversation: conversation,
                                messageUserId: message.userId,
                              );

                        return _MessageRow(
                          mine: mine,
                          message: message.content,
                          senderName: senderName,
                          avatarUrl: mine ? null : otherAvatarUrl,
                          time: formatter.format(message.createdAt.toLocal()),
                        );
                      },
                    ),
            ),
          ),
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: content,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: t.messageHint,
                        filled: true,
                        fillColor: colors.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colors.outlineVariant,
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colors.outlineVariant,
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: sending ? null : _sendMessage,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(50, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _senderName({
    required AppDataProvider data,
    required ConversationModel? conversation,
    required int messageUserId,
  }) {
    if (conversation != null &&
        conversation.otherUserId == messageUserId &&
        conversation.otherUserName.trim().isNotEmpty) {
      return conversation.otherUserName.trim();
    }

    return data.userName(messageUserId);
  }
}

class _MessageRow extends StatelessWidget {
  final bool mine;
  final String message;
  final String senderName;
  final String? avatarUrl;
  final String time;

  const _MessageRow({
    required this.mine,
    required this.message,
    required this.senderName,
    required this.avatarUrl,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final bubble = Container(
      constraints: const BoxConstraints(
        maxWidth: 320,
      ),
      margin: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        10,
      ),
      decoration: BoxDecoration(
        color: mine ? const Color(0xFFEAF3DE) : colors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 6),
          bottomRight: Radius.circular(mine ? 6 : 18),
        ),
        border: Border.all(
          color: mine
              ? const Color(0xFFC0DD97)
              : colors.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine) ...[
            Text(
              senderName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF3B6D11),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
          ],
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$senderName • $time',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );

    if (mine) {
      return Align(
        alignment: Alignment.centerRight,
        child: bubble,
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 6),
            child: UserAvatar(
              imageUrl: avatarUrl,
              name: senderName,
              radius: 15,
            ),
          ),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

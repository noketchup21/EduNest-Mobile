import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';

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

      final conv = context.read<AppDataProvider>().conversations
          .where((c) => c.conversationId == widget.conversationId)
          .firstOrNull;
      if (conv != null && context.mounted) {
        for (final id in conv.userIds) {
          context.read<AppDataProvider>().loadUserName(id);
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
      // ErrorBanner will show provider error.
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

    content.clear();

    try {
      await context.read<AppDataProvider>().sendMessage(
        widget.conversationId,
        text,
      );

      if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final auth = context.watch<AuthProvider>();

    final messages = data.messages[widget.conversationId] ?? [];
    final formatter = DateFormat('HH:mm');

    final theme = Theme.of(context);
          final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,

      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,

        title: Builder(
          builder: (context) {
            final data = context.watch<AppDataProvider>();

            final conv = data.conversations
                .where((c) => c.conversationId == widget.conversationId)
                .firstOrNull;

            final otherIds = conv?.userIds
                .where((id) => id != data.profile?.userId)
                .toList() ??
                [];

            final titleName = otherIds.isEmpty
                ? 'Conversation #${widget.conversationId}'
                : otherIds.map((id) => data.userName(id)).join(', ');

            return Text(
              titleName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            );
          },
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
                      const SizedBox(height: 120),

                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 56,
                        color: colors.onSurface.withValues(
                          alpha: 0.25,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'No messages yet',
                        style: theme.textTheme.titleMedium,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Start the conversation 👋',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface
                              .withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  : ListView.builder(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final mine = auth.userId != null &&
                      message.userId == auth.userId;

                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                             constraints: const BoxConstraints(
                               maxWidth: 340,
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
                               color: mine
                                   ? const Color(0xFFEAF3DE)
                                   : colors.surface,
                               borderRadius: BorderRadius.only(
                                 topLeft: const Radius.circular(18),
                                 topRight: const Radius.circular(18),
                                 bottomLeft: Radius.circular(
                                   mine ? 18 : 6,
                                 ),
                                 bottomRight: Radius.circular(
                                   mine ? 6 : 18,
                                 ),
                               ),
                               border: Border.all(
                                 color: mine
                                     ? const Color(0xFFC0DD97)
                                     : colors.outlineVariant.withValues(
                                         alpha: 0.5,
                                       ),
                                 width: 0.5,
                               ),
                             ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!mine) ...[
                            Text(
                              data.userName(message.userId),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF3B6D11),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],
                          Text(
                            message.content,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${mine ? 'You' : data.userName(message.userId)} • '
                                '${formatter.format(message.createdAt.toLocal())}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    color: colors.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                12,
              ),
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
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor:
                            colors.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colors.outlineVariant,
                            width: 0.5,
                          ),
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color:
                                colors.outlineVariant,
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  FilledButton(
                    onPressed:
                        sending ? null : _sendMessage,
                    style: FilledButton.styleFrom(
                      minimumSize:
                          const Size(50, 50),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
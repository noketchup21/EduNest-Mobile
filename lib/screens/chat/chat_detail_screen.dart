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

    return Scaffold(
      appBar: AppBar(
        title: Text('Conversation #${widget.conversationId}'),
        actions: [
          IconButton(
            onPressed: data.loading ? null : () => _loadMessages(),
            icon: const Icon(Icons.refresh),
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
                children: const [
                  SizedBox(height: 160),
                  Center(
                    child: Text('No messages yet. Say hello!'),
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
                        maxWidth: 320,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: mine
                            ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            : Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message.content),
                          const SizedBox(height: 4),
                          Text(
                            '${mine ? 'You' : 'User #${message.userId}'} • '
                                '${formatter.format(message.createdAt.toLocal())}',
                            style: Theme.of(context).textTheme.bodySmall,
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: content,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: sending ? null : _sendMessage,
                    icon: sending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.send),
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
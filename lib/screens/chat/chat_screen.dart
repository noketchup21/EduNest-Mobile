import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final otherUser = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppDataProvider>().loadConversations());
  }

  @override
  void dispose() {
    otherUser.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final formatter = DateFormat('dd/MM HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Chat'), actions: [IconButton(onPressed: data.loadConversations, icon: const Icon(Icons.refresh))]),
      body: ListView(
        children: [
          ErrorBanner(data.error),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: otherUser,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Other user ID'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final id = int.tryParse(otherUser.text.trim());
                      if (id == null) return;
                      try {
                        final c = await data.startConversation(id);
                        if (context.mounted) context.push('/chat/${c.conversationId}');
                      } catch (_) {}
                    },
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),
          ),
          ...data.conversations.map(
            (c) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                title: Text('Conversation #${c.conversationId}'),
                subtitle: Text('Users: ${c.userIds.join(', ')}'),
                trailing: Text(formatter.format(c.lastMessageAt.toLocal())),
                onTap: () => context.push('/chat/${c.conversationId}'),
              ),
            ),
          ),
          if (!data.loading && data.conversations.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('No conversations yet.')),
        ],
      ),
    );
  }
}

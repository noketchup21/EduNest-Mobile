import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final otherUserEmail = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppDataProvider>().loadConversations(),
    );
  }

  @override
  void dispose() {
    otherUserEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final formatter = DateFormat('dd/MM HH:mm');

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          t.chat,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.outlined(
              onPressed: data.loading ? null : data.loadConversations,
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
      body: RefreshIndicator(
        onRefresh: data.loadConversations,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ErrorBanner(data.error),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSectionHeader(
                      icon: Icons.person_add_alt_1_rounded,
                      title: t.text('Start a conversation'),
                      subtitle: t.text(
                          'Connect safely with a tutor, learner, or parent.'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: otherUserEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: t.userEmail,
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: data.loading
                          ? null
                          : () async {
                              final email = otherUserEmail.text.trim();

                              if (email.isEmpty || !email.contains('@')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(t.enterValidUserEmail)),
                                );
                                return;
                              }

                              try {
                                final conversation =
                                    await data.startConversationByEmail(email);

                                if (context.mounted) {
                                  otherUserEmail.clear();
                                  context.push(
                                      '/chat/${conversation.conversationId}');
                                }
                              } catch (_) {
                                // ErrorBanner renders the provider error.
                              }
                            },
                      icon: const Icon(Icons.send_rounded),
                      label: Text(t.start),
                    ),
                  ],
                ),
              ),
            ),
            ...data.conversations.map((c) {
              final otherIds =
                  c.userIds.where((id) => id != data.profile?.userId).toList();

              final fallbackName = otherIds.isEmpty
                  ? t.conversationNumber(c.conversationId)
                  : otherIds.map((id) => data.userName(id)).join(', ');

              final displayName = c.otherUserName.trim().isNotEmpty
                  ? c.otherUserName
                  : fallbackName;

              final roleText =
                  c.otherUserRole.trim().isEmpty ? '' : ' • ${c.otherUserRole}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: UserAvatar(
                      imageUrl: c.otherUserAvatarUrl,
                      name: displayName,
                      radius: 24,
                    ),
                    title: Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '${formatter.format(c.lastMessageAt.toLocal())}$roleText',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurface.withValues(alpha: 0.4),
                    ),
                    onTap: () => context.push('/chat/${c.conversationId}'),
                  ),
                ),
              );
            }),
            if (data.loading && data.conversations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!data.loading && data.conversations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: AppEmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: t.text('No conversations yet'),
                  message: t.text('Start a conversation using an email above.'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

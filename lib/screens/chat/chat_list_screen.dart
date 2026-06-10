import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/premium_loading.dart';
import '../../widgets/swaply_background.dart';
import 'widgets/chat_tile.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChats());
  }

  @override
  void dispose() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.unsubscribeChats();
    super.dispose();
  }

  Future<void> _loadChats() async {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (userId != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.fetchChats(userId);
      chatProvider.subscribeToChats(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    return Scaffold(
      body: SwaplyBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.s20,
                      AppSizes.s16,
                      AppSizes.s20,
                      AppSizes.s12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight.withValues(alpha: 0.90),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Messages',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(AppSizes.s10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            size: AppSizes.iconSm,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: chatProvider.isLoading
                    ? const PageShimmer(itemCount: 5)
                    : chatProvider.chats.isEmpty
                        ? _buildEmptyState(theme, isDark)
                        : RefreshIndicator(
                            onRefresh: _loadChats,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                AppSizes.s16,
                                AppSizes.s16,
                                AppSizes.s16,
                                AppSizes.s24,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemCount: chatProvider.chats.length,
                              itemBuilder: (context, index) {
                                final chat = chatProvider.chats[index];
                                return ChatTile(
                                  chat: chat,
                                  currentUserId: currentUserId,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.chat,
                                      arguments: {
                                        'chatId': chat.id,
                                        'participantName':
                                            chat.participantName,
                                        'participantAvatarUrl':
                                            chat.participantAvatarUrl,
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.s24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: AppSizes.iconXl,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSizes.s20),
            Text(
              'No conversations yet',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              'Browse books and message owners\nto start trading!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

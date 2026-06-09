import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../models/chat_model.dart';
import '../../../widgets/animated_badge.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String? currentUserId;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final participantName = chat.participantName ?? 'BookSwap Reader';
    final avatarUrl = chat.participantAvatarUrl;
    final initials = participantName.isNotEmpty
        ? participantName.substring(0, 1).toUpperCase()
        : 'U';
    final hasLastMessage =
        chat.lastMessage != null && chat.lastMessage!.isNotEmpty;
    final unreadCount = currentUserId != null
        ? chat.unreadCountFor(currentUserId!)
        : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.s14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.bgCardDark.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.border.withValues(alpha: 0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          foregroundDecoration: unreadCount > 0
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                )
              : null,
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: avatarUrl == null
                          ? LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.8),
                                AppColors.primaryLight.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.transparent,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              initials,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: AnimatedBadge(count: unreadCount),
                    ),
                ],
              ),
              const SizedBox(width: AppSizes.s14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            participantName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.lastMessageAt != null) ...[
                          const SizedBox(width: AppSizes.s8),
                          Text(
                            _formatTimestamp(chat.lastMessageAt!),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: unreadCount > 0
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMuted),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      hasLastMessage
                          ? chat.lastMessage!
                          : 'Start the conversation',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight:
                            unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                        color: hasLastMessage
                            ? (unreadCount > 0
                                ? (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary)
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary))
                            : (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMuted),
                        fontStyle: hasLastMessage
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: AppSizes.s8),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

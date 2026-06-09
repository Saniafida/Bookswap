import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final String? avatarUrl;
  final String initials;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    this.avatarUrl,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        top: AppSizes.s2,
        bottom: AppSizes.s2,
        left: isMe ? AppSizes.s56 : 0,
        right: isMe ? 0 : AppSizes.s56,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              Container(
                width: 28,
                height: 28,
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
                  radius: 14,
                  backgroundColor: Colors.transparent,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                          initials,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: AppSizes.s8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s14,
                vertical: AppSizes.s10,
              ),
              decoration: BoxDecoration(
                gradient: isMe ? AppColors.primaryGradient : null,
                color: isMe
                    ? null
                    : (isDark
                        ? AppColors.bgCardDark.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.85)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSizes.radiusLg),
                  topRight: const Radius.circular(AppSizes.radiusLg),
                  bottomLeft:
                      Radius.circular(isMe ? AppSizes.radiusLg : AppSizes.s4),
                  bottomRight:
                      Radius.circular(isMe ? AppSizes.s4 : AppSizes.radiusLg),
                ),
                border: !isMe
                    ? Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppColors.border.withValues(alpha: 0.4),
                        width: 0.5,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.poppins(
                      color: isMe
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.65)
                              : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMuted),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: AppSizes.s4),
                        Icon(
                          message.isRead
                              ? Icons.check_circle_rounded
                              : Icons.check_rounded,
                          size: 13,
                          color: message.isRead
                              ? (isMe
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppColors.primary)
                              : (isMe
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

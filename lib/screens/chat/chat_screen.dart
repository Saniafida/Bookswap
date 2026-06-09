import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/premium_loading.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String? participantName;
  final String? participantAvatarUrl;

  const ChatScreen({
    super.key,
    required this.chatId,
    this.participantName,
    this.participantAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessages());
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    Provider.of<ChatProvider>(context, listen: false).unsubscribeMessages();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.clearMessages();
    await chatProvider.fetchMessages(widget.chatId);
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (userId != null) {
      chatProvider.markAsRead(widget.chatId, userId);
    }
    _scrollToBottom();
  }

  void _scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (currentUserId == null) return;

    setState(() => _isSending = true);
    _inputController.clear();

    final message = MessageModel(
      id: '',
      chatId: widget.chatId,
      senderId: currentUserId,
      text: text,
      createdAt: DateTime.now(),
    );

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(message, currentUserId: currentUserId);

    setState(() => _isSending = false);
    _scrollToBottom(animate: true);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    if (_isSameDay(dt, now)) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(dt, yesterday)) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    final messages = chatProvider.messages;

    if (messages.isNotEmpty) {
      _scrollToBottom(animate: true);
    }

    final participantName = widget.participantName ?? 'Reader';
    final avatarUrl = widget.participantAvatarUrl;
    final initials =
        participantName.isNotEmpty ? participantName[0].toUpperCase() : 'R';

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.bgDark.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSizes.s8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(AppSizes.s8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.bgSurface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.border.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: AppSizes.iconSm,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
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
                radius: 18,
                backgroundColor: Colors.transparent,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        initials,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSizes.s10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participantName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'BookSwap Reader',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(
            height: 0.5,
            thickness: 0.5,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.border.withValues(alpha: 0.4),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.isLoading
                ? const PremiumLoading(message: 'Loading messages...')
                : messages.isEmpty
                    ? _buildEmptyConversation(theme, isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.s16,
                          AppSizes.s16,
                          AppSizes.s16,
                          AppSizes.s8,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.senderId == currentUserId;
                          final prevMsg =
                              index > 0 ? messages[index - 1] : null;
                          final showDateLabel = prevMsg == null ||
                              !_isSameDay(
                                  msg.createdAt, prevMsg.createdAt);
                          final showAvatar = !isMe &&
                              (index == messages.length - 1 ||
                                  messages[index + 1].senderId !=
                                      msg.senderId);

                          return Column(
                            children: [
                              if (showDateLabel)
                                _buildDateLabel(msg.createdAt, isDark),
                              MessageBubble(
                                message: msg,
                                isMe: isMe,
                                showAvatar: showAvatar,
                                avatarUrl: avatarUrl,
                                initials: initials,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _buildInputBar(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildDateLabel(DateTime dt, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s14,
            vertical: AppSizes.s6,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.bgSurface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.border.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            _formatDateLabel(dt),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyConversation(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.s20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.waving_hand_rounded,
              size: AppSizes.iconLg,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          Text(
            'Say hello!',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSizes.s6),
          Text(
            'This is the start of your conversation.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, bool isDark) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSizes.s16,
            AppSizes.s12,
            AppSizes.s16,
            AppSizes.s12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.bgDark.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.border.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.bgSurface.withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.border.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _inputController,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message\u2026',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSizes.s12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.s10),
              GestureDetector(
                onTap: _isSending ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: AppSizes.iconSm,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

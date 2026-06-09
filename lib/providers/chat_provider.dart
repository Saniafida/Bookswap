import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

enum ChatStatus { initial, loading, loaded, error }

class ChatProvider extends ChangeNotifier {
  ChatStatus _status = ChatStatus.initial;
  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  String? _errorMessage;
  RealtimeChannel? _messageChannel;
  RealtimeChannel? _chatsChannel;

  // ── Getters ───────────────────────────────────────────────────────────────
  ChatStatus get status => _status;
  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ChatStatus.loading;

  int totalUnreadFor(String userId) =>
      _chats.fold(0, (sum, chat) => sum + chat.unreadCountFor(userId));

  // ── Fetch user chats ──────────────────────────────────────────────────────
  Future<void> fetchChats(String userId) async {
    _setLoading();
    try {
      final data = await SupabaseService.table('chats')
          .select()
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('last_message_at', ascending: false);
      final chats = (data as List).map((e) => ChatModel.fromJson(e)).toList();

      // Batch-fetch the OTHER participant's profile for each chat
      final otherIds = chats.map((c) =>
        c.user1Id == userId ? c.user2Id : c.user1Id
      ).toList();

      if (otherIds.isNotEmpty) {
        final profiles = await SupabaseService.table('profiles')
            .select('id, full_name, avatar_url')
            .inFilter('id', otherIds);

        final profileMap = {
          for (final p in (profiles as List)) p['id'] as String: p
        };

        for (int i = 0; i < chats.length; i++) {
          final otherId = chats[i].user1Id == userId
              ? chats[i].user2Id
              : chats[i].user1Id;
          final profile = profileMap[otherId];
          if (profile != null) {
            chats[i] = chats[i].copyWith(
              participantName: profile['full_name'] as String?,
              participantAvatarUrl: profile['avatar_url'] as String?,
            );
          }
        }
      }

      _chats = chats;
      _status = ChatStatus.loaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── Fetch messages for a chat ─────────────────────────────────────────────
  Future<void> fetchMessages(String chatId) async {
    _setLoading();
    try {
      final data = await SupabaseService.table('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);
      _messages = (data as List).map((e) => MessageModel.fromJson(e)).toList();
      _status = ChatStatus.loaded;
      notifyListeners();
      _subscribeToMessages(chatId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── Send message ──────────────────────────────────────────────────────────
  Future<bool> sendMessage(MessageModel message, {String? currentUserId}) async {
    try {
      await SupabaseService.table('messages').insert(message.toJson());

      // Update local state immediately so badge shows without realtime delay
      if (currentUserId != null) {
        final idx = _chats.indexWhere((c) => c.id == message.chatId);
        if (idx != -1) {
          final chat = _chats.removeAt(idx);
          final isUser1 = chat.user1Id == currentUserId;
          _chats.insert(0, chat.copyWith(
            lastMessage: message.text,
            lastMessageAt: message.createdAt,
            unreadCount1: chat.unreadCount1 + (isUser1 ? 0 : 1),
            unreadCount2: chat.unreadCount2 + (isUser1 ? 1 : 0),
          ));
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Mark messages as read ──────────────────────────────────────────────────
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await SupabaseService.table('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      final chat = _chats.firstWhere((c) => c.id == chatId,
          orElse: () => _chats.first);
      final isUser1 = chat.user1Id == userId;
      await SupabaseService.table('chats')
          .update(isUser1 ? {'unread_count_1': 0} : {'unread_count_2': 0})
          .eq('id', chatId);

      // Update local state immediately
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].senderId != userId && !_messages[i].isRead) {
          _messages[i] = _messages[i].copyWith(isRead: true);
        }
      }
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── Get or Create Chat ─────────────────────────────────────────────────────
  Future<String?> getOrCreateChat(String user1Id, String user2Id) async {
    try {
      final existing = await SupabaseService.table('chats')
          .select()
          .or('and(user1_id.eq.$user1Id,user2_id.eq.$user2Id),and(user1_id.eq.$user2Id,user2_id.eq.$user1Id)')
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      final response = await SupabaseService.table('chats').insert({
        'user1_id': user1Id,
        'user2_id': user2Id,
      }).select().single();

      return response['id'] as String;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // ── Realtime subscription ─────────────────────────────────────────────────
  void _subscribeToMessages(String chatId) {
    _messageChannel?.unsubscribe();
    _messageChannel = SupabaseService.client
        .channel('messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final newMessage = MessageModel.fromJson(payload.newRecord);
            _messages.add(newMessage);
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final updated = MessageModel.fromJson(payload.newRecord);
            final idx = _messages.indexWhere((m) => m.id == updated.id);
            if (idx != -1) {
              _messages[idx] = updated;
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  // ── Dispose realtime ──────────────────────────────────────────────────────
  void unsubscribeMessages() {
    _messageChannel?.unsubscribe();
    _messageChannel = null;
  }

  void subscribeToChats(String userId) {
    _chatsChannel?.unsubscribe();
    _chatsChannel = SupabaseService.client
        .channel('chats:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chats',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user1_id',
            value: userId,
          ),
          callback: (_) => fetchChats(userId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chats',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user2_id',
            value: userId,
          ),
          callback: (_) => fetchChats(userId),
        )
        .subscribe();
  }

  void unsubscribeChats() {
    _chatsChannel?.unsubscribe();
    _chatsChannel = null;
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _setLoading() {
    _status = ChatStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = ChatStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribeMessages();
    unsubscribeChats();
    super.dispose();
  }
}

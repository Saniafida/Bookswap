import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../core/enums/user_role.dart';
import '../repositories/admin_user_repository.dart';

enum AdminUserStatus { initial, loading, loaded, error }

class AdminUserProvider extends ChangeNotifier {
  final AdminUserRepository _repo;
  AdminUserProvider({AdminUserRepository? repo})
      : _repo = repo ?? const AdminUserRepository();

  AdminUserStatus _status = AdminUserStatus.initial;
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  List<PostModel> _selectedUserPosts = [];
  String? _error;
  String _searchQuery = '';
  bool _bannedOnly = false;
  int _page = 0;
  bool _hasMore = true;

  AdminUserStatus get status => _status;
  List<UserModel> get users => _users;
  UserModel? get selectedUser => _selectedUser;
  List<PostModel> get selectedUserPosts => _selectedUserPosts;
  String? get error => _error;
  bool get isLoading => _status == AdminUserStatus.loading;
  bool get hasMore => _hasMore;

  Future<void> fetchUsers({bool refresh = false}) async {
    if (refresh) {
      _page = 0;
      _users = [];
      _hasMore = true;
    }
    if (!_hasMore) return;
    _status = AdminUserStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.fetchUsers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        bannedOnly: _bannedOnly ? true : null,
        page: _page,
      );
      if (result.length < 30) _hasMore = false;
      _users = refresh ? result : [..._users, ...result];
      _page++;
      _status = AdminUserStatus.loaded;
    } catch (e) {
      _status = AdminUserStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    fetchUsers(refresh: true);
  }

  void setFilter({required bool bannedOnly}) {
    _bannedOnly = bannedOnly;
    fetchUsers(refresh: true);
  }

  Future<void> loadUserDetail(String uid) async {
    _status = AdminUserStatus.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.fetchUserDetail(uid),
        _repo.fetchUserPosts(uid),
      ]);
      _selectedUser = results[0] as UserModel;
      _selectedUserPosts = results[1] as List<PostModel>;
      _status = AdminUserStatus.loaded;
    } catch (e) {
      _status = AdminUserStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> banUser(String uid) => _performAction(() => _repo.banUser(uid));
  Future<bool> unbanUser(String uid) => _performAction(() => _repo.unbanUser(uid));
  Future<bool> deleteUser(String uid) => _performAction(() => _repo.deleteUser(uid));

  Future<bool> changeRole(String uid, UserRole role) =>
      _performAction(() => _repo.changeRole(uid, role.name));

  Future<bool> _performAction(Future<void> Function() action) async {
    try {
      await action();
      await fetchUsers(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

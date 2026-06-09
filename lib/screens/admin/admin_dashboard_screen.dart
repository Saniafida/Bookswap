import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/enums/user_role.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/permission_helper.dart';
import '../../providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Admin Dashboard Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // ── Stats ─────────────────────────────────────────────────────────────────
  int _totalUsers = 0;
  int _totalPosts = 0;
  bool _statsLoading = true;

  // ── Users list ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _users = [];
  bool _usersLoading = true;

  // ── Posts list ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _posts = [];
  bool _postsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _loadStats();
    _loadUsers();
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Data Loading ──────────────────────────────────────────────────────────

  Future<void> _loadStats() async {
    try {
      final users =
          await SupabaseService.table('profiles').select('id').count();
      final posts =
          await SupabaseService.table('posts').select('id').count();
      if (mounted) {
        setState(() {
          _totalUsers = users.count;
          _totalPosts = posts.count;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final data = await SupabaseService.table('profiles')
          .select('id, full_name, email, role, created_at, avatar_url')
          .order('created_at', ascending: false)
          .limit(50);
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _usersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _usersLoading = false);
    }
  }

  Future<void> _loadPosts() async {
    try {
      final data = await SupabaseService.table('posts')
          .select('id, title, listing_type, created_at, user_id')
          .order('created_at', ascending: false)
          .limit(50);
      if (mounted) {
        setState(() {
          _posts = List<Map<String, dynamic>>.from(data);
          _postsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _postsLoading = false);
    }
  }

  Future<void> _changeUserRole(String uid, UserRole newRole) async {
    try {
      await SupabaseService.table('profiles')
          .update({'role': newRole.name})
          .eq('id', uid);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role updated to ${newRole.displayName}'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update role'),
            backgroundColor: const Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Delete Post',
        message: 'Are you sure you want to permanently delete this post?',
      ),
    );
    if (confirm != true) return;

    try {
      await SupabaseService.table('posts').delete().eq('id', postId);
      await _loadPosts();
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post deleted'),
            backgroundColor: const Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Double-check permission in build (guard covers navigation,
    // this covers deep-link and hot-reload edge cases).
    if (!PermissionHelper.canAccessAdmin(auth.currentRole)) {
      return const _AccessDeniedPlaceholder();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [_buildAppBar(auth)],
          body: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(
                      totalUsers: _totalUsers,
                      totalPosts: _totalPosts,
                      loading: _statsLoading,
                    ),
                    _UsersTab(
                      users: _users,
                      loading: _usersLoading,
                      onRoleChange: _changeUserRole,
                    ),
                    _PostsTab(
                      posts: _posts,
                      loading: _postsLoading,
                      onDelete: _deletePost,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AuthProvider auth) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0F),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.bottomNav),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0533), Color(0xFF0A0A0F)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFF7C3AED),
                            Color(0xFFEC4899),
                          ]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('ADMIN',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5),
                  ),
                  Text(
                    'Logged in as ${auth.currentUser?.fullName ?? 'Admin'}',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF7C3AED),
        indicatorWeight: 2,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Users'),
          Tab(text: 'Posts'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Overview Tab
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final int totalUsers;
  final int totalPosts;
  final bool loading;

  const _OverviewTab({
    required this.totalUsers,
    required this.totalPosts,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Overview',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people_alt_rounded,
                  label: 'Total Users',
                  value: loading ? '—' : totalUsers.toString(),
                  gradient: const [Color(0xFF7C3AED), Color(0xFF9F67FA)],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Total Posts',
                  value: loading ? '—' : totalPosts.toString(),
                  gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Active Swaps',
                  value: '—',
                  gradient: const [Color(0xFF059669), Color(0xFF34D399)],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  icon: Icons.flag_rounded,
                  label: 'Reports',
                  value: '0',
                  gradient: const [Color(0xFFE11D48), Color(0xFFFB7185)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Quick Actions',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          const SizedBox(height: 14),
          _QuickAction(
            icon: Icons.people_rounded,
            title: 'Manage Users',
            subtitle: 'View and modify user roles',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.auto_delete_rounded,
            title: 'Moderate Posts',
            subtitle: 'Remove policy-violating content',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.bar_chart_rounded,
            title: 'Analytics',
            subtitle: 'Platform growth metrics',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Users Tab
// ─────────────────────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final bool loading;
  final Future<void> Function(String uid, UserRole role) onRoleChange;

  const _UsersTab({
    required this.users,
    required this.loading,
    required this.onRoleChange,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
    }
    if (users.isEmpty) {
      return const Center(
          child: Text('No users found.',
              style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u = users[i];
        final role = UserRole.fromString(u['role'] as String?);
        final name = u['full_name'] as String? ?? 'Unknown';
        final email = u['email'] as String? ?? '';
        final uid = u['id'] as String;

        return _UserCard(
          name: name,
          email: email,
          uid: uid,
          role: role,
          avatarUrl: u['avatar_url'] as String?,
          onRoleChange: (newRole) => onRoleChange(uid, newRole),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Posts Tab
// ─────────────────────────────────────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  final bool loading;
  final Future<void> Function(String postId) onDelete;

  const _PostsTab({
    required this.posts,
    required this.loading,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
    }
    if (posts.isEmpty) {
      return const Center(
          child: Text('No posts found.',
              style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final p = posts[i];
        final title = p['title'] as String? ?? 'Untitled';
        final type = p['listing_type'] as String? ?? 'swap';
        final id = p['id'] as String;

        return _PostAdminCard(
          title: title,
          listingType: type,
          postId: id,
          onDelete: () => onDelete(id),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient.map((c) => c.withOpacity(0.15)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient.first.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style:
                TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF9F67FA), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String uid;
  final UserRole role;
  final String? avatarUrl;
  final void Function(UserRole) onRoleChange;

  const _UserCard({
    required this.name,
    required this.email,
    required this.uid,
    required this.role,
    required this.onRoleChange,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = role.isAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAdmin
              ? const Color(0xFF7C3AED).withOpacity(0.4)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            backgroundColor: const Color(0xFF7C3AED).withOpacity(0.2),
            child: avatarUrl == null
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(width: 8),
                    _RoleBadge(role: role),
                  ],
                ),
                const SizedBox(height: 2),
                Text(email,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Role toggle
          PopupMenuButton<UserRole>(
            color: const Color(0xFF1A1A2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: Icon(Icons.more_vert_rounded,
                color: Colors.white.withOpacity(0.4), size: 20),
            onSelected: onRoleChange,
            itemBuilder: (_) => UserRole.values
                .where((r) => r != role)
                .map(
                  (r) => PopupMenuItem(
                    value: r,
                    child: Text('Set as ${r.displayName}',
                        style: const TextStyle(color: Colors.white)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (bg, text) = role.isAdmin
        ? (const Color(0xFF7C3AED), Colors.white)
        : (Colors.white12, Colors.white54);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.badgeLabel,
        style: TextStyle(
            fontSize: 9,
            color: text,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8),
      ),
    );
  }
}

class _PostAdminCard extends StatelessWidget {
  final String title;
  final String listingType;
  final String postId;
  final VoidCallback onDelete;

  const _PostAdminCard({
    required this.title,
    required this.listingType,
    required this.postId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Color(0xFF38BDF8), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(listingType.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48)),
            onPressed: onDelete,
            tooltip: 'Delete post',
          ),
        ],
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  const _ConfirmDialog({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700)),
      content: Text(message,
          style: TextStyle(color: Colors.white.withOpacity(0.6))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete',
              style:
                  TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _AccessDeniedPlaceholder extends StatelessWidget {
  const _AccessDeniedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block_rounded,
                size: 72, color: Color(0xFFE11D48)),
            const SizedBox(height: 20),
            const Text('Access Denied',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('This area is restricted to admins.',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.bottomNav),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
              child: const Text('Go Back',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

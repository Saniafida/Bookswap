/// Platform-wide statistics shown on the admin dashboard.
class AdminStatsModel {
  final int totalUsers;
  final int totalBooks;
  final int totalChats;
  final int totalDonations;
  final int totalExchanges;
  final int totalSells;
  final int newUsersToday;
  final int newBooksToday;
  final int pendingReports;
  final int activeAnnouncements;

  const AdminStatsModel({
    this.totalUsers = 0,
    this.totalBooks = 0,
    this.totalChats = 0,
    this.totalDonations = 0,
    this.totalExchanges = 0,
    this.totalSells = 0,
    this.newUsersToday = 0,
    this.newBooksToday = 0,
    this.pendingReports = 0,
    this.activeAnnouncements = 0,
  });

  AdminStatsModel copyWith({
    int? totalUsers,
    int? totalBooks,
    int? totalChats,
    int? totalDonations,
    int? totalExchanges,
    int? totalSells,
    int? newUsersToday,
    int? newBooksToday,
    int? pendingReports,
    int? activeAnnouncements,
  }) {
    return AdminStatsModel(
      totalUsers: totalUsers ?? this.totalUsers,
      totalBooks: totalBooks ?? this.totalBooks,
      totalChats: totalChats ?? this.totalChats,
      totalDonations: totalDonations ?? this.totalDonations,
      totalExchanges: totalExchanges ?? this.totalExchanges,
      totalSells: totalSells ?? this.totalSells,
      newUsersToday: newUsersToday ?? this.newUsersToday,
      newBooksToday: newBooksToday ?? this.newBooksToday,
      pendingReports: pendingReports ?? this.pendingReports,
      activeAnnouncements: activeAnnouncements ?? this.activeAnnouncements,
    );
  }
}

enum ReportStatus { pending, resolved, dismissed }

extension ReportStatusExt on ReportStatus {
  String get label => switch (this) {
        ReportStatus.pending => 'Pending',
        ReportStatus.resolved => 'Resolved',
        ReportStatus.dismissed => 'Dismissed',
      };

  static ReportStatus fromString(String? s) => ReportStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ReportStatus.pending,
      );
}

class ReportModel {
  final String id;
  final String? reporterId;
  final String? reporterName;
  final String? reportedPostId;
  final String? reportedPostTitle;
  final String? reportedUserId;
  final String? reportedUserName;
  final String reason;
  final ReportStatus status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const ReportModel({
    required this.id,
    this.reporterId,
    this.reporterName,
    this.reportedPostId,
    this.reportedPostTitle,
    this.reportedUserId,
    this.reportedUserName,
    required this.reason,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.resolvedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String?,
      reporterName: (json['reporter'] as Map<String, dynamic>?)?['full_name']
          as String?,
      reportedPostId: json['reported_post_id'] as String?,
      reportedPostTitle:
          (json['reported_post'] as Map<String, dynamic>?)?['title']
              as String?,
      reportedUserId: json['reported_user_id'] as String?,
      reportedUserName:
          (json['reported_user'] as Map<String, dynamic>?)?['full_name']
              as String?,
      reason: json['reason'] as String,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      adminNote: json['admin_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }
}

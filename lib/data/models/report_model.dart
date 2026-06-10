class ReportModel {
  final String id;
  final String reporterId;
  final String? listingId;
  final String? userId;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    this.listingId,
    this.userId,
    required this.reason,
    this.description,
    this.status = 'pending',
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      listingId: json['listing_id'] as String?,
      userId: json['user_id'] as String?,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reporter_id': reporterId,
      'listing_id': listingId,
      'user_id': userId,
      'reason': reason,
      'description': description,
      'status': status,
    };
  }

  ReportModel copyWith({
    String? listingId,
    String? userId,
    String? reason,
    String? description,
    String? status,
  }) {
    return ReportModel(
      id: id,
      reporterId: reporterId,
      listingId: listingId ?? this.listingId,
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

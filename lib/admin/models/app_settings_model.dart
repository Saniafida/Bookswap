/// Wraps the key-value `app_settings` Supabase table as typed fields.
class AppSettingsModel {
  final String appName;
  final String contactEmail;
  final String privacyPolicy;
  final String termsAndConditions;

  const AppSettingsModel({
    this.appName = 'BookSwap',
    this.contactEmail = '',
    this.privacyPolicy = '',
    this.termsAndConditions = '',
  });

  /// Build from a list of {key, value} rows from Supabase.
  factory AppSettingsModel.fromRows(List<Map<String, dynamic>> rows) {
    final map = {for (final r in rows) r['key'] as String: r['value'] as String? ?? ''};
    return AppSettingsModel(
      appName: map['app_name'] ?? 'BookSwap',
      contactEmail: map['contact_email'] ?? '',
      privacyPolicy: map['privacy_policy'] ?? '',
      termsAndConditions: map['terms_and_conditions'] ?? '',
    );
  }

  /// Convert back to a list of {key, value} rows for bulk upsert.
  List<Map<String, dynamic>> toRows() => [
        {'key': 'app_name', 'value': appName},
        {'key': 'contact_email', 'value': contactEmail},
        {'key': 'privacy_policy', 'value': privacyPolicy},
        {'key': 'terms_and_conditions', 'value': termsAndConditions},
      ];

  AppSettingsModel copyWith({
    String? appName,
    String? contactEmail,
    String? privacyPolicy,
    String? termsAndConditions,
  }) {
    return AppSettingsModel(
      appName: appName ?? this.appName,
      contactEmail: contactEmail ?? this.contactEmail,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
    );
  }
}

class SearchConstants {
  SearchConstants._();

  static const List<String> listingTypes = [
    'sell',
    'exchange',
    'donate',
    'sellExchange',
    'sell_exchange',
  ];

  static const List<String> conditions = [
    'brandNew',
    'likeNew',
    'good',
    'fair',
    'poor',
  ];

  static String listingTypeLabel(String type) {
    return switch (type) {
      'sell' => 'Sell',
      'exchange' => 'Exchange',
      'donate' => 'Donate',
      'sellExchange' => 'Sell/Exchange',
      'sell_exchange' => 'Sell/Exchange',
      _ => type,
    };
  }

  static String conditionLabel(String condition) {
    return switch (condition) {
      'brandNew' => 'Brand New',
      'likeNew' => 'Like New',
      'good' => 'Good',
      'fair' => 'Fair',
      'poor' => 'Poor',
      _ => condition,
    };
  }
}

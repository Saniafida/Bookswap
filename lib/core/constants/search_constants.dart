import '../../models/post_model.dart';

/// Shared search categories and filter options.
class SearchConstants {
  SearchConstants._();

  static const List<String> categories = [
    'Fiction',
    'Non-Fiction',
    'Academic',
    'Sci-Fi',
    'Biography',
    'Children',
    'Mystery',
    'History',
  ];

  static String listingTypeLabel(ListingType type) {
    switch (type) {
      case ListingType.swap:
        return 'Swap';
      case ListingType.sell:
        return 'Sell';
      case ListingType.both:
        return 'Both';
      case ListingType.donate:
        return 'Donate';
    }
  }

  static String conditionLabel(BookCondition condition) {
    switch (condition) {
      case BookCondition.brandNew:
        return 'Brand New';
      case BookCondition.likeNew:
        return 'Like New';
      case BookCondition.good:
        return 'Good';
      case BookCondition.fair:
        return 'Fair';
      case BookCondition.poor:
        return 'Poor';
    }
  }
}

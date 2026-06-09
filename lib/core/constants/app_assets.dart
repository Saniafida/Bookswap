/// Asset path constants — single source of truth for all asset references.
class AppAssets {
  AppAssets._();

  // ── Base paths ────────────────────────────────────────────────────────────
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _animations = 'assets/animations';

  // ── Images ────────────────────────────────────────────────────────────────
  static const String logo = '$_images/logo.png';
  static const String logoFull = '$_images/logo_full.png';
  static const String placeholder = '$_images/book_placeholder.png';
  static const String onboarding1 = '$_images/onboarding_1.png';
  static const String onboarding2 = '$_images/onboarding_2.png';
  static const String onboarding3 = '$_images/onboarding_3.png';
  static const String emptyBooks = '$_images/empty_books.png';
  static const String emptyChat = '$_images/empty_chat.png';

  // ── Icons ─────────────────────────────────────────────────────────────────
  static const String iconGoogle = '$_icons/google.svg';
  static const String iconApple = '$_icons/apple.svg';
  static const String iconBook = '$_icons/book.svg';
  static const String iconSwap = '$_icons/swap.svg';

  // ── Animations (Lottie) ───────────────────────────────────────────────────
  static const String animLoading = '$_animations/loading.json';
  static const String animSuccess = '$_animations/success.json';
  static const String animEmpty = '$_animations/empty.json';
}

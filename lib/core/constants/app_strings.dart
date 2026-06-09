/// Central repository for all user-facing strings.
/// Keeps the codebase i18n-ready.
class AppStrings {
  AppStrings._();

  // ── App ──────────────────────────────────────────────────────────────────
  static const String appName = 'BookSwap';
  static const String appTagline = 'Trade books. Grow your shelf.';

  // ── Onboarding ───────────────────────────────────────────────────────────
  static const String onboarding1Title = 'Discover Books Near You';
  static const String onboarding1Desc =
      'Browse thousands of pre-loved books listed by readers in your area.';

  static const String onboarding2Title = 'Swap or Sell';
  static const String onboarding2Desc =
      'Exchange books with others or sell them at your own price.';

  static const String onboarding3Title = 'Connect with Readers';
  static const String onboarding3Desc =
      'Chat with fellow book lovers and build your reading community.';

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String forgotPassword = 'Forgot Password?';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String orContinueWith = 'Or continue with';

  // ── Navigation ────────────────────────────────────────────────────────────
  static const String navHome = 'Home';
  static const String navSearch = 'Search';
  static const String navAdd = 'Add';
  static const String navChat = 'Chat';
  static const String navProfile = 'Profile';

  // ── Home ──────────────────────────────────────────────────────────────────
  static const String featuredBooks = 'Featured Books';
  static const String nearbyBooks = 'Books Near You';
  static const String recentlyAdded = 'Recently Added';

  // ── Search ───────────────────────────────────────────────────────────────
  static const String discover = 'Discover';
  static const String searchBooksHint = 'Search books, authors…';
  static const String searchUsersHint = 'Search readers by name…';
  static const String searchBooksTab = 'Books';
  static const String searchUsersTab = 'Readers';
  static const String findNextRead = 'Find your next read';
  static const String connectReaders = 'Connect with readers';
  static const String clearFilters = 'Clear filters';
  static const String noBooksMatch = 'No books match your search';
  static const String noReadersFound = 'No readers found';

  // ── Profile ──────────────────────────────────────────────────────────────
  static const String myProfile = 'My Profile';
  static const String editProfile = 'Edit Profile';
  static const String readerProfile = 'Reader Profile';
  static const String bio = 'Bio';
  static const String location = 'Location';
  static const String myListings = 'My Listings';
  static const String listedBooks = 'Listed Books';
  static const String confirmLogout = 'Confirm Logout';
  static const String logoutConfirmMessage = 'Are you sure you want to sign out?';
  static const String listFirstBook = 'List your first book';
  static const String noBooksListed = 'You have not listed any books yet.';
  static const String noBooksListedOther = 'This reader has no books listed.';

  // ── Post ─────────────────────────────────────────────────────────────────
  static const String addBook = 'Add a Book';
  static const String editBook = 'Edit Book';
  static const String bookTitle = 'Book Title';
  static const String bookAuthor = 'Author';
  static const String bookCondition = 'Condition';
  static const String bookDescription = 'Description';
  static const String bookCategory = 'Category';
  static const String listingType = 'Listing Type';
  static const String swap = 'Swap';
  static const String sell = 'Sell';
  static const String both = 'Both';
  static const String price = 'Price (optional)';

  // ── Errors ────────────────────────────────────────────────────────────────
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection.';
  static const String fieldRequired = 'This field is required.';
  static const String invalidEmail = 'Please enter a valid email.';
  static const String passwordTooShort = 'Password must be at least 6 characters.';
  static const String passwordMismatch = 'Passwords do not match.';

  // ── Common ────────────────────────────────────────────────────────────────
  static const String loading = 'Loading...';
  static const String retry = 'Retry';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String search = 'Search books, authors...';
  static const String noResults = 'No results found.';
  static const String noBooks = 'No books listed yet.';
}

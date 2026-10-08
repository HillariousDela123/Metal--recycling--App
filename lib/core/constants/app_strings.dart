/// Centralized application strings for consistent UI and localization readiness.
class AppStrings {
  AppStrings._();

  static const String appName = 'EcoMetal';
  static const String appTagline = 'Sustainable Metal Recycling & Discovery';

  // Auth Strings
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to track recycling plans and view drop-off points';
  static const String registerTitle = 'Create Account';
  static const String registerSubtitle = 'Join our metal recycling community and earn eco-credits';
  static const String emailHint = 'Email Address';
  static const String passwordHint = 'Password';
  static const String nameHint = 'Full Name';
  static const String loginButton = 'Sign In';
  static const String registerButton = 'Create Account';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccount = "Don't have an account? Sign up";
  static const String alreadyHaveAccount = 'Already have an account? Sign in';

  // Metal Categories
  static const String metalSelectionTitle = 'Select Metal Type';
  static const String metalSelectionSubtitle = 'Choose scrap metal category to locate matching certified recyclers';
  static const String aluminum = 'Aluminium';
  static const String copper = 'Copper';
  static const String steel = 'Steel';
  static const String brass = 'Brass';
  static const String lead = 'Lead';
  static const String iron = 'Iron';

  // Discovery & Map
  static const String discoveryTitle = 'Recycling Centers';
  static const String searchHint = 'Search by name or accepted metal...';
  static const String filterAll = 'All Metals';
  static const String viewMap = 'Map View';
  static const String viewList = 'List View';
  static const String distanceKm = 'km away';
  static const String openNow = 'Open Now';
  static const String closedNow = 'Closed';

  // Plans & History
  static const String createPlanTitle = 'Schedule Recycling Plan';
  static const String weightHint = 'Estimated Weight (kg)';
  static const String dateHint = 'Select Scheduled Date';
  static const String reminderToggle = 'Receive Notification Reminder';
  static const String confirmPlan = 'Confirm Recycling Plan';
  static const String historyTitle = 'Activity & Recycling Log';
  static const String noActivities = 'No recycling activities yet. Schedule your first drop-off!';
}

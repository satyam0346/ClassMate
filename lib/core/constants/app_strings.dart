/// ClassMate static string constants.
/// All user-facing strings live here — makes localization easy in future.
abstract class AppStrings {
  // ── App ──────────────────────────────────────────────────
  static const String appName        = 'ClassMate';
  static const String appTagline     = 'Your academic companion';

  // ── Auth ─────────────────────────────────────────────────
  static const String login          = 'Login';
  static const String logout         = 'Logout';
  static const String register       = 'Register';
  static const String forgotPassword = 'Forgot Password?';
  static const String email          = 'Email';
  static const String password       = 'Password';
  static const String confirmPassword= 'Confirm Password';
  static const String fullName       = 'Full Name';
  static const String phone          = 'Phone Number';
  static const String rollNo         = 'Roll Number';
  static const String grNumber       = 'GR Number';
  static const String classLabel     = 'Class';
  static const String section        = 'Section';

  // ── Nav ──────────────────────────────────────────────────
  static const String navHome        = 'Home';
  static const String navTasks       = 'Tasks';
  static const String navTimetable   = 'Timetable';
  static const String navMaterials   = 'Materials';
  static const String navProfile     = 'Profile';
  static const String navAdmin       = 'Admin';

  // ── Tasks ────────────────────────────────────────────────
  static const String tasks          = 'Tasks';
  static const String addTask        = 'Add Task';
  static const String editTask       = 'Edit Task';
  static const String deleteTask     = 'Delete Task';
  static const String taskTitle      = 'Title';
  static const String taskDesc       = 'Description';
  static const String taskSubject    = 'Subject';
  static const String taskDueDate    = 'Due Date';
  static const String taskPriority   = 'Priority';
  static const String taskStatus     = 'Status';
  static const String filterAll      = 'All';
  static const String filterMy       = 'My Tasks';
  static const String filterClass    = 'Class Tasks';
  static const String filterOverdue  = 'Overdue';

  // ── Errors & Validation ──────────────────────────────────
  static const String errorRequired       = 'This field is required';
  static const String errorInvalidEmail   = 'Enter a valid email address';
  static const String errorDomainBlocked  =
      'Only @marwadiuniversity.ac.in or @gmail.com emails are allowed';
  static const String errorPasswordShort  = 'Password must be at least 8 characters';
  static const String errorPasswordMatch  = 'Passwords do not match';
  static const String errorTooManyAttempts=
      'Too many failed attempts. Try again in 60 seconds.';
  static const String errorOffline        = 'You\'re offline — showing cached data';

  // ── OTA ──────────────────────────────────────────────────
  static const String updateAvailable  = 'Update Available';
  static const String updateNow        = 'Update Now';
  static const String maintenance      = 'Under Maintenance';
  static const String maintenanceMsg   =
      'ClassMate is currently under maintenance. Please check back soon.';

  // ── Security warnings ────────────────────────────────────
  static const String rootedDevice  =
      'Security Warning: This device appears to be rooted. '
      'Some features may behave unexpectedly.';
  static const String emulatorDevice =
      'Warning: ClassMate is running on an emulator. '
      'This is not recommended for production use.';

  // ── FCM topics ───────────────────────────────────────────
  static const String fcmTopicAnnouncements = 'class_announcements';
  static const String fcmTopicMaterials     = 'class_materials';
  static const String fcmTopicTasks         = 'class_tasks';
  static const String fcmTopicTimetable     = 'class_timetable';
}

class RouteStrings {
  // =========================================================================
  // 1. AUTHENTICATION MODULE TRACKS (Universal Entryways)
  // =========================================================================
  static const String landing = '/';
  static const String login = '/login';
  static const String registration = '/register';
  static const String forgotPassword = '/forgot_password';
  static const String otpVerify = '/otp_verify';

  // =========================================================================
  // 2. CORE ROLE LANDING DASHBOARDS (Shell Context Holders)
  // =========================================================================
  static const String residentHome =
      '/home'; // Matches your exact resident tab shell
  static const String chairmanHome =
      '/chairman_home'; // Unique path to safely isolate executive controls

  // =========================================================================
  // 3. RESIDENT PROFILE & CORE FEATURE PANEL ENDPOINTS
  // =========================================================================
  static const String payMaintenance = '/maintenance';
  static const String amenities = '/amenities';
  static const String complaints = '/complaints';
  static const String vehicles = '/vehicles';
  static const String polls = '/polls';
  static const String lostFound = '/lost_found';
  static const String expenseReport = '/expense_report';
  static const String feedback = '/feedback';
  static const String meetings = '/meetings';
  static const String updateProfile = '/update_profile';
  static const String paymentHistory = '/payment_history';
  static const String updateNominee = '/update_nominee';
  static const String resetPassword = '/reset_password';

  // =========================================================================
  // 4. EXCLUSIVE ADMINISTRATIVE & CHAIRMAN CONTROL TRACKS
  // =========================================================================
  static const String societyReports = '/society_reports';
  static const String approveDecisions = '/approve_decisions';
  static const String manageNotices = '/manage_notices';
  static const String viewResidents = '/view_residents';
  static const String chatRoom = '/chat_room';
  static const String viewComplaints = '/view_complaints';
  static const String financialSummary = '/financial_summary';
  static const String triggerEmergency = '/trigger_emergency';
  static const String manageAssets = '/manage_assets';
  static const String bookAmenity = '/book_amenity';
  static const String participatePoll = '/participate_poll';
  static const String crudVehicles = '/crud_vehicles';
  static const String manageNominee = '/manage_nominee';
  static const String manageMeetings = '/manage_meetings';
  static const String lostFoundRegistry = '/lost_found_registry';
  static const String committeeManagement = '/committee_management';
}

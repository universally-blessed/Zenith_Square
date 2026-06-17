import 'package:flutter/material.dart';
import '../constants/route_strings.dart';

// 1. Navigation Shell Holder Location
import '../../features/navigation_holders/resident_navigation_holder.dart';

// 2. Feature Domain View Locations
import '../../features/finance/view/resident_pay_bill.dart';
import '../../features/finance/view/resident_payment_history.dart';
import '../../features/finance/view/shared_expense_report_page.dart';
import '../../features/complaints/view/resident_complaint_page.dart';
import '../../features/profile/view/update_profile.dart';
import '../../features/profile/view/update_nominee.dart';
import '../../features/profile/view/change_password_page.dart';

// 3. Independent Feature Modules Locations
import '../../features/amenities/view/book_amenities.dart';
import '../../features/vehicles/view/manage_vehicles.dart';
import '../../features/polls/view/active_polls_board.dart';
import '../../features/lost_found/view/lost_found_board.dart';
import '../../features/feedback/view/feedback.dart';
import '../../features/meetings/view/resident_view_meetings.dart';

class ResidentRoutes {
  static Map<String, WidgetBuilder> get routes => {
    // Keeps your exact endpoints intact so your buttons work perfectly!
    RouteStrings.residentHome: (context) => const ResidentNavigationHolder(),
    RouteStrings.payMaintenance: (context) => const MaintenancePaymentPage(),
    RouteStrings.amenities: (context) => const BookAmenitiesPage(),
    RouteStrings.complaints: (context) => const FileComplaintPage(),
    RouteStrings.vehicles: (context) => const MyVehiclesPage(),
    RouteStrings.polls: (context) => const ActivePollsPage(),
    RouteStrings.lostFound: (context) => const LostFoundPage(),
    RouteStrings.expenseReport: (context) => const SocietyExpenseReportPage(),
    RouteStrings.feedback: (context) => const GiveFeedbackPage(),
    RouteStrings.meetings: (context) => const ViewMeetingsPage(),
    RouteStrings.updateProfile: (context) => const UpdateProfilePage(),
    RouteStrings.paymentHistory: (context) => const PaymentHistoryPage(),
    RouteStrings.updateNominee: (context) => const UpdateNomineePageContent(),
    RouteStrings.resetPassword: (context) => const ChangePasswordPage(),
  };
}

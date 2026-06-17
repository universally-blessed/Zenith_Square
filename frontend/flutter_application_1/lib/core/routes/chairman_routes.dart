import 'package:flutter/material.dart';
import '../constants/route_strings.dart';

// 1. Core Panel Layout Configuration
import '../../features/navigation_holders/chairman_page.dart';

// 2. Core Administrative Feature Verticals
import '../../features/finance/view/chariman_ledger_summary.dart';
import '../../features/finance/view/chariman_pay_bill.dart';
import '../../features/complaints/view/chariman_complaint_page.dart';
import '../../features/notices/view/manage_notices_page.dart';
import '../../features/reports/view/society_page.dart';
import '../../features/decisions/view/approve_decision_page.dart';
import '../../features/meetings/view/chairman_manange_meetings.dart';
import '../../features/finance/view/shared_expense_report_page.dart';

// 3. Member, Asset, & Registry Domain Verticals
import '../../features/residents/view/view_residents_page.dart';
import '../../features/residents/view/chat_room_page.dart';
import '../../features/assets/view/manage_assets.dart';
import '../../features/amenities/view/book_amenities.dart';
import '../../features/lost_found/view/lost_found_board.dart';
import '../../features/committee/view/committee_management.dart';

// 4. Personal Profile & Security Handlers
import '../../features/profile/view/manage_profile.dart';
import '../../features/profile/view/nominee_details.dart';
import '../../features/profile/view/update_profile.dart';
import '../../features/profile/view/update_nominee.dart';
import '../../features/vehicles/view/manage_vehicles.dart';
import '../../features/polls/view/active_polls_board.dart';
import '../../features/security/view/emergency_log_page.dart';

class ChairmanRoutes {
  static Map<String, WidgetBuilder> get routes => {
    // Updated to use standardized RouteStrings to prevent path string duplication
    RouteStrings.chairmanHome: (context) => const ChairmanHomePage(
      chairmanData: {
        'user_name': 'Rahul Mahesh Shah',
        'society_name': 'Zenith Square',
      },
    ),
    RouteStrings.societyReports: (context) => const SocietyReportsPage(),
    RouteStrings.approveDecisions: (context) => const ApproveDecisionsPage(),
    RouteStrings.manageNotices: (context) => const ManageNoticesPage(),
    RouteStrings.viewResidents: (context) => const ViewResidentsPage(),
    RouteStrings.chatRoom: (context) => const ChatRoomPage(),
    RouteStrings.payMaintenance: (context) =>
        const ChairmanMaintenancePaymentPage(),
    RouteStrings.viewComplaints: (context) =>
        const ChairmanViewComplaintsPage(),
    RouteStrings.financialSummary: (context) =>
        const ChairmanFinancialSummaryPage(),
    RouteStrings.expenseReport: (context) => const SocietyExpenseReportPage(),

    // Your remaining unique administrative action endpoints
    '/trigger_emergency': (context) => const EmergencyLogPage(),
    '/manage_assets': (context) => const AssetRegistryPage(),
    '/manage_profile': (context) => const ManageProfilePage(),
    '/update_profile': (context) => const UpdateProfilePage(),
    '/book_amenity': (context) => const BookAmenitiesPage(),
    '/participate_poll': (context) => const ActivePollsPage(),
    '/crud_vehicles': (context) => const MyVehiclesPage(),
    '/manage_nominee': (context) => const NomineeDetailsPage(),
    '/update_nominee': (context) => const UpdateNomineePageContent(),
    '/manage_meetings': (context) => const ManageMeetingsPage(),
    '/lost_found_registry': (context) => const LostFoundPage(),
    '/committee_management': (context) => const CommitteeManagementPage(),
  };
}

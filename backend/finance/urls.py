from django.urls import path
from .views import (
    ResidentPendingBillView,
    SettleMaintenancePaymentView,
    ResidentPaymentHistoryView,
    SocietyExpensesView,
    ChairmanFinancialSummaryView,
    GenerateMaintenanceBillsView,
    SocietyExecutiveReportView,
    SocietyIncomeView,
    AllMaintenanceBillsView,
    OfflinePaymentView,
    AllReceiptsView,
    SocietyBankDetailsView,
    BlockMaintenanceReportView
)

urlpatterns = [
    path('bill/latest/', ResidentPendingBillView.as_view(), name='latest-bill'),
    path('bill/pay/', SettleMaintenancePaymentView.as_view(), name='pay-bill'),
    path('bills/generate/', GenerateMaintenanceBillsView.as_view(), name='generate-bills'),
    path('bills/all/', AllMaintenanceBillsView.as_view(), name='all-bills'),
    path('payment/history/', ResidentPaymentHistoryView.as_view(), name='payment-history'),
    path('payment/offline/', OfflinePaymentView.as_view(), name='offline-payment'),
    path('receipts/all/', AllReceiptsView.as_view(), name='all-receipts'),
    path('expenses/', SocietyExpensesView.as_view(), name='society-expenses'),
    path('income/', SocietyIncomeView.as_view(), name='society-income'),
    path('summary/', ChairmanFinancialSummaryView.as_view(), name='financial-summary'),
    path('executive-report/', SocietyExecutiveReportView.as_view(), name='executive-report'),
    path('bank-details/', SocietyBankDetailsView.as_view(), name='bank-details'),
    path('block-report/', BlockMaintenanceReportView.as_view(), name='block-maintenance-report'),
]

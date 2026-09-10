from django.urls import path
from .views import (
    ResidentPendingBillView,
    SettleMaintenancePaymentView,
    ResidentPaymentHistoryView,
    SocietyExpensesView,
    ChairmanFinancialSummaryView,
    GenerateMaintenanceBillsView,
    SocietyExecutiveReportView,
    SocietyIncomeView
)

urlpatterns = [
    path('bill/latest/', ResidentPendingBillView.as_view(), name='latest-bill'),
    path('bill/pay/', SettleMaintenancePaymentView.as_view(), name='pay-bill'),
    path('bills/generate/', GenerateMaintenanceBillsView.as_view(), name='generate-bills'),
    path('payment/history/', ResidentPaymentHistoryView.as_view(), name='payment-history'),
    path('expenses/', SocietyExpensesView.as_view(), name='society-expenses'),
    path('income/', SocietyIncomeView.as_view(), name='society-income'),
    path('summary/', ChairmanFinancialSummaryView.as_view(), name='financial-summary'),
    path('executive-report/', SocietyExecutiveReportView.as_view(), name='executive-report'),
]
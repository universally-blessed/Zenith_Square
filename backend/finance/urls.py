from django.urls import path
from .views import (
    ResidentPendingBillView,
    SettleMaintenancePaymentView,
    ResidentPaymentHistoryView,
    SocietyExpensesView,
    ChairmanFinancialSummaryView,
)

urlpatterns = [
    path('bill/latest/', ResidentPendingBillView.as_view(), name='latest-bill'),
    path('bill/pay/', SettleMaintenancePaymentView.as_view(), name='pay-bill'),
    path('payment/history/', ResidentPaymentHistoryView.as_view(), name='payment-history'),
    path('expenses/', SocietyExpensesView.as_view(), name='society-expenses'),
    path('summary/', ChairmanFinancialSummaryView.as_view(), name='financial-summary'),
]
from django.urls import path # type: ignore
from . import views

urlpatterns =[
    path('maintenance/current/', views.get_latest_maintenance_bill, name='api_current_bill'),
    path('maintenance/pay/', views.settle_maintenance_payment, name='api_pay_bill'),
    path('payments/history/', views.get_payment_history, name='api_payment_history'),
    path('expenses/', views.society_expense_report_api, name='api_expenses'),
]
from django.urls import path

from .views import EmployeeMeView

urlpatterns = [path("mobile/me/", EmployeeMeView.as_view(), name="mobile-me")]
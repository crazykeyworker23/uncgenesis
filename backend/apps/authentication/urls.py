from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from apps.authentication.views import (
    RegisterView,
    LoginView,
    GoogleAuthView,
    LogoutView,
    ForgotPasswordView,
    ResetPasswordView,
    ChangePasswordView,
    UserMeView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='auth_register'),
    path('login/', LoginView.as_view(), name='auth_login'),
    path('google/', GoogleAuthView.as_view(), name='auth_google'),
    path('token/refresh/', TokenRefreshView.as_view(), name='auth_token_refresh'),
    path('logout/', LogoutView.as_view(), name='auth_logout'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='auth_forgot_password'),
    path('reset-password/', ResetPasswordView.as_view(), name='auth_reset_password'),
    path('change-password/', ChangePasswordView.as_view(), name='auth_change_password'),
    path('me/', UserMeView.as_view(), name='auth_me'),
]

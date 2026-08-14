from django.contrib.auth import get_user_model
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.core.mail import send_mail
from django.conf import settings
from rest_framework import status, generics, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from drf_spectacular.utils import extend_schema

from apps.authentication.serializers import (
    UserRegisterSerializer,
    CustomTokenObtainPairSerializer,
    GoogleAuthSerializer,
    ForgotPasswordSerializer,
    ResetPasswordSerializer,
    ChangePasswordSerializer,
    UserMeSerializer,
)
from apps.authentication.services import verify_google_id_token

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    """
    Registra un nuevo usuario en la plataforma.
    """
    serializer_class = UserRegisterSerializer
    permission_classes = [permissions.AllowAny]

    @extend_schema(responses={201: UserMeSerializer})
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Opcional: Auto-asignar rol MEMBER de la comunidad
        from apps.roles.models import Role, UserRole, RoleType
        try:
            member_role = Role.objects.get(name=RoleType.MEMBER)
            UserRole.objects.create(user=user, role=member_role)
        except Exception:
            pass # Si no están poblados aún los roles
            
        headers = self.get_success_headers(serializer.data)
        response_serializer = UserMeSerializer(user)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED, headers=headers)


class LoginView(TokenObtainPairView):
    """
    Inicio de sesión estándar con correo y contraseña. Devuelve un access token y un refresh token.
    """
    serializer_class = CustomTokenObtainPairSerializer


class GoogleAuthView(APIView):
    """
    Autenticación y registro con Google OAuth.
    Recibe el token de Google, verifica el payload y devuelve tokens JWT de Génesis App.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(request=GoogleAuthSerializer, responses={200: dict})
    def post(self, request):
        serializer = GoogleAuthSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        id_token = serializer.validated_data['id_token']
        payload = verify_google_id_token(id_token)
        
        email = payload.get('email')
        google_id = payload.get('sub')
        first_name = payload.get('given_name', '')
        last_name = payload.get('family_name', '')

        # Buscar usuario por google_id o email
        user = User.objects.filter(google_id=google_id).first()
        if not user:
            user = User.objects.filter(email=email).first()
            if user:
                # Enlace de cuenta existente con Google
                user.google_id = google_id
                user.save()
            else:
                # Registro automático de nuevo usuario de Google
                user = User.objects.create_user(
                    email=email,
                    first_name=first_name,
                    last_name=last_name,
                    google_id=google_id,
                )
                
                # Asignar rol MEMBER inicial
                from apps.roles.models import Role, UserRole, RoleType
                try:
                    member_role = Role.objects.get(name=RoleType.MEMBER)
                    UserRole.objects.create(user=user, role=member_role)
                except Exception:
                    pass

        # Validar estado del usuario
        if user.status != 'ACTIVE':
            return Response(
                {"detail": "Esta cuenta se encuentra inactiva o bloqueada."},
                status=status.HTTP_403_FORBIDDEN
            )

        # Generar Tokens JWT
        refresh = RefreshToken.for_user(user)
        refresh['email'] = user.email
        refresh['full_name'] = user.full_name
        refresh['status'] = user.status

        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': UserMeSerializer(user).data
        }, status=status.HTTP_200_OK)


class LogoutView(APIView):
    """
    Cierra la sesión del usuario agregando el refresh token a la lista negra.
    """
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(request=dict, responses={205: None})
    def post(self, request):
        try:
            refresh_token = request.data.get("refresh")
            if not refresh_token:
                return Response({"detail": "El refresh token es obligatorio."}, status=status.HTTP_400_BAD_REQUEST)
                
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response(status=status.HTTP_205_RESET_CONTENT)
        except TokenError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class ForgotPasswordView(APIView):
    """
    Solicita el restablecimiento de la contraseña enviando un correo al usuario con un token seguro.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(request=ForgotPasswordSerializer, responses={200: dict})
    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            # Por seguridad, no revelamos si el correo existe o no en la base de datos
            return Response(
                {"detail": "Si el correo ingresado coincide con un usuario registrado, recibirás un enlace de recuperación pronto."},
                status=status.HTTP_200_OK
            )

        # Generar token seguro e identificador UID en base64
        uid = urlsafe_base64_encode(force_bytes(user.pk))
        token = default_token_generator.make_token(user)
        
        # Enviar correo de recuperación
        reset_link = f"{settings.FRONTEND_URL}/reset-password?uid={uid}&token={token}"
        
        # Intentamos enviar el correo electrónico
        try:
            send_mail(
                subject='Recuperación de contraseña - Génesis App',
                message=f'Hola {user.first_name},\n\nHemos recibido una solicitud para cambiar tu contraseña. Haz clic en el enlace para restablecerla:\n\n{reset_link}\n\nSi no realizaste esta solicitud, ignora este mensaje.',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=False,
            )
        except Exception as e:
            # En desarrollo podemos imprimir en consola si SMTP falla
            print(f"Error de envío de correo SMTP: {str(e)}. Enlace de recuperación: {reset_link}")

        return Response(
            {"detail": "Si el correo ingresado coincide con un usuario registrado, recibirás un enlace de recuperación pronto."},
            status=status.HTTP_200_OK
        )


class ResetPasswordView(APIView):
    """
    Restablece la contraseña utilizando el UID y token de recuperación enviados al correo.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(request=ResetPasswordSerializer, responses={200: dict})
    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # El uid y el token llegan por separado en la petición.
        uid = request.data.get('uid')
        token = request.data.get('token')
        
        if not uid or not token:
            return Response(
                {"detail": "El UID y el token son obligatorios para restablecer la contraseña."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            uid_decoded = force_str(urlsafe_base64_decode(uid))
            user = User.objects.get(pk=uid_decoded)
        except (TypeError, ValueError, OverflowError, User.DoesNotExist):
            return Response({"detail": "Enlace inválido o expirado."}, status=status.HTTP_400_BAD_REQUEST)

        # Validar el token de recuperación
        if not default_token_generator.check_token(user, token):
            return Response({"detail": "Enlace inválido o expirado."}, status=status.HTTP_400_BAD_REQUEST)

        # Guardar nueva contraseña
        user.set_password(serializer.validated_data['password'])
        user.save()

        return Response({"detail": "Contraseña restablecida con éxito."}, status=status.HTTP_200_OK)


class ChangePasswordView(APIView):
    """
    Permite al usuario cambiar su contraseña actual.
    """
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(request=ChangePasswordSerializer, responses={200: dict})
    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        
        user = request.user
        if not user.check_password(serializer.validated_data['old_password']):
            return Response({"old_password": ["La contraseña actual es incorrecta."]}, status=status.HTTP_400_BAD_REQUEST)
            
        user.set_password(serializer.validated_data['new_password'])
        user.save()
        return Response({"detail": "Contraseña cambiada con éxito."}, status=status.HTTP_200_OK)


class UserMeView(generics.RetrieveUpdateAPIView):
    """
    Obtiene y actualiza el perfil del usuario autenticado.
    """
    serializer_class = UserMeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

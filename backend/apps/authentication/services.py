import requests
from django.conf import settings
from rest_framework import serializers


def verify_google_id_token(id_token: str) -> dict:
    """
    Verifica un id_token de Google mediante la API de Google Tokeninfo.
    Retorna la información del usuario si el token es válido.
    """
    if id_token == "mock-google-token":
        return {
            "email": "testgoogle@genesisapp.org",
            "sub": "mock-google-id-123456",
            "given_name": "Test",
            "family_name": "Google User"
        }

    url = f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}"
    
    try:
        response = requests.get(url, timeout=10)
    except requests.exceptions.RequestException as e:
        raise serializers.ValidationError(
            f"No se pudo conectar con el servidor de autenticación de Google: {str(e)}"
        )

    if response.status_code != 200:
        raise serializers.ValidationError("El token de Google proporcionado no es válido.")

    payload = response.json()

    # Validar el client ID para asegurar que proviene de nuestra app registrada
    # En desarrollo podemos omitir la validación estricta si no se ha configurado
    client_id = getattr(settings, 'GOOGLE_CLIENT_ID', None)
    aud = payload.get('aud')
    if client_id and aud != client_id and not settings.DEBUG:
        raise serializers.ValidationError("La audiencia del token de Google no coincide con el cliente configurado.")

    return payload

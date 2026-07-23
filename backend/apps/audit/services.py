from apps.audit.models import AuditLog


def log_action(user, action, module, object_id, description, request=None):
    """
    Función de utilidad centralizada para registrar entradas de auditoría.
    Extrae la dirección IP y el User Agent del objeto de petición HTTP si se proporciona.
    """
    ip_address = None
    user_agent = ""

    if request:
        # Extraer dirección IP
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip_address = x_forwarded_for.split(',')[0].strip()
        else:
            ip_address = request.META.get('REMOTE_ADDR')

        # Extraer User Agent
        user_agent = request.META.get('HTTP_USER_AGENT', '')

    return AuditLog.objects.create(
        user=user,
        action=action,
        module=module,
        object_id=str(object_id) if object_id else "",
        description=description,
        ip_address=ip_address,
        user_agent=user_agent
    )

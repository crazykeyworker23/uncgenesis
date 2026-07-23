from django.db import models
from django.conf import settings


class AuditLog(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs'
    )
    action = models.CharField(max_length=50, db_index=True) # CREATE, EDIT, DELETE, BLOCK, etc.
    module = models.CharField(max_length=50, db_index=True) # USERS, PUBLICATIONS, etc.
    object_id = models.CharField(max_length=255, blank=True, db_index=True)
    description = models.TextField()
    ip_address = models.GenericIPAddressField(null=True, blank=True, db_index=True)
    user_agent = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = 'registro de auditoría'
        verbose_name_plural = 'registros de auditoría'
        ordering = ['-created_at']

    def __str__(self):
        user_email = self.user.email if self.user else "Anónimo"
        return f"[{self.created_at.strftime('%Y-%m-%d %H:%M')}] {user_email} - {self.action} on {self.module} ({self.object_id})"

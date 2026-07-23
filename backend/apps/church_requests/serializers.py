from rest_framework import serializers
from apps.users.models import CustomUser
from apps.cells.models import CellGroup
from .models import PrayerRequest, VisitorRequest


class AssigneeSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'email', 'first_name', 'last_name']


# ────────────────────────────────────────────
# Prayer Request Serializers
# ────────────────────────────────────────────

class PrayerRequestCreateSerializer(serializers.ModelSerializer):
    """Public serializer — submitted by app users without authentication."""

    class Meta:
        model = PrayerRequest
        fields = [
            'requester_name', 'requester_email', 'requester_phone',
            'subject', 'description', 'is_anonymous',
        ]


class PrayerRequestSerializer(serializers.ModelSerializer):
    """Full serializer for admin panel."""
    assigned_to = AssigneeSerializer(read_only=True)
    assigned_to_id = serializers.PrimaryKeyRelatedField(
        queryset=CustomUser.objects.all(),
        source='assigned_to',
        write_only=True,
        required=False,
        allow_null=True,
    )

    class Meta:
        model = PrayerRequest
        fields = [
            'id', 'requester_name', 'requester_email', 'requester_phone',
            'subject', 'description', 'is_anonymous',
            'status', 'assigned_to', 'assigned_to_id', 'notes',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


# ────────────────────────────────────────────
# Visitor Request Serializers
# ────────────────────────────────────────────

class CellGroupSimpleSerializer(serializers.ModelSerializer):
    class Meta:
        model = CellGroup
        fields = ['id', 'name', 'slug', 'meeting_day', 'meeting_time', 'address']


class VisitorRequestCreateSerializer(serializers.ModelSerializer):
    """Public serializer — submitted by app users."""
    cell_group_id = serializers.PrimaryKeyRelatedField(
        queryset=CellGroup.objects.all(),
        source='cell_group',
        required=False,
        allow_null=True
    )

    class Meta:
        model = VisitorRequest
        fields = [
            'full_name', 'email', 'phone',
            'age_range', 'how_did_you_find_us',
            'message', 'preferred_contact',
            'cell_group_id', 'user',
        ]


class VisitorRequestSerializer(serializers.ModelSerializer):
    """Full serializer for admin panel."""
    assigned_to = AssigneeSerializer(read_only=True)
    assigned_to_id = serializers.PrimaryKeyRelatedField(
        queryset=CustomUser.objects.all(),
        source='assigned_to',
        write_only=True,
        required=False,
        allow_null=True,
    )
    cell_group = CellGroupSimpleSerializer(read_only=True)
    cell_group_id = serializers.PrimaryKeyRelatedField(
        queryset=CellGroup.objects.all(),
        source='cell_group',
        write_only=True,
        required=False,
        allow_null=True,
    )

    class Meta:
        model = VisitorRequest
        fields = [
            'id', 'full_name', 'email', 'phone',
            'age_range', 'how_did_you_find_us',
            'message', 'preferred_contact',
            'status', 'assigned_to', 'assigned_to_id',
            'cell_group', 'cell_group_id', 'user', 'notes',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


# ────────────────────────────────────────────
# Action Serializers
# ────────────────────────────────────────────

class AssignSerializer(serializers.Serializer):
    assigned_to_id = serializers.PrimaryKeyRelatedField(
        queryset=CustomUser.objects.all(),
        allow_null=True,
    )


class ChangeStatusSerializer(serializers.Serializer):
    STATUS_CHOICES = [
        ('PENDING', 'Pendiente'),
        ('IN_PROGRESS', 'En proceso'),
        ('RESOLVED', 'Resuelto'),
        ('ARCHIVED', 'Archivado'),
    ]
    status = serializers.ChoiceField(choices=STATUS_CHOICES)
    notes = serializers.CharField(required=False, allow_blank=True)

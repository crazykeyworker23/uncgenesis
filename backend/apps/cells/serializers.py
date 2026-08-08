from rest_framework import serializers
from .models import CellGroup
from apps.users.models import CustomUser

class LeaderSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = CustomUser
        fields = ['id', 'email', 'first_name', 'last_name', 'full_name', 'status']

    def get_full_name(self, obj):
        full = f"{obj.first_name} {obj.last_name}".strip()
        return full if full else obj.email

class CellMemberSerializer(serializers.ModelSerializer):
    """Persona a cargo de un líder dentro de su célula."""

    full_name = serializers.SerializerMethodField()

    class Meta:
        model = CustomUser
        fields = [
            'id', 'email', 'first_name', 'last_name', 'full_name',
            'phone', 'location', 'status', 'avatar', 'created_at',
        ]

    def get_full_name(self, obj):
        full = f"{obj.first_name} {obj.last_name}".strip()
        return full if full else obj.email


class CellReminderSerializer(serializers.Serializer):
    """Recordatorio que un líder envía a los miembros de su célula."""

    title = serializers.CharField(max_length=150, required=False, allow_blank=True)
    body = serializers.CharField()
    scheduled_for = serializers.DateTimeField(required=False, allow_null=True)


class CellGroupSerializer(serializers.ModelSerializer):
    leader = LeaderSerializer(read_only=True)
    leader_id = serializers.PrimaryKeyRelatedField(
        queryset=CustomUser.objects.all(),
        source='leader',
        write_only=True,
        required=False,
        allow_null=True
    )
    coordinator = LeaderSerializer(read_only=True)
    coordinator_id = serializers.PrimaryKeyRelatedField(
        queryset=CustomUser.objects.all(),
        source='coordinator',
        write_only=True,
        required=False,
        allow_null=True
    )
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)

    class Meta:
        model = CellGroup
        fields = [
            'id', 'name', 'slug', 'leader', 'leader_id',
            'coordinator', 'coordinator_id',
            'meeting_day', 'meeting_time', 'address',
            'latitude', 'longitude', 'description',
            'status', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'slug', 'created_at', 'updated_at']

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

class CellGroupSerializer(serializers.ModelSerializer):
    leader = LeaderSerializer(read_only=True)
    leader_id = serializers.PrimaryKeyRelatedField(
        queryset=CustomUser.objects.all(), 
        source='leader', 
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
            'meeting_day', 'meeting_time', 'address', 
            'latitude', 'longitude', 'description', 
            'status', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'slug', 'created_at', 'updated_at']

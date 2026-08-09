from rest_framework import serializers
from .models import FCMDevice, Notification
from apps.users.models import CustomUser


class FCMDeviceSerializer(serializers.ModelSerializer):
    token = serializers.CharField()

    class Meta:
        model = FCMDevice
        fields = ['id', 'token', 'device_type', 'created_at', 'updated_at']

    def create(self, validated_data):
        # Allow linking authenticated user inside the ViewSet
        request = self.context.get('request')
        user = request.user if request and request.user.is_authenticated else None
        
        # Get or create token to prevent duplicates
        token = validated_data.get('token')
        device_type = validated_data.get('device_type', 'ANDROID')
        
        device, created = FCMDevice.objects.update_or_create(
            token=token,
            defaults={
                'user': user,
                'device_type': device_type
            }
        )
        return device


class NotificationSenderSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'email', 'first_name', 'last_name', 'full_name']


class NotificationSerializer(serializers.ModelSerializer):
    sender = NotificationSenderSerializer(read_only=True)
    target_user_detail = NotificationSenderSerializer(source='target_user', read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id', 'title', 'body', 'sender', 'target_audience', 'target_user',
            'target_user_detail', 'status', 'deep_link', 'scheduled_for',
            'sent_at', 'error_message', 'created_at'
        ]
        read_only_fields = ['status', 'sent_at', 'error_message', 'created_at']

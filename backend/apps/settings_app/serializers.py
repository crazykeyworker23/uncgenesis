from rest_framework import serializers
from apps.settings_app.models import AppSettings, ChurchSettings, ServiceSchedule, SocialNetwork


class AppSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = AppSettings
        fields = '__all__'


class ChurchSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChurchSettings
        fields = '__all__'


class ServiceScheduleSerializer(serializers.ModelSerializer):
    day_of_week_display = serializers.CharField(source='get_day_of_week_display', read_only=True)

    class Meta:
        model = ServiceSchedule
        fields = ('id', 'day_of_week', 'day_of_week_display', 'start_time', 'title', 'description')


class SocialNetworkSerializer(serializers.ModelSerializer):
    class Meta:
        model = SocialNetwork
        fields = '__all__'


class PublicSettingsSerializer(serializers.Serializer):
    app = AppSettingsSerializer()
    church = ChurchSettingsSerializer()
    schedules = ServiceScheduleSerializer(many=True)
    social_networks = SocialNetworkSerializer(many=True)

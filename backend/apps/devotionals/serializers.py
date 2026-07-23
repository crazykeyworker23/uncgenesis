from rest_framework import serializers
from apps.devotionals.models import Devotional
from apps.authentication.serializers import UserMeSerializer


class DevotionalSerializer(serializers.ModelSerializer):
    author = UserMeSerializer(read_only=True)

    class Meta:
        model = Devotional
        fields = '__all__'
        read_only_fields = ('author', 'views_count')

    def create(self, validated_data):
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            validated_data['author'] = request.user
        return super().create(validated_data)

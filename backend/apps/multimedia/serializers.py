from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Multimedia

User = get_user_model()


class UploaderSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name']


class MultimediaSerializer(serializers.ModelSerializer):
    uploaded_by = UploaderSerializer(read_only=True)
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = Multimedia
        fields = [
            'id', 'title', 'file', 'file_type', 'file_size',
            'uploaded_by', 'file_url', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'file_type', 'file_size', 'uploaded_by', 'file_url', 'created_at', 'updated_at']

    def get_file_url(self, obj):
        if obj.file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.file.url)
            return obj.file.url
        return None

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['uploaded_by'] = request.user
        return super().create(validated_data)

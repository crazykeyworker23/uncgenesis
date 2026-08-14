from rest_framework import serializers
from apps.events.models import Event, EventRegistration
from apps.authentication.serializers import UserMeSerializer


class EventRegistrationSerializer(serializers.ModelSerializer):
    user = UserMeSerializer(read_only=True)

    class Meta:
        model = EventRegistration
        fields = ['id', 'event', 'user', 'registered_at', 'status']
        read_only_fields = ['registered_at']


class EventSerializer(serializers.ModelSerializer):
    registered_count = serializers.IntegerField(read_only=True)
    is_registered = serializers.SerializerMethodField()

    class Meta:
        model = Event
        fields = '__all__'
        read_only_fields = ('registered_count', 'is_registered')

    def to_internal_value(self, data):
        if hasattr(data, 'copy'):
            data = data.copy()

        if 'cover_image' in data and (data['cover_image'] == '' or data['cover_image'] is None):
            data['cover_image'] = None

        self._existing_cover_image = None
        if 'cover_image' in data and isinstance(data['cover_image'], str) and data['cover_image'] != '':
            self._existing_cover_image = data['cover_image']
            data.pop('cover_image')

        return super().to_internal_value(data)

    def create(self, validated_data):
        existing_cover = getattr(self, '_existing_cover_image', None)
        instance = super().create(validated_data)
        if existing_cover:
            instance.cover_image = self._clean_media_path(existing_cover)
            instance.save(update_fields=['cover_image'])
        return instance

    def update(self, instance, validated_data):
        existing_cover = getattr(self, '_existing_cover_image', None)
        instance = super().update(instance, validated_data)
        if existing_cover is not None:
            instance.cover_image = self._clean_media_path(existing_cover)
            instance.save(update_fields=['cover_image'])
        return instance

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        if ret.get('cover_image'):
            url = str(ret['cover_image'])
            request = self.context.get('request')
            if request and not url.startswith('http'):
                ret['cover_image'] = request.build_absolute_uri(url)
            elif not url.startswith('http'):
                from django.conf import settings
                base = getattr(settings, 'BACKEND_URL', 'http://127.0.0.1:8000')
                ret['cover_image'] = f"{base}{url if url.startswith('/') else '/media/' + url}"
        return ret

    def _clean_media_path(self, url):
        if not url:
            return None
        if '://' in url:
            url = '/' + url.split('://', 1)[1].split('/', 1)[-1]
        if url.startswith('/media/'):
            return url[7:]
        if url.startswith('media/'):
            return url[6:]
        if url.startswith('/'):
            return url[1:]
        return url

    def get_is_registered(self, obj):
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if user and getattr(user, 'is_authenticated', False):
            return obj.registrations.filter(user=user, status='CONFIRMED').exists()
        return False

from rest_framework import serializers
from django.contrib.auth import get_user_model
from apps.publications.models import (
    PublicationCategory,
    PublicationTag,
    Publication,
    PublicationGallery,
)
from apps.authentication.serializers import UserMeSerializer

User = get_user_model()


class PublicationCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = PublicationCategory
        fields = '__all__'


class PublicationTagSerializer(serializers.ModelSerializer):
    class Meta:
        model = PublicationTag
        fields = '__all__'


class PublicationGallerySerializer(serializers.ModelSerializer):
    class Meta:
        model = PublicationGallery
        fields = '__all__'


class PublicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Publication
        fields = '__all__'
        read_only_fields = ('author', 'views_count', 'published_at')

    def to_internal_value(self, data):
        # Create a mutable copy of the data if possible
        if hasattr(data, 'copy'):
            data = data.copy()
            
        # Coerce empty string to None/null to avoid validation failure on ImageField
        if 'cover_image' in data and data['cover_image'] == '':
            data['cover_image'] = None

        # If cover_image is sent as a string (existing URL), extract it and bypass ImageField validation
        self._existing_cover_image = None
        if 'cover_image' in data and isinstance(data['cover_image'], str) and data['cover_image'] != '':
            self._existing_cover_image = data['cover_image']
            data.pop('cover_image')

        return super().to_internal_value(data)

    def create(self, validated_data):
        # Auto-assign author from request context
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            validated_data['author'] = request.user
            
        existing_cover = getattr(self, '_existing_cover_image', None)
        instance = super().create(validated_data)
        if existing_cover:
            instance.cover_image = self._clean_media_path(existing_cover)
            instance.save(update_fields=['cover_image'])
        return instance

    def update(self, instance, validated_data):
        existing_cover = getattr(self, '_existing_cover_image', None)
        instance = super().update(instance, validated_data)
        if existing_cover:
            instance.cover_image = self._clean_media_path(existing_cover)
            instance.save(update_fields=['cover_image'])
        return instance

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


class PublicationDetailSerializer(serializers.ModelSerializer):
    category = PublicationCategorySerializer(read_only=True)
    tags = PublicationTagSerializer(many=True, read_only=True)
    author = UserMeSerializer(read_only=True)
    gallery_images = PublicationGallerySerializer(many=True, read_only=True)

    class Meta:
        model = Publication
        fields = '__all__'

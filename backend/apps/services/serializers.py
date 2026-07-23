from rest_framework import serializers
from apps.services.models import ChurchService, ServiceVerse


class ServiceVerseSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)

    class Meta:
        model = ServiceVerse
        fields = ['id', 'book', 'chapter', 'verses', 'text']


class ChurchServiceSerializer(serializers.ModelSerializer):
    verses = ServiceVerseSerializer(many=True, required=False)

    class Meta:
        model = ChurchService
        fields = '__all__'
        read_only_fields = ('views_count',)

    def create(self, validated_data):
        verses_data = validated_data.pop('verses', [])
        service = ChurchService.objects.create(**validated_data)
        for verse in verses_data:
            ServiceVerse.objects.create(service=service, **verse)
        return service

    def update(self, instance, validated_data):
        verses_data = validated_data.pop('verses', [])
        instance = super().update(instance, validated_data)

        # Mantener los IDs enviados, eliminar los omitidos
        keep_ids = [v.get('id') for v in verses_data if v.get('id')]
        instance.verses.exclude(id__in=keep_ids).delete()

        for verse in verses_data:
            v_id = verse.get('id')
            if v_id:
                try:
                    v_instance = ServiceVerse.objects.get(id=v_id, service=instance)
                    v_instance.book = verse.get('book', v_instance.book)
                    v_instance.chapter = verse.get('chapter', v_instance.chapter)
                    v_instance.verses = verse.get('verses', v_instance.verses)
                    v_instance.text = verse.get('text', v_instance.text)
                    v_instance.save()
                except ServiceVerse.DoesNotExist:
                    # Si no existe por error, crearlo
                    verse.pop('id', None)
                    ServiceVerse.objects.create(service=instance, **verse)
            else:
                ServiceVerse.objects.create(service=instance, **verse)

        return instance

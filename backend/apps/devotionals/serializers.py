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


class WeeklyPlanDaySerializer(serializers.Serializer):
    """Un día del plan: qué se lee y qué se dice sobre ello."""

    bible_passage = serializers.CharField(max_length=150)
    content = serializers.CharField()


class WeeklyPlanSerializer(serializers.Serializer):
    """
    Plan de lecturas de una semana: siete días de una vez.

    Cargarlos uno a uno eran siete formularios, cada uno pidiendo título,
    pasaje, el texto bíblico completo y una reflexión. Para un plan como
    «lunes Hebreos 13, martes 1 Samuel 16…» era inviable cada semana.

    El plan se guarda como borrador. Los avisos no salen hasta publicarlo, de
    modo que un error de dedo no manda siete notificaciones equivocadas.
    """

    #: Lunes de la semana. El plan cubre ese día y los seis siguientes.
    start_date = serializers.DateField()
    days = WeeklyPlanDaySerializer(many=True)

    def validate_days(self, value):
        if len(value) != 7:
            raise serializers.ValidationError(
                'El plan cubre una semana: hacen falta los siete días.'
            )
        return value

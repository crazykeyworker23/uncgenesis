import datetime
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.contrib.auth import get_user_model

from apps.roles.models import Role, UserRole, RoleType
from apps.cells.models import CellGroup, MeetingDay, CellStatus
from apps.devotionals.models import Devotional, DevotionalStatus
from apps.events.models import Event, EventStatus
from apps.publications.models import Publication, PublicationCategory, PublicationStatus, PublicationContentType

User = get_user_model()


class Command(BaseCommand):
    help = 'Poblar la base de datos con datos reales iniciales para Génesis App'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('=== Iniciando sembrado de datos reales ==='))

        # 1. Crear Roles si no existen
        roles_dict = {}
        for r_type in RoleType:
            role_obj, _ = Role.objects.get_or_create(
                name=r_type.value,
                defaults={'description': r_type.label}
            )
            roles_dict[r_type.value] = role_obj

        # 2. Crear Usuarios Clave
        admin_user, _ = User.objects.get_or_create(
            email='admin@admin.com',
            defaults={
                'first_name': 'Administrador',
                'last_name': 'Génesis',
                'full_name': 'Administrador Génesis',
                'phone': '+51987654321',
                'is_staff': True,
                'is_superuser': True,
                'status': 'ACTIVE',
            }
        )
        admin_user.set_password('admin123')
        admin_user.save()
        UserRole.objects.get_or_create(user=admin_user, role=roles_dict[RoleType.SUPERADMIN])

        editor_user, _ = User.objects.get_or_create(
            email='pastor@iglesia.org',
            defaults={
                'first_name': 'Juan',
                'last_name': 'Pérez',
                'full_name': 'Pastor Juan Pérez',
                'phone': '+51912345678',
                'location': 'Lima, Perú',
                'bio': 'Pastor principal de la comunidad Génesis.',
                'status': 'ACTIVE',
                'is_staff': True,
            }
        )
        editor_user.set_password('pastor123')
        editor_user.save()
        UserRole.objects.get_or_create(user=editor_user, role=roles_dict[RoleType.CONTENT_EDITOR])

        lider1, _ = User.objects.get_or_create(
            email='lider.carlos@iglesia.org',
            defaults={
                'first_name': 'Carlos',
                'last_name': 'Mendoza',
                'full_name': 'Carlos Mendoza',
                'phone': '+51998877665',
                'location': 'San Isidro, Lima',
                'status': 'ACTIVE',
            }
        )
        lider1.set_password('lider123')
        lider1.save()
        UserRole.objects.get_or_create(user=lider1, role=roles_dict[RoleType.CELL_LEADER])

        lider2, _ = User.objects.get_or_create(
            email='lider.maria@iglesia.org',
            defaults={
                'first_name': 'María',
                'last_name': 'Rojas',
                'full_name': 'María Rojas',
                'phone': '+51944556677',
                'location': 'Surco, Lima',
                'status': 'ACTIVE',
            }
        )
        lider2.set_password('lider123')
        lider2.save()
        UserRole.objects.get_or_create(user=lider2, role=roles_dict[RoleType.CELL_LEADER])

        self.stdout.write(self.style.SUCCESS('✓ Usuarios y roles creados correctamente.'))

        # 3. Crear Células / Grupos Pequeños
        c1, _ = CellGroup.objects.get_or_create(
            name='Célula Ebenezer - San Isidro',
            defaults={
                'leader': lider1,
                'meeting_day': MeetingDay.THURSDAY,
                'meeting_time': datetime.time(19, 30),
                'address': 'Av. Javier Prado Este 1234, San Isidro',
                'latitude': -12.0897,
                'longitude': -77.0342,
                'description': 'Grupo de estudio bíblico y comunión para jóvenes profesionales en San Isidro.',
                'status': CellStatus.ACTIVE,
            }
        )

        c2, _ = CellGroup.objects.get_or_create(
            name='Célula Shalom - Surco',
            defaults={
                'leader': lider2,
                'meeting_day': MeetingDay.FRIDAY,
                'meeting_time': datetime.time(20, 0),
                'address': 'Calle Los Álamos 456, Surco',
                'latitude': -12.1324,
                'longitude': -76.9854,
                'description': 'Reunión familiar de edificación y oración todos los viernes por la noche.',
                'status': CellStatus.ACTIVE,
            }
        )

        self.stdout.write(self.style.SUCCESS('✓ Grupos de célula creados correctamente.'))

        # 4. Crear Devocionales
        today = timezone.now().date()
        Devotional.objects.get_or_create(
            date=today,
            defaults={
                'title': 'Fortaleza en Tiempos de Cambio',
                'bible_passage': 'Josué 1:9',
                'bible_text': 'Mira que te mando que te esfuerces y seas valiente; no temas ni desmayes, porque Jehová tu Dios estará contigo en dondequiera que vayas.',
                'content': 'En cada etapa de nuestra vida enfrentamos desafíos que pueden hacernos dudar. Sin embargo, la promesa divina nos recuerda que no caminamos solos. La verdadera valentía no es la ausencia de miedo, sino la certeza de la presencia de Dios en cada paso.',
                'author': editor_user,
                'status': DevotionalStatus.PUBLISHED,
            }
        )

        Devotional.objects.get_or_create(
            date=today - datetime.timedelta(days=1),
            defaults={
                'title': 'El Poder de la Fe y la Oración',
                'bible_passage': 'Filipenses 4:6-7',
                'bible_text': 'Por nada estéis afanosos, sino sean conocidas vuestras peticiones delante de Dios en toda oración y ruego, con acción de gracias.',
                'content': 'La paz de Dios sobrepasa todo entendimiento humano. Cuando entregamos nuestras preocupaciones en oración sincera, abrimos nuestro corazón a la tranquilidad celestial.',
                'author': editor_user,
                'status': DevotionalStatus.PUBLISHED,
            }
        )

        self.stdout.write(self.style.SUCCESS('✓ Devocionales publicados correctamente.'))

        # 5. Crear Eventos
        now = timezone.now()
        Event.objects.get_or_create(
            title='Culto Dominical de Celebración',
            defaults={
                'description': 'Acompáñanos este domingo a nuestro culto presencial y transmitido en vivo. Tiempo de alabanza, palabra inspiradora y comunión.',
                'start_date': now + datetime.timedelta(days=3),
                'end_date': now + datetime.timedelta(days=3, hours=2),
                'location': 'Auditorio Principal Génesis - Av. Arequipa 2500',
                'requires_registration': False,
                'status': EventStatus.PUBLISHED,
            }
        )

        Event.objects.get_or_create(
            title='Noche de Oración y Alabanza',
            defaults={
                'description': 'Una noche especial dedicada a buscar la presencia de Dios en oración unida, intercesión y adoración.',
                'start_date': now + datetime.timedelta(days=7),
                'end_date': now + datetime.timedelta(days=7, hours=3),
                'location': 'Auditorio Principal Génesis',
                'requires_registration': True,
                'capacity': 200,
                'status': EventStatus.PUBLISHED,
            }
        )

        self.stdout.write(self.style.SUCCESS('✓ Eventos creados correctamente.'))

        # 6. Crear Categorías y Publicaciones
        cat_noticias, _ = PublicationCategory.objects.get_or_create(
            name='Noticias de la Comunidad',
            defaults={'description': 'Novedades y anuncios importantes de Génesis App.'}
        )

        cat_eventos, _ = PublicationCategory.objects.get_or_create(
            name='Comunidad y Ministerios',
            defaults={'description': 'Actividades ministeriales y proyectos sociales.'}
        )

        Publication.objects.get_or_create(
            title='¡Bienvenidos a la nueva plataforma digital Génesis App!',
            defaults={
                'summary': 'Nos alegra lanzar nuestra nueva plataforma integral para conectar a toda nuestra comunidad e iglesia.',
                'content': 'Estamos emocionados de presentar la versión web y móvil de Génesis App. A través de este portal podrás acceder a devocionales diarios, inscribirte en eventos, ubicar tu célula más cercana y enviar peticiones de oración.',
                'category': cat_noticias,
                'content_type': PublicationContentType.NEWS,
                'author': editor_user,
                'status': PublicationStatus.PUBLISHED,
                'published_at': now,
                'is_featured': True,
                'show_in_app': True,
            }
        )

        Publication.objects.get_or_create(
            title='Inicio del Programa de Células y Grupos Pequeños 2026',
            defaults={
                'summary': 'Te invitamos a integrarte a un grupo pequeño cerca de tu hogar.',
                'content': 'Las células son el corazón de nuestra comunidad. Encuentra un espacio de amistad, crecimiento espiritual y apoyo mutuo cada semana en tu distrito.',
                'category': cat_eventos,
                'content_type': PublicationContentType.GENERAL,
                'author': editor_user,
                'status': PublicationStatus.PUBLISHED,
                'published_at': now - datetime.timedelta(days=2),
                'is_featured': False,
                'show_in_app': True,
            }
        )

        self.stdout.write(self.style.SUCCESS('=== Datos reales poblados exitosamente en Génesis App ==='))

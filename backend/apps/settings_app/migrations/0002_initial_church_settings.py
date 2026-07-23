from django.db import migrations
import datetime


def populate_church_settings(apps, schema_editor):
    AppSettings = apps.get_model('settings_app', 'AppSettings')
    ChurchSettings = apps.get_model('settings_app', 'ChurchSettings')
    ServiceSchedule = apps.get_model('settings_app', 'ServiceSchedule')
    SocialNetwork = apps.get_model('settings_app', 'SocialNetwork')

    # AppSettings
    AppSettings.objects.create(
        pk=1,
        app_name="Génesis App",
        app_description="Aplicación oficial de la Iglesia Génesis. Conéctate, crece y participa.",
        splash_text="Una casa para todos",
        primary_color="#032F2F", # Deep Teal
        secondary_color="#D4AF37", # Dorado
        privacy_policy_url="https://genesisunnuevocomenzar.org/privacy-policy",
        terms_url="https://genesisunnuevocomenzar.org/terms"
    )

    # ChurchSettings
    ChurchSettings.objects.create(
        pk=1,
        church_name="Iglesia Génesis",
        address="Carretera Iquitos-Nauta Km 1.5, Loreto",
        city="Iquitos",
        country="Perú",
        phone="",
        whatsapp="+51 931 405 531",
        email="genesisweeklyminute@gmail.com",
        website="genesisunnuevocomenzar.org",
        latitude=-3.771966,
        longitude=-73.308226
    )

    # ServiceSchedules
    ServiceSchedule.objects.create(
        day_of_week='SUNDAY',
        start_time=datetime.time(10, 0),
        title="Culto General Dominical",
        description="Ven con tu familia a adorar y aprender de la Palabra de Dios."
    )
    ServiceSchedule.objects.create(
        day_of_week='SUNDAY',
        start_time=datetime.time(18, 0),
        title="Culto de Jóvenes",
        description="Una reunión juvenil radical, moderna e inspiradora."
    )

    # SocialNetworks
    SocialNetwork.objects.create(
        name="Facebook",
        url="https://www.facebook.com/IglesiaGenesisIquitos",
        icon_name="facebook"
    )
    SocialNetwork.objects.create(
        name="Instagram",
        url="https://www.instagram.com/IglesiaGenesisIquitos",
        icon_name="instagram"
    )


def rollback_church_settings(apps, schema_editor):
    AppSettings = apps.get_model('settings_app', 'AppSettings')
    ChurchSettings = apps.get_model('settings_app', 'ChurchSettings')
    ServiceSchedule = apps.get_model('settings_app', 'ServiceSchedule')
    SocialNetwork = apps.get_model('settings_app', 'SocialNetwork')

    AppSettings.objects.all().delete()
    ChurchSettings.objects.all().delete()
    ServiceSchedule.objects.all().delete()
    SocialNetwork.objects.all().delete()


class Migration(migrations.Migration):

    dependencies = [
        ('settings_app', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(populate_church_settings, rollback_church_settings),
    ]

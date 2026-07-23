import os
from celery import Celery

# Set default Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')

app = Celery('genesis')

# Configure Celery using Django settings (CELERY_* settings keys)
app.config_from_object('django.conf:settings', namespace='CELERY')

# Automatically discover tasks.py in all registered apps
app.autodiscover_tasks()


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f'Request: {self.request!r}')

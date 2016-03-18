from __future__ import absolute_import

import os
from datetime import timedelta

from celery import Celery

from .settings import CELERY_AUTOCONFIRM_CLASSES_INTERVAL

# set the default Django settings module for the 'celery' program.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')

from django.conf import settings  # noqa
import logging

logger = logging.getLogger('app')

celery_app = Celery('server')

# Using a string here means the worker will not have to
# pickle the object when using Windows.
celery_app.config_from_object('django.conf:settings')
celery_app.autodiscover_tasks(lambda: settings.INSTALLED_APPS)

celery_app.conf.update(
    CELERY_ROUTES={
        "proj.tasks.add":{"queue":"hipri"},# 把add任务放入hipri队列
        # 需要执行时指定队列 add.apply_async((2, 2), queue='hipri')
        },
    CELERYBEAT_SCHEDULE={
        "add":{
            "task":"app.tasks.autoConfirmClasses",
            "schedule":timedelta(seconds=CELERY_AUTOCONFIRM_CLASSES_INTERVAL),
            },
        },
    )

if __name__ == "__main__":
    celery_app.start()


@celery_app.task(bind=True)
def debug_task(self):
    logger.debug('Request: {0!r}'.format(self.request))

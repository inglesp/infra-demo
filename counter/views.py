from django.conf import settings
from django.http import HttpResponse

from counter.models import Visit


def index(request):
    Visit.objects.create()
    count = Visit.objects.count()
    return HttpResponse(
        f"This page has been visited {count} times.\nBuild: {settings.GIT_COMMIT}",
        content_type="text/plain",
    )

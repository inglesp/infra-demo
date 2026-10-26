from django.conf import settings
from django.http import HttpResponse

from counter.models import Visit


def index(request):
    Visit.objects.create()
    count = Visit.objects.count()
    return HttpResponse(
        f"Visit count: {count}\n"
        f"Build: {settings.GIT_COMMIT}\n"
        f"Secret: {settings.DEMO_SECRET or 'not set'}\n",
        content_type="text/plain",
    )

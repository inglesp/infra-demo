from django.http import HttpResponse


def health_check(get_response):
    """Answer /health/ before the host is checked against ALLOWED_HOSTS.

    Dokku's health checks call the container directly, without the app's domain.
    """

    def middleware(request):
        if request.path == "/health/":
            return HttpResponse("ok", content_type="text/plain")
        return get_response(request)

    return middleware

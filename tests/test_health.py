import json

from django.conf import settings


def test_app_json_health_checks_are_answered(client):
    app_json = json.loads((settings.BASE_DIR / "app.json").read_text())
    for check in app_json["healthchecks"]["web"]:
        assert client.get(check["path"], HTTP_HOST="10.0.0.1").status_code == 200

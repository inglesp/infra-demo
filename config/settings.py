from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# Development only: never use this key in production.
SECRET_KEY = "django-insecure-dev-key"

DEBUG = True

ALLOWED_HOSTS = []

INSTALLED_APPS = ["counter"]

ROOT_URLCONF = "config.urls"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

USE_TZ = True

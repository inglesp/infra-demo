import pytest


@pytest.mark.django_db
def test_index_counts_visits(client):
    assert "Visit count: 1\n" in client.get("/").text
    assert "Visit count: 2\n" in client.get("/").text


@pytest.mark.django_db
def test_index_shows_secret(client, settings):
    settings.DEMO_SECRET = "hello"
    assert "Secret: hello" in client.get("/").text


@pytest.mark.django_db
def test_index_shows_secret_not_set(client, settings):
    settings.DEMO_SECRET = ""
    assert "Secret: not set" in client.get("/").text


def test_unknown_host_is_rejected(client):
    assert client.get("/", HTTP_HOST="evil.example").status_code == 400

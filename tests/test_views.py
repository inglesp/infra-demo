import pytest


@pytest.mark.django_db
def test_index_counts_visits(client):
    assert "visited 1 times" in client.get("/").text
    assert "visited 2 times" in client.get("/").text

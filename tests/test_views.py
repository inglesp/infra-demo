import pytest


@pytest.mark.django_db
def test_index_counts_visits(client):
    assert client.get("/").text == "This page has been visited 1 times."
    assert client.get("/").text == "This page has been visited 2 times."

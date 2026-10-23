def test_health_check_ignores_host(client):
    response = client.get("/health/", HTTP_HOST="10.0.0.1:8000")
    assert response.status_code == 200
    assert response.text == "ok"

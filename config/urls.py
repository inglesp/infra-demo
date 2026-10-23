from django.urls import path

from counter import views

urlpatterns = [
    path("", views.index),
]

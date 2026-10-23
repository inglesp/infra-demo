default:
    @just --list

# Run the development server
run:
    uv run manage.py migrate
    uv run manage.py runserver

# Run the tests
test:
    uv run pytest

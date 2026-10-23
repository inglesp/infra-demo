default:
    @just --list

# Run the development server
run:
    DJANGO_DEBUG=1 uv run manage.py migrate
    DJANGO_DEBUG=1 uv run manage.py runserver

# Run the tests
test:
    DJANGO_DEBUG=1 uv run pytest

# Check formatting, lint, and run the tests
check:
    uv run ruff format --check
    uv run ruff check
    just test

# Fix lint and formatting where possible
fix:
    uv run ruff check --fix
    uv run ruff format

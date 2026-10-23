default:
    @just --list

# Run the development server
run:
    uv run manage.py migrate
    uv run manage.py runserver

# Run the tests
test:
    uv run pytest

# Check formatting, lint, and run the tests
check:
    uv run ruff format --check
    uv run ruff check
    just test

# Fix lint and formatting where possible
fix:
    uv run ruff check --fix
    uv run ruff format

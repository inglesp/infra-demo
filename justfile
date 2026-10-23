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

# Build the container image
docker-build:
    docker build -t infra-demo --build-arg GIT_COMMIT=$(git rev-parse HEAD) .

# Run the app in a container, keeping its data in the infra-demo-data volume
docker-run: docker-build
    docker run --rm -p 8000:8000 \
        -e DJANGO_SECRET_KEY=insecure-docker-run-key \
        -e DJANGO_ALLOWED_HOSTS=localhost \
        -v infra-demo-data:/data \
        infra-demo

# Run OpenTofu in infra/tofu, e.g. `just tofu init`
tofu *args:
    tofu -chdir=infra/tofu {{args}}

# Show what OpenTofu would change
plan: (tofu "plan")

# Apply OpenTofu's changes
apply: (tofu "apply")

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

# Check OpenTofu formatting and validity, and Ansible syntax (needs no credentials)
check-infra:
    just tofu fmt -check -recursive
    just tofu init -backend=false -input=false
    just tofu validate
    cd infra/ansible && uv run --group infra ansible-playbook --syntax-check -i localhost, playbook.yml

# Configure the droplets with Ansible, e.g. `just configure --check --diff`
configure *args:
    #!/usr/bin/env bash
    set -euo pipefail
    inventory=$(mktemp --suffix .json)
    trap 'rm -f "$inventory"' EXIT
    just tofu output -json ansible_inventory > "$inventory"
    cd infra/ansible
    uv run --group infra ansible-playbook -i "$inventory" playbook.yml {{args}}

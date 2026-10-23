FROM python:3.15-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:0.13.4 /uv /usr/local/bin/uv

# UV_COMPILE_BYTECODE: compile .py files to .pyc at install time, so the app
#   starts faster and doesn't try to write .pyc files at runtime
# UV_PYTHON_DOWNLOADS: use the image's Python rather than downloading one
ENV UV_COMPILE_BYTECODE=1 UV_PYTHON_DOWNLOADS=never

WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev


# The final image has the venv but not uv or its cache. The venv's Python is a
# symlink to the base image's, so both stages must use the same base image.
FROM python:3.15-slim

# gunicorn's control server needs a writable home directory
RUN groupadd --gid 10001 app && useradd --uid 10001 --gid 10001 --create-home app

WORKDIR /app

COPY --from=builder /app/.venv /app/.venv
COPY . .

# The code stays owned by root, so the app can only write to /data (and its
# home directory)
RUN mkdir /data && chown app:app /data

ENV PATH="/app/.venv/bin:$PATH" DATABASE_PATH=/data/db.sqlite3

# The commit the image was built from, shown on the page. This changes on every
# build, so it comes late, after the layers it would otherwise invalidate.
ARG GIT_COMMIT=unknown
ENV GIT_COMMIT=$GIT_COMMIT

USER 10001:10001

EXPOSE 8000

# exec, so that gunicorn is PID 1 and receives signals from `docker stop`
CMD ["sh", "-c", "python manage.py migrate --noinput && exec gunicorn config.wsgi --bind 0.0.0.0:8000"]

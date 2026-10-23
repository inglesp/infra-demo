FROM python:3.15-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# UV_COMPILE_BYTECODE: compile .py files to .pyc at install time, so the app
#   starts faster and doesn't try to write .pyc files at runtime
# UV_PYTHON_DOWNLOADS: use the image's Python rather than downloading one
ENV UV_COMPILE_BYTECODE=1 UV_PYTHON_DOWNLOADS=never

WORKDIR /app

# Install dependencies before copying the code, so that code changes don't
# invalidate this layer
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev

COPY . .

RUN mkdir /data

ENV PATH="/app/.venv/bin:$PATH" DATABASE_PATH=/data/db.sqlite3

EXPOSE 8000

# exec, so that gunicorn is PID 1 and receives signals from `docker stop`
CMD ["sh", "-c", "python manage.py migrate --noinput && exec gunicorn config.wsgi --bind 0.0.0.0:8000"]

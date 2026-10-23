# infra-demo

A small Django app that counts visits to its one page.
It's a demo app for setting up infrastructure and configuration as code.

## Running locally

You need [just](https://github.com/casey/just) and [uv](https://docs.astral.sh/uv/).

```sh
just run
```

Then open http://localhost:8000.
The visit count is stored in `db.sqlite3`.

## Running in Docker

You also need [Docker](https://docs.docker.com/get-docker/).

```sh
just docker-run
```

Then open http://localhost:8000.
This builds the image and runs it with gunicorn, applying migrations first.
The page shows the commit the image was built from.
The visit count is stored in the `infra-demo-data` Docker volume, so it survives restarts.
To start again from zero, run `docker volume rm infra-demo-data`.

## Configuration

The app is configured with environment variables:

| Variable | Default | |
|---|---|---|
| `DJANGO_DEBUG` | off | Set to `1` to turn on debug mode |
| `DJANGO_SECRET_KEY` | required, unless in debug mode | |
| `DJANGO_ALLOWED_HOSTS` | none | Comma-separated; in debug mode, localhost is always allowed |
| `DATABASE_PATH` | `db.sqlite3` | Path to the SQLite database |

`just run` and `just test` set `DJANGO_DEBUG=1` for you.
If you run `manage.py` or `pytest` directly, set it yourself.

## Tests and checks

```sh
just test   # run the tests
just check  # check formatting and lint, and run the tests
just fix    # fix formatting and lint where possible
```

CI runs `just check` on every pull request and on pushes to `main`.

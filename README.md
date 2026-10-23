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
Its actions are pinned to commit SHAs.

## Published image

On every push to `main`, CI publishes the image to ghcr.io with two tags:

- `ghcr.io/inglesp/infra-demo:latest`
- `ghcr.io/inglesp/infra-demo:sha-<commit>`, where `<commit>` is the full commit SHA

On pull requests, CI builds the image but doesn't publish it.

## Infrastructure

The app runs on a DigitalOcean droplet, managed with [OpenTofu](https://opentofu.org/) in `infra/tofu/`.
Each app in `local.apps` in `infra/tofu/main.tf` gets its own droplet, created by the `web-app` module.

You need:

- [OpenTofu](https://opentofu.org/docs/intro/install/), [doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/) and [jq](https://jqlang.org/)
- a DigitalOcean API token with full access, named `infra-demo-tofu-local`, exported as `DIGITALOCEAN_ACCESS_TOKEN` (OpenTofu and doctl both read it)
- your SSH public key uploaded to DigitalOcean with the name in `local.ssh_key_name`:

  ```sh
  doctl compute ssh-key import inglesp --public-key-file ~/.ssh/id_ed25519.pub
  ```

```sh
just tofu init  # once, to download the provider
just plan       # show what would change
just apply      # make the changes
```

`just tofu ...` runs any other OpenTofu command in `infra/tofu/`.

OpenTofu's state is kept locally, in `infra/tofu/terraform.tfstate`, and isn't committed.
So for now, only one person can manage the infrastructure.

## Runbook

### SSH into a droplet

```sh
ssh root@$(just tofu output -json ips | jq -r '.["infra-demo"]')
```

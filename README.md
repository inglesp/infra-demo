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
The page shows the commit the image was built from, and the value of `DEMO_SECRET`, a secret with no use, which shows that secrets reach the app.
`/health/` returns `ok` for health checks, whatever the request's `Host` header.
Dokku uses it, as set in `app.json`, to check that a new container is healthy before switching traffic to it.
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
| `DEMO_SECRET` | none | A secret with no use, which the page shows |

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
Each droplet has a block storage volume attached, for all persistent data, so that the droplet itself can be replaced.
OpenTofu refuses to destroy a volume: to really delete one, first remove `prevent_destroy` from the `web-app` module.
Changing a droplet's image or SSH keys only affects new droplets, rather than replacing existing ones.
Each droplet has a cloud firewall that allows inbound SSH, HTTP, HTTPS and ICMP, and all outbound traffic.
Each app also has its own DNS zone in DigitalOcean, such as `infra-demo.opensafely.org`, with A and AAAA records pointing at its droplet.

At a droplet's first boot, cloud-init writes its settings and secrets to `/etc/web-app/`, installs Ansible, and runs `ansible-pull` against `main` of this repo, which configures the droplet (see [Server configuration](#server-configuration)).
Changing the cloud-init config (the droplet's `user_data`) replaces the droplet: see [After a droplet is replaced](#after-a-droplet-is-replaced).

You need:

- [OpenTofu](https://opentofu.org/docs/intro/install/), [doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/) and [jq](https://jqlang.org/)
- a DigitalOcean API token with full access, named `infra-demo-tofu-local`, exported as `DIGITALOCEAN_ACCESS_TOKEN` (OpenTofu and doctl both read it)
- your SSH public key uploaded to DigitalOcean with the name in `local.ssh_key_name`:

  ```sh
  doctl compute ssh-key import inglesp --public-key-file ~/.ssh/id_ed25519.pub
  ```

- a Spaces access key named `infra-demo-tofu-state-local`, with read/write access to the state bucket (see below), exported as `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- the state passphrase, from the password manager, exported as `TF_VAR_state_passphrase`
- each app's zone delegated to DigitalOcean: opensafely.org's DNS is on Cloudflare, which has NS records for `infra-demo` pointing to `ns1.digitalocean.com`, `ns2.digitalocean.com` and `ns3.digitalocean.com`

```sh
just tofu init  # once, to download the provider and connect to the state bucket
just plan       # show what would change
just apply      # make the changes
```

`just tofu ...` runs any other OpenTofu command in `infra/tofu/`.

`just check-infra` checks that the OpenTofu config is formatted and valid, and that the Ansible playbook's syntax is valid.
It needs no credentials, and CI runs it on every pull request and on pushes to `main`.

OpenTofu's state is kept in the `inglesp-infra-demo-tofu-state` Spaces bucket, in `lon1`.
The bucket was created by hand, since it can't hold its own state.
The state is encrypted with the state passphrase: if the passphrase is lost, so is the state.
The state holds secrets, such as each app's Django secret key, which OpenTofu generates and puts in the droplet's `user_data`.
State isn't locked, so only one person should run `just apply` at a time.

## Server configuration

What runs on each droplet is configured with [Ansible](https://docs.ansible.com/), in `infra/ansible/`.
Each droplet configures itself: every minute, before deploying (see [Deploys](#deploys)), it runs `ansible-pull`, which applies the playbook from `main` if `main` has changed since the last run.
So a change merged to `main` is applied within a minute or so.
If applying the playbook fails, the run still deploys the image, but shows as a failed `deploy` unit, and the next run tries the playbook again.
That's the only way config reaches a droplet.

Ansible installs Docker, [Dokku](https://dokku.com/) and Dokku's [letsencrypt plugin](https://github.com/dokku/dokku-letsencrypt) (setting its email and adding its renewal cron job), and mounts each droplet's volume at `/srv/<app>/data` with an `/etc/fstab` entry.
The mount point is owned by UID 10001, which the app runs as in its image.
It blocks containers from DigitalOcean's metadata service, which serves the droplet's `user_data`, and so its secrets, to anything on the droplet that asks.
DigitalOcean mounts a newly attached volume under `/mnt/` itself, and Ansible removes that mount.
It also creates the app in Dokku, routes ports 80 and 443 to it, and sets its domain and its environment (from `app_env` in the `web_app` role's defaults).
It mounts the volume into the app's container at `/data`, so the app's database lives on the volume.
Once the app has been deployed, the deploy service (see [Deploys](#deploys)) gets it a TLS certificate from Let's Encrypt, which the cron job renews.
HTTP then redirects to HTTPS, and Dokku turns on HSTS, so browsers that have visited will only use HTTPS for the domain.

Dokku has no declarative config, only commands, so Ansible reads each Dokku setting first and only runs a command when the setting differs.

### Secrets

Secrets that OpenTofu doesn't generate are kept in the repo, encrypted with [ansible-vault](https://docs.ansible.com/ansible/latest/vault_guide/index.html), in `infra/ansible/host_vars/<app>/vault.yml`.
Each app's vault has its own password, which OpenTofu generates, and which is on the app's droplet, so the droplet can decrypt it.
To edit an app's secrets in `$EDITOR`, creating the file if needed:

```sh
just vault-edit infra-demo
```

To give the app a secret environment variable, add it under `app_secret_env` in the vault:

```yaml
app_secret_env:
  SOME_API_KEY: ...
```

Removing a variable from the vault doesn't remove it from the app: run `dokku config:unset <app> <variable>` on the droplet.

### Deploys

Each app's image and tag are set in `infra/ansible/host_vars/<app>/main.yml`, which Ansible writes to `/etc/web-app/image` on the droplet.
Every minute, a systemd timer on the droplet starts the `deploy` service, which first applies any changes to `main` with `ansible-pull`.
It then pulls the image, and deploys it by digest if the digest differs from the one Dokku last deployed.
It then enables TLS for the app, if it isn't already enabled.
So a change merged to `main` goes live within a couple of minutes of CI publishing its image, and a change to the image or tag is applied and deployed in the same run.
To deploy straight away, run `systemctl start deploy` on the droplet.
Its output is in `journalctl -u deploy`.

### Alerts

When the deploy service starts failing, the droplet posts the end of the failed run's log to a Slack channel, and when it next succeeds, it posts that it has recovered.
Runs that fail while it's already failing don't post again.
The droplet posts through an [incoming webhook](https://api.slack.com/messaging/webhooks), which belongs to a Slack app created at https://api.slack.com/apps.
The webhook's URL is a secret, set as `alert_webhook_url` in the app's vault.
To send a test alert, run `systemctl start notify-failure@deploy.service` on the droplet. The next successful run then posts that it has recovered.

## Runbook

### SSH into a droplet

```sh
ssh root@$(just tofu output -json ips | jq -r '.["infra-demo"]')
```

### After a droplet is replaced

The droplet's data is on its volume, which is moved to the new droplet, but everything else needs setting up again.
The new droplet has a new IP address and new SSH host keys, so first remove the old keys, using the old IP address:

```sh
ssh-keygen -R infra-demo.opensafely.org
ssh-keygen -R <old IP address>
```

The new droplet configures itself at first boot, which takes a few minutes, and within a minute after that, deploys the app and enables TLS.
`cloud-init status --wait` on the droplet waits for the first boot to finish.
The DNS records can take up to 30 minutes to point at the new IP address everywhere.

### Roll back to an earlier build

Set `image_tag` in `infra/ansible/host_vars/<app>/main.yml` to `sha-<commit>`, where `<commit>` is the full SHA of a commit on `main`, and merge the change.
Within a minute or so, the droplet applies and deploys it.
Set it back to `latest`, and merge that, to return to deploying each new build.

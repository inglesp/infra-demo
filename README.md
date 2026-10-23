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

## Tests and checks

```sh
just test   # run the tests
just check  # check formatting and lint, and run the tests
just fix    # fix formatting and lint where possible
```

Run `just check` before pushing.

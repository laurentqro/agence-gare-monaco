# Agence Gare Monaco

Website for Agence Gare Monaco, a Monaco-based real estate agency (agencegaremonaco.com).

## Stack

* Ruby on Rails 8.1.2
* SQLite
* Tailwind CSS
* Stimulus (Hotwire)
* Solid Queue (background jobs)
* Minitest

## Languages

The site is available in 9 locales: French (default), English, Italian, German, Swedish, Norwegian, Danish, Finnish, and Russian. French is served at `/`; other locales use a prefix (`/en`, `/de`, etc.). Route segments are translated per locale.

## Setup

```bash
bin/setup
```

This installs dependencies, prepares the database, and starts the dev server.

To run the server manually:

```bash
bin/dev
```

## Tests

```bash
bin/rails test
```

TDD is required for all changes — see `CLAUDE.md`.

## Key Services

* **Immotoolbox sync** — pulls districts, buildings, and properties from the Immotoolbox API. Run with `bin/rails immotoolbox:sync`. Scheduled via Solid Queue.
* **YouTube feed** — fetches latest videos from the agency channel every 6 hours.
* **Exchange rates** — daily refresh from the Frankfurter API for multi-currency display.
* **PDF brochures** — per-property PDFs generated with Typst, pre-cached and regenerated on update.

## Admin

Admin interface lives at `/admin`. Authentication uses Rails 8 built-in patterns (cookie sessions, `has_secure_password`). The admin UI is always rendered in French regardless of public locale.

## Deployment

Kamal-based deployment. Staging is gated by the `SITE_HOST` env var: when set to a non-production host, the site emits noindex/nofollow, blocks crawlers via `robots.txt`, and skips analytics.

## Documentation

* Product requirements: `PRD.md`
* Progress tracking: `progress.txt`

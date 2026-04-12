# Mosafer

Smart travel companion backend powering both a **mobile app** (scan/track tickets) and a **web app** (search/buy tickets).

## Stack

- **Framework:** FastAPI (async)
- **Database:** PostgreSQL 15 + SQLAlchemy (async) + Alembic migrations
- **Auth:** JWT (access + refresh tokens), RBAC with roles & permissions
- **Infrastructure:** Docker, Docker Compose (dev/staging/prod), GitHub Actions CI/CD

## Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [uv](https://docs.astral.sh/uv/) (Python package manager)

### Run with Docker (recommended)

```bash
# Start the dev environment (API + PostgreSQL + optional pgAdmin)
docker compose up -d

# Include pgAdmin for database management
docker compose --profile tools up -d
```

The API will be available at `http://localhost:8001`.

### Run locally

```bash
# Install dependencies
uv sync --dev

# Run database migrations
uv run alembic upgrade head

# Start the dev server
uv run uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
```

## API Documentation

When running in development mode, interactive API docs are available at:

- **Swagger UI:** `http://localhost:8001/docs`
- **ReDoc:** `http://localhost:8001/redoc`

## Project Structure

```
app/
├── api/v1/          # API route handlers
├── core/            # Config, security, JWT, RBAC, QR/PDF generation
├── db/              # Database engine & session
├── models/          # SQLAlchemy ORM models
├── schemas/         # Pydantic request/response schemas
├── services/        # Business logic & external API clients
└── utils/           # Shared helpers
alembic/             # Database migrations
docker/              # Dockerfiles (dev, staging, prod)
tests/               # Test suite
```

## Environment Variables

Copy `.env` and adjust values for your environment. Key variables:

| Variable | Description |
|---|---|
| `SECRET_KEY` | JWT signing secret (change in production) |
| `DATABASE_URL` | PostgreSQL connection string |
| `ENVIRONMENT` | `dev` / `staging` / `prod` |
| `CORS_ORIGINS` | Comma-separated allowed origins (default `*`) |

## Testing

```bash
uv run pytest -v --cov=app
```

## License

All rights reserved.

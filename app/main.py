"""FastAPI application entry point."""

from contextlib import asynccontextmanager
from time import perf_counter

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import PlainTextResponse
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.api.v1 import (
    airports_router,
    auth_router,
    destinations_router,
    devices_router,
    flights_router,
    health_router,
    notifications_router,
    orders_router,
    payments_router,
    reservations_router,
    tickets_router,
    trips_router,
    users_router,
)
from app.api.v2 import health_v2_router
from app.core.cache import close_redis, init_redis
from app.core.config import settings
from app.core.logging import RequestIDMiddleware, setup_logging
from app.core.rate_limit import limiter
from app.db.database import close_db

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status_code"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "path"],
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    setup_logging(
        json_format=not settings.is_development,
        log_level="DEBUG" if settings.DEBUG else "INFO",
    )
    await init_redis()
    yield
    await close_redis()
    await close_db()


app = FastAPI(
    title="Mosafer API",
    description="Smart travel companion backend for mobile and web apps",
    version="0.1.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.is_development else None,
    redoc_url="/redoc" if settings.is_development else None,
    swagger_ui_parameters={"persistAuthorization": True},
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(RequestIDMiddleware)
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=settings.trusted_hosts_list,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def request_size_limit_middleware(request: Request, call_next):
    content_length = request.headers.get("content-length")
    if content_length and content_length.isdigit():
        if int(content_length) > settings.MAX_REQUEST_SIZE_BYTES:
            return PlainTextResponse("Request entity too large", status_code=413)
    return await call_next(request)


@app.middleware("http")
async def security_headers_middleware(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    return response


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = perf_counter()
    response = await call_next(request)
    elapsed = perf_counter() - start
    path = request.url.path
    method = request.method
    REQUEST_COUNT.labels(method=method, path=path, status_code=str(response.status_code)).inc()
    REQUEST_LATENCY.labels(method=method, path=path).observe(elapsed)
    return response


app.include_router(health_router, prefix="/api/v1", tags=["health"])
app.include_router(users_router, prefix="/api/v1", tags=["users"])
app.include_router(airports_router, prefix="/api/v1", tags=["airports"])
app.include_router(flights_router, prefix="/api/v1", tags=["flights"])
app.include_router(reservations_router, prefix="/api/v1", tags=["reservations"])
app.include_router(tickets_router, prefix="/api/v1", tags=["tickets"])
app.include_router(auth_router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(notifications_router, prefix="/api/v1", tags=["notifications"])
app.include_router(orders_router, prefix="/api/v1", tags=["orders"])
app.include_router(trips_router, prefix="/api/v1", tags=["trips"])
app.include_router(destinations_router, prefix="/api/v1", tags=["destinations"])
app.include_router(payments_router, prefix="/api/v1", tags=["payments"])
app.include_router(devices_router, prefix="/api/v1", tags=["devices"])
app.include_router(health_v2_router, prefix="/api/v2", tags=["health-v2"])


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "Mosafer API",
        "version": "0.1.0",
        "environment": settings.ENVIRONMENT,
    }


@app.get("/metrics")
async def metrics() -> PlainTextResponse:
    """Prometheus metrics endpoint."""
    return PlainTextResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)

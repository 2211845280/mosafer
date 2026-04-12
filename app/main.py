"""FastAPI application entry point."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.api.v1 import (
    airports_router,
    auth_router,
<<<<<<< HEAD
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
from app.core.cache import close_redis, init_redis
from app.core.config import settings
from app.core.logging import RequestIDMiddleware, setup_logging
from app.core.rate_limit import limiter
=======
    flights_router,
    health_router,
    reservations_router,
    tickets_router,
    users_router,
)
from app.core.config import settings
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
from app.db.database import close_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
<<<<<<< HEAD
    setup_logging(
        json_format=not settings.is_development,
        log_level="DEBUG" if settings.DEBUG else "INFO",
    )
    await init_redis()
=======
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
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
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router, prefix="/api/v1", tags=["health"])
app.include_router(users_router, prefix="/api/v1", tags=["users"])
app.include_router(airports_router, prefix="/api/v1", tags=["airports"])
app.include_router(flights_router, prefix="/api/v1", tags=["flights"])
app.include_router(reservations_router, prefix="/api/v1", tags=["reservations"])
app.include_router(tickets_router, prefix="/api/v1", tags=["tickets"])
<<<<<<< HEAD
app.include_router(auth_router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(notifications_router, prefix="/api/v1", tags=["notifications"])
app.include_router(orders_router, prefix="/api/v1", tags=["orders"])
app.include_router(trips_router, prefix="/api/v1", tags=["trips"])
app.include_router(destinations_router, prefix="/api/v1", tags=["destinations"])
app.include_router(payments_router, prefix="/api/v1", tags=["payments"])
app.include_router(devices_router, prefix="/api/v1", tags=["devices"])
=======
app.include_router(auth_router, prefix="/auth", tags=["auth"])
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "Mosafer API",
        "version": "0.1.0",
        "environment": settings.ENVIRONMENT,
    }

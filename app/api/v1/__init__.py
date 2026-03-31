"""API v1 routers package."""

from app.api.v1.airports import router as airports_router
from app.api.v1.auth import router as auth_router
from app.api.v1.endpoints import router as users_router
from app.api.v1.flights import router as flights_router
from app.api.v1.health import router as health_router
from app.api.v1.reservations import router as reservations_router
from app.api.v1.tickets import router as tickets_router

__all__ = [
    "health_router",
    "users_router",
    "auth_router",
    "airports_router",
    "flights_router",
    "reservations_router",
    "tickets_router",
]

"""API v1 routers package."""

from app.api.v1.airports import router as airports_router
from app.api.v1.auth import router as auth_router
<<<<<<< HEAD
from app.api.v1.destinations import router as destinations_router
from app.api.v1.devices import router as devices_router
from app.api.v1.flights import router as flights_router
from app.api.v1.health import router as health_router
from app.api.v1.notifications import router as notifications_router
from app.api.v1.orders import router as orders_router
from app.api.v1.payments import router as payments_router
from app.api.v1.reservations import router as reservations_router
from app.api.v1.tickets import router as tickets_router
from app.api.v1.trips import router as trips_router
from app.api.v1.users import router as users_router
=======
from app.api.v1.endpoints import router as users_router
from app.api.v1.flights import router as flights_router
from app.api.v1.health import router as health_router
from app.api.v1.reservations import router as reservations_router
from app.api.v1.tickets import router as tickets_router
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767

__all__ = [
    "health_router",
    "users_router",
    "auth_router",
    "airports_router",
    "flights_router",
    "reservations_router",
    "tickets_router",
<<<<<<< HEAD
    "notifications_router",
    "orders_router",
    "trips_router",
    "destinations_router",
    "payments_router",
    "devices_router",
=======
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
]

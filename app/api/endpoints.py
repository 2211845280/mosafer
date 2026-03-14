from fastapi import APIRouter

import app.api.v1.auth as auth
import app.api.v1.health as health

main_router = APIRouter()

main_router.include_router(health.router, prefix="/check", tags=["Health"])
main_router.include_router(auth.router, prefix="/auth", tags=["Auth"])

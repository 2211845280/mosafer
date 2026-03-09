from fastapi import FastAPI

from app.api import api_router

app = FastAPI(title="Traveler Backend")

app.include_router(api_router)

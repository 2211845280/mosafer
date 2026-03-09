from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Traveler Backend"
    database_url: str = "postgresql+psycopg://traveler:traveler@localhost:5432/traveler_db"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()

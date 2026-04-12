"""Application configuration management."""

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application
    API_HOST: str = Field(default="0.0.0.0", description="API host address")
    API_PORT: int = Field(default=8001, description="API port number")
    ENVIRONMENT: str = Field(default="dev", description="Environment name (dev/staging/prod)")
    SECRET_KEY: str = Field(..., description="Secret key for security operations")
    DEBUG: bool = Field(default=False, description="Debug mode")
    JWT_ALGORITHM: str = Field(default="HS256", description="JWT signing algorithm")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(
        default=30,
        description="Access token expiry in minutes",
    )
    REFRESH_TOKEN_EXPIRE_DAYS: int = Field(
        default=7,
        description="Refresh token expiry in days",
    )
    PROFILE_PICTURES_DIR: str = Field(
        default="uploads/profile_pictures",
        description="Directory for user profile picture uploads",
    )
    PROFILE_PICTURE_MAX_SIZE_BYTES: int = Field(
        default=2 * 1024 * 1024,
        description="Maximum allowed profile picture upload size",
    )
    ADMIN_EMAIL: str | None = Field(
        default=None,
        description="Optional admin seed email used by migration/deployment setup",
    )
    ADMIN_PASSWORD: str | None = Field(
        default=None,
        description="Optional admin seed password used by migration/deployment setup",
    )
    TICKET_QR_DIR: str = Field(
        default="uploads/ticket_qr",
        description="Directory for generated ticket QR PNG files",
    )
    TICKET_UPLOADS_DIR: str = Field(
        default="uploads/ticket_attachments",
        description="Directory for user-uploaded ticket-related files",
    )
    TICKET_UPLOAD_MAX_SIZE_BYTES: int = Field(
        default=5 * 1024 * 1024,
        description="Maximum ticket attachment upload size",
    )
    CORS_ORIGINS: str = Field(
        default="http://localhost:3000,http://localhost:5173",
        description="Comma-separated list of allowed CORS origins (use * for all)",
    )
    REDIS_URL: str = Field(
        default="redis://localhost:6379/0",
        description="Redis connection URL",
    )
    MAX_REQUEST_SIZE_BYTES: int = Field(
        default=5 * 1024 * 1024,
        description="Global maximum request size in bytes",
    )
    TRUSTED_HOSTS: str = Field(
        default="*",
        description="Comma-separated trusted hosts for Host header validation",
    )

    # OpenAI
    OPENAI_API_KEY: str | None = Field(
        default=None,
        description="OpenAI API key for AI travel agent features",
    )

    # Payment
    PAYMENT_PROVIDER: str = Field(
        default="mock",
        description="Payment provider (mock, stripe, paymob)",
    )
    PAYMENT_WEBHOOK_SECRET: str | None = Field(
        default=None,
        description="Webhook signature secret for payment provider",
    )

    # Firebase (FCM)
    FIREBASE_CREDENTIALS_PATH: str | None = Field(
        default=None,
        description="Path to Firebase service account JSON for FCM",
    )

    # Email (Resend)
    RESEND_API_KEY: str | None = Field(
        default=None,
        description="Resend API key for transactional emails",
    )
    RESEND_FROM_EMAIL: str = Field(
        default="noreply@mosafer.dev",
        description="Default sender email address",
    )

    # Database
    DATABASE_URL: str = Field(
        ...,
        description="PostgreSQL database connection URL",
    )
    POSTGRES_USER: str = Field(default="postgres", description="PostgreSQL user")
    POSTGRES_PASSWORD: str = Field(..., description="PostgreSQL password")
    POSTGRES_DB: str = Field(default="mosafer", description="PostgreSQL database name")
    POSTGRES_HOST: str = Field(default="db", description="PostgreSQL host")
    POSTGRES_PORT: int = Field(default=5432, description="PostgreSQL port")

    # Database Pool Settings
    DB_POOL_SIZE: int = Field(default=5, description="Database connection pool size")
    DB_MAX_OVERFLOW: int = Field(default=10, description="Database connection pool max overflow")

    @property
    def cors_origins_list(self) -> list[str]:
        """Parse CORS_ORIGINS into a list."""
        if self.CORS_ORIGINS.strip() == "*":
            return ["*"]
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]

    @property
    def database_url_async(self) -> str:
        """Get async database URL for SQLAlchemy."""
        if self.DATABASE_URL.startswith("postgresql://"):
            return self.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)
        return self.DATABASE_URL

    @property
    def trusted_hosts_list(self) -> list[str]:
        """Parse TRUSTED_HOSTS into list."""
        if self.TRUSTED_HOSTS.strip() == "*":
            return ["*"]
        return [h.strip() for h in self.TRUSTED_HOSTS.split(",") if h.strip()]

    @property
    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.ENVIRONMENT == "prod"

    @property
    def is_development(self) -> bool:
        """Check if running in development environment."""
        return self.ENVIRONMENT == "dev"


# Global settings instance
settings = Settings()

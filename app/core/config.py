"""Application configuration management."""

from typing import Self

from pydantic import Field, model_validator
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
    PASSPORT_IMAGES_DIR: str = Field(
        default="uploads/passport_images",
        description="Directory for passport image uploads",
    )
    PASSPORT_IMAGE_MAX_SIZE_BYTES: int = Field(
        default=5 * 1024 * 1024,
        description="Maximum allowed passport image upload size",
    )
    PASSPORT_IMAGE_ANALYSIS_MODEL: str = Field(
        default="gpt-4o-mini",
        description="OpenAI model used to analyze uploaded passport images",
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
    TICKET_IMAGE_ANALYSIS_MAX_SIZE_BYTES: int = Field(
        default=5 * 1024 * 1024,
        description="Maximum image size for AI ticket analysis uploads",
    )
    TICKET_EXPIRY_GRACE_MINUTES: int = Field(
        default=30,
        description="Extra minutes after departure before a ticket is considered expired",
    )
    TICKET_IMAGE_ANALYSIS_MODEL: str = Field(
        default="gpt-4o-mini",
        description="OpenAI model used to analyze uploaded ticket images",
    )
    CORS_ORIGINS: str = Field(
        default="http://localhost:3000,http://localhost:5173",
        description="Comma-separated list of allowed CORS origins (use * for all)",
    )
    CORS_ORIGIN_REGEX: str | None = Field(
        default=None,
        description="Optional regex for allowed CORS origins",
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

    # Weather (OpenWeatherMap)
    WEATHER_API_KEY: str | None = Field(
        default=None,
        description="OpenWeatherMap API key for destination weather forecasts",
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
    STRIPE_SECRET_KEY: str | None = Field(
        default=None,
        description="Stripe secret key (sk_test_... or sk_live_...)",
    )
    STRIPE_PUBLISHABLE_KEY: str | None = Field(
        default=None,
        description="Stripe publishable key for client-side Checkout",
    )
    STRIPE_WEBHOOK_SECRET: str | None = Field(
        default=None,
        description="Stripe webhook signing secret (whsec_...)",
    )

    # Firebase (FCM)
    FIREBASE_CREDENTIALS_PATH: str | None = Field(
        default=None,
        description="Path to Firebase service account JSON for FCM",
    )

    # Google Maps Platform
    GOOGLE_MAPS_API_KEY: str | None = Field(
        default=None,
        description="Client-side Google Maps key (Flutter). Used as server key fallback in dev.",
    )
    GOOGLE_MAPS_SERVER_API_KEY: str | None = Field(
        default=None,
        description="Server-side Google Maps Platform API key for Routes/Geocoding",
    )
    GOOGLE_ROUTES_ENABLED: bool = Field(
        default=False,
        description="Use Google Routes API for route/ETA calculations when a key is configured",
    )

    # Email (SMTP — Mailpit in dev, Gmail in prod)
    SMTP_HOST: str = Field(
        default="localhost",
        description="SMTP server hostname (mailpit in Docker dev, smtp.gmail.com in prod)",
    )
    SMTP_PORT: int = Field(default=1025, description="SMTP server port")
    SMTP_USER: str | None = Field(default=None, description="SMTP username (required in prod)")
    SMTP_PASSWORD: str | None = Field(
        default=None,
        description="SMTP password or Gmail app password (required in prod)",
    )
    SMTP_FROM: str = Field(
        default="noreply@mosafer.local",
        description="Default sender email address",
    )
    SMTP_USE_TLS: bool = Field(
        default=False,
        description="Use implicit TLS (SMTPS, typically port 465)",
    )
    SMTP_START_TLS: bool = Field(
        default=False,
        description="Upgrade connection with STARTTLS (typically port 587)",
    )
    PASSWORD_RESET_EXPIRE_MINUTES: int = Field(
        default=60,
        description="Password reset token validity in minutes",
    )
    API_PUBLIC_URL: str = Field(
        default="http://localhost:8001",
        description="Public API base URL (no trailing slash) for links in emails",
    )
    WEB_APP_URL: str = Field(
        default="http://localhost:3000",
        description="Public web app URL (no trailing slash) for redirects after verify",
    )

    @model_validator(mode="after")
    def _apply_defaults(self) -> Self:
        if not self.GOOGLE_MAPS_SERVER_API_KEY and self.GOOGLE_MAPS_API_KEY:
            self.GOOGLE_MAPS_SERVER_API_KEY = self.GOOGLE_MAPS_API_KEY
        return self

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
    def cors_origin_regex(self) -> str | None:
        """Allow Flutter Web and other local dev servers that use random ports."""
        if self.CORS_ORIGIN_REGEX:
            return self.CORS_ORIGIN_REGEX.strip() or None
        if self.is_development:
            return r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"
        return None

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

    @property
    def payment_provider_is_stripe(self) -> bool:
        return self.PAYMENT_PROVIDER.strip().lower() == "stripe" and bool(self.STRIPE_SECRET_KEY)

    @property
    def stripe_test_mode(self) -> bool:
        key = self.STRIPE_SECRET_KEY or ""
        return key.startswith("sk_test_")

    def validate_for_launch(self) -> None:
        """Fail fast when production is misconfigured."""
        if not self.is_production:
            return
        missing: list[str] = []
        if not self.SMTP_HOST:
            missing.append("SMTP_HOST")
        if not self.SMTP_USER:
            missing.append("SMTP_USER")
        if not self.SMTP_PASSWORD:
            missing.append("SMTP_PASSWORD")
        if "@" not in self.SMTP_FROM:
            missing.append("SMTP_FROM")
        if not self.SECRET_KEY or self.SECRET_KEY.startswith("dev-"):
            missing.append("SECRET_KEY (must be a strong non-dev value)")
        if self.GOOGLE_ROUTES_ENABLED and not self.GOOGLE_MAPS_SERVER_API_KEY:
            missing.append("GOOGLE_MAPS_SERVER_API_KEY (required when GOOGLE_ROUTES_ENABLED=true)")
        if missing:
            raise RuntimeError(
                "Production configuration incomplete: " + ", ".join(missing),
            )


# Global settings instance
settings = Settings()

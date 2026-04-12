"""Abstract base client for external HTTP APIs.

Provides retry with exponential backoff, structured logging, and timeout
management. Concrete clients (e.g. Skyscanner, AviationStack) inherit from
this class and only need to implement their domain-specific methods.
"""

from __future__ import annotations

import asyncio
from time import perf_counter
from types import TracebackType
from uuid import uuid4

import httpx
import structlog

logger = structlog.get_logger(__name__)


class ExternalServiceError(Exception):
    """Raised when an external API call fails after all retries."""

    def __init__(self, service: str, message: str, status_code: int | None = None) -> None:
        self.service = service
        self.status_code = status_code
        super().__init__(f"[{service}] {message}")


class BaseExternalClient:
    """Async HTTP client with retry, timeout, and structured logging.

    Usage::

        class SkyscannerClient(BaseExternalClient):
            def __init__(self, api_key: str):
                super().__init__(
                    base_url="https://partners.api.skyscanner.net/apiservices",
                    headers={"x-api-key": api_key},
                    service_name="skyscanner",
                )

            async def search_flights(self, origin, destination, date):
                return await self._request("GET", "/flights", params={...})
    """

    def __init__(
        self,
        *,
        base_url: str,
        headers: dict[str, str] | None = None,
        timeout: float = 30.0,
        max_retries: int = 3,
        backoff_base: float = 1.0,
        service_name: str = "external",
    ) -> None:
        self._service_name = service_name
        self._max_retries = max_retries
        self._backoff_base = backoff_base
        self._client = httpx.AsyncClient(
            base_url=base_url,
            headers=headers or {},
            timeout=httpx.Timeout(timeout),
        )

    async def __aenter__(self) -> BaseExternalClient:
        return self

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_val: BaseException | None,
        exc_tb: TracebackType | None,
    ) -> None:
        await self.close()

    async def close(self) -> None:
        await self._client.aclose()

    async def _request(
        self,
        method: str,
        path: str,
        *,
        params: dict | None = None,
        json: dict | None = None,
        headers: dict[str, str] | None = None,
    ) -> httpx.Response:
        """Execute an HTTP request with automatic retry and logging."""
        last_exc: Exception | None = None

        for attempt in range(1, self._max_retries + 1):
            trace_id = uuid4().hex
            started_at = perf_counter()
            log = logger.bind(
                service=self._service_name,
                method=method,
                path=path,
                attempt=attempt,
                trace_id=trace_id,
            )
            try:
                log.debug("external_request.start")
                response = await self._client.request(
                    method,
                    path,
                    params=params,
                    json=json,
                    headers=headers,
                )
                log.info(
                    "external_request.response",
                    status_code=response.status_code,
                    elapsed_ms=round((perf_counter() - started_at) * 1000, 2),
                )
                response.raise_for_status()
                return response

            except httpx.HTTPStatusError as exc:
                status = exc.response.status_code
                # Don't retry client errors (4xx) except 429 (rate-limited)
                if 400 <= status < 500 and status != 429:
                    log.warning("external_request.client_error", status_code=status)
                    raise ExternalServiceError(
                        self._service_name,
                        f"HTTP {status}: {exc.response.text[:200]}",
                        status_code=status,
                    ) from exc
                last_exc = exc

            except (httpx.ConnectError, httpx.ReadTimeout, httpx.WriteTimeout) as exc:
                last_exc = exc

            except Exception as exc:
                log.error("external_request.unexpected_error", error=str(exc))
                last_exc = exc

            if attempt < self._max_retries:
                delay = self._backoff_base * (2 ** (attempt - 1))
                log.warning("external_request.retrying", delay_seconds=delay)
                await asyncio.sleep(delay)

        raise ExternalServiceError(
            self._service_name,
            f"All {self._max_retries} attempts failed: {last_exc}",
        ) from last_exc

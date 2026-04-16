"""OpenAI LLM client with structured JSON output support."""

from __future__ import annotations

import json

import structlog
from openai import AsyncOpenAI

from app.core.config import settings

logger = structlog.get_logger(__name__)


class LLMClient:
    """Thin async wrapper around the OpenAI chat completions API."""

    def __init__(self, api_key: str) -> None:
        self._client = AsyncOpenAI(api_key=api_key)

    async def chat(
        self,
        system_prompt: str,
        user_message: str,
        *,
        model: str = "gpt-4o-mini",
        temperature: float = 0.7,
        max_tokens: int = 2048,
    ) -> str:
        """Send a chat completion request and return the text response."""
        logger.info("llm.chat.start", model=model)
        response = await self._client.chat.completions.create(
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message},
            ],
        )
        text = response.choices[0].message.content or ""
        logger.info(
            "llm.chat.done",
            model=model,
            tokens=response.usage.total_tokens if response.usage else 0,
        )
        return text

    async def chat_json(
        self,
        system_prompt: str,
        user_message: str,
        *,
        model: str = "gpt-4o-mini",
        temperature: float = 0.7,
        max_tokens: int = 2048,
    ) -> dict:
        """Send a chat request expecting a JSON response."""
        logger.info("llm.chat_json.start", model=model)
        response = await self._client.chat.completions.create(
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message},
            ],
        )
        raw = response.choices[0].message.content or "{}"
        logger.info(
            "llm.chat_json.done",
            model=model,
            tokens=response.usage.total_tokens if response.usage else 0,
        )
        return json.loads(raw)


_client: LLMClient | None = None


def get_llm_client() -> LLMClient:
    """Return a module-level LLMClient singleton."""
    global _client
    if _client is not None:
        return _client
    if not settings.OPENAI_API_KEY:
        raise RuntimeError("OPENAI_API_KEY is not configured")
    _client = LLMClient(api_key=settings.OPENAI_API_KEY)
    return _client

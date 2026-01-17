"""HTTP client for Pairing Planet backend API."""

import asyncio
from pathlib import Path
from typing import Any, Dict, List, Optional

import httpx
import structlog
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from ..config import get_settings
from ..personas import BotPersona
from .models import (
    AuthResponse,
    CreateLogRequest,
    CreateRecipeRequest,
    ImageUploadResponse,
    LogPost,
    Recipe,
)

logger = structlog.get_logger()


class PairingPlanetClient:
    """Async HTTP client for Pairing Planet backend API."""

    def __init__(
        self,
        base_url: Optional[str] = None,
        timeout: float = 30.0,
    ) -> None:
        settings = get_settings()
        self.base_url = base_url or settings.backend_base_url
        self.timeout = timeout
        self._client: Optional[httpx.AsyncClient] = None
        self._access_token: Optional[str] = None
        self._refresh_token: Optional[str] = None
        self._user_public_id: Optional[str] = None

    async def __aenter__(self) -> "PairingPlanetClient":
        """Enter async context."""
        await self._ensure_client()
        return self

    async def __aexit__(self, *args: Any) -> None:
        """Exit async context."""
        await self.close()

    async def _ensure_client(self) -> httpx.AsyncClient:
        """Ensure HTTP client is initialized."""
        if self._client is None:
            self._client = httpx.AsyncClient(
                base_url=self.base_url,
                timeout=self.timeout,
            )
        return self._client

    async def close(self) -> None:
        """Close the HTTP client."""
        if self._client:
            await self._client.aclose()
            self._client = None

    def _get_auth_headers(self) -> Dict[str, str]:
        """Get authentication headers."""
        if not self._access_token:
            raise RuntimeError("Not authenticated. Call login() first.")
        return {"Authorization": f"Bearer {self._access_token}"}

    @retry(
        retry=retry_if_exception_type((httpx.TimeoutException, httpx.NetworkError)),
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
    )
    async def _request(
        self,
        method: str,
        path: str,
        *,
        json: Optional[Dict[str, Any]] = None,
        data: Optional[Dict[str, Any]] = None,
        files: Optional[Dict[str, Any]] = None,
        auth: bool = True,
        **kwargs: Any,
    ) -> httpx.Response:
        """Make an HTTP request with retry logic."""
        client = await self._ensure_client()
        headers = kwargs.pop("headers", {})

        if auth:
            headers.update(self._get_auth_headers())

        # Set Content-Type for JSON requests (not for file uploads)
        if json is not None and not files:
            headers.setdefault("Content-Type", "application/json")

        response = await client.request(
            method,
            path,
            json=json,
            data=data,
            files=files,
            headers=headers,
            **kwargs,
        )

        # Log request
        logger.debug(
            "api_request",
            method=method,
            path=path,
            status=response.status_code,
        )

        # Handle token refresh on 401
        if response.status_code == 401 and auth and self._refresh_token:
            logger.info("access_token_expired", refreshing=True)
            await self._refresh_access_token()
            headers.update(self._get_auth_headers())
            response = await client.request(
                method,
                path,
                json=json,
                data=data,
                files=files,
                headers=headers,
                **kwargs,
            )

        if response.status_code >= 400:
            print(f"API Error {response.status_code}: {response.text[:1000]}")
        response.raise_for_status()
        return response

    async def _refresh_access_token(self) -> None:
        """Refresh the access token using refresh token."""
        if not self._refresh_token:
            raise RuntimeError("No refresh token available")

        response = await self._request(
            "POST",
            "/auth/reissue",
            json={"refreshToken": self._refresh_token},
            auth=False,
        )
        data = response.json()
        self._access_token = data["accessToken"]
        self._refresh_token = data["refreshToken"]

    # ==================== Authentication ====================

    async def login_bot(self, api_key: str) -> AuthResponse:
        """Authenticate using bot API key."""
        response = await self._request(
            "POST",
            "/auth/bot-login",
            json={"apiKey": api_key},
            auth=False,
        )
        data = response.json()
        auth = AuthResponse(**data)

        self._access_token = auth.access_token
        self._refresh_token = auth.refresh_token
        self._user_public_id = auth.user_public_id

        logger.info(
            "bot_authenticated",
            user_id=auth.user_public_id,
            username=auth.username,
            persona=auth.persona_name,
        )
        return auth

    async def login_persona(self, persona: BotPersona) -> AuthResponse:
        """Authenticate using a persona's API key."""
        if not persona.api_key:
            raise ValueError(f"Persona {persona.name} has no API key configured")

        auth = await self.login_bot(persona.api_key)

        # Update persona with auth info
        persona.user_public_id = auth.user_public_id
        persona.persona_public_id = auth.persona_public_id
        persona.access_token = auth.access_token
        persona.refresh_token = auth.refresh_token

        return auth

    # ==================== Images ====================

    async def upload_image(self, image_path: Path) -> ImageUploadResponse:
        """Upload an image file."""
        if not image_path.exists():
            raise FileNotFoundError(f"Image not found: {image_path}")

        with open(image_path, "rb") as f:
            files = {"file": (image_path.name, f, "image/jpeg")}
            response = await self._request(
                "POST",
                "/images/upload",
                files=files,
            )

        data = response.json()
        logger.info("image_uploaded", public_id=data.get("publicId"))
        return ImageUploadResponse(
            public_id=data["publicId"],
            url=data["url"],
            thumbnail_url=data.get("thumbnailUrl"),
        )

    async def upload_image_bytes(
        self,
        image_bytes: bytes,
        filename: str = "image.jpg",
        image_type: str = "COVER",
    ) -> ImageUploadResponse:
        """Upload image from bytes."""
        files = {"file": (filename, image_bytes, "image/jpeg")}
        form_data = {"type": image_type}
        response = await self._request(
            "POST",
            "/images/upload",
            files=files,
            data=form_data,
        )
        result = response.json()
        logger.info("image_uploaded", public_id=result.get("imagePublicId"))
        return ImageUploadResponse(
            public_id=result["imagePublicId"],
            url=result["imageUrl"],
            thumbnail_url=result.get("thumbnailUrl"),
        )

    # ==================== Recipes ====================

    async def create_recipe(self, request: CreateRecipeRequest) -> Recipe:
        """Create a new recipe."""
        payload = request.model_dump(exclude_none=True, by_alias=True)

        # Debug: print payload
        import json
        print(f"imagePublicIds in payload: {payload.get('imagePublicIds', 'NOT FOUND')}")
        print(f"Full payload keys: {list(payload.keys())}")

        response = await self._request("POST", "/recipes", json=payload)
        data = response.json()
        print(f"Response imageUrls: {data.get('imageUrls', 'NOT FOUND')}")
        print(f"Response images: {data.get('images', 'NOT FOUND')}")
        logger.info(
            "recipe_created",
            public_id=data.get("publicId"),
            title=data.get("title"),
        )
        return Recipe(**data)

    async def get_recipe(self, public_id: str) -> Recipe:
        """Get a recipe by public ID."""
        response = await self._request("GET", f"/recipes/{public_id}", auth=False)
        data = response.json()
        return Recipe(**self._from_camel_case(data))

    async def get_recipes(
        self,
        page: int = 0,
        size: int = 20,
    ) -> List[Recipe]:
        """Get paginated list of recipes."""
        response = await self._request(
            "GET",
            "/recipes",
            params={"page": page, "size": size},
            auth=False,
        )
        data = response.json()
        content = data.get("content", [])
        return [Recipe(**self._from_camel_case(r)) for r in content]

    # ==================== Log Posts ====================

    async def create_log(self, request: CreateLogRequest) -> LogPost:
        """Create a new cooking log."""
        payload = request.model_dump(exclude_none=True, by_alias=True)
        payload = self._to_camel_case(payload)

        response = await self._request("POST", "/log_posts", json=payload)
        data = response.json()
        logger.info(
            "log_created",
            public_id=data.get("publicId"),
            recipe=data.get("recipePublicId"),
            outcome=data.get("outcome"),
        )
        return LogPost(**self._from_camel_case(data))

    async def get_log(self, public_id: str) -> LogPost:
        """Get a log post by public ID."""
        response = await self._request("GET", f"/log_posts/{public_id}", auth=False)
        data = response.json()
        return LogPost(**self._from_camel_case(data))

    # ==================== Helpers ====================

    @staticmethod
    def _to_camel_case(data: Dict[str, Any]) -> Dict[str, Any]:
        """Convert dict keys from snake_case to camelCase."""

        def convert_key(key: str) -> str:
            components = key.split("_")
            return components[0] + "".join(x.title() for x in components[1:])

        def convert_value(value: Any) -> Any:
            if isinstance(value, dict):
                return {convert_key(k): convert_value(v) for k, v in value.items()}
            elif isinstance(value, list):
                return [convert_value(item) for item in value]
            return value

        return {convert_key(k): convert_value(v) for k, v in data.items()}

    @staticmethod
    def _from_camel_case(data: Dict[str, Any]) -> Dict[str, Any]:
        """Convert dict keys from camelCase to snake_case."""
        import re

        def convert_key(key: str) -> str:
            s1 = re.sub("(.)([A-Z][a-z]+)", r"\1_\2", key)
            return re.sub("([a-z0-9])([A-Z])", r"\1_\2", s1).lower()

        def convert_value(value: Any) -> Any:
            if isinstance(value, dict):
                return {convert_key(k): convert_value(v) for k, v in value.items()}
            elif isinstance(value, list):
                return [convert_value(item) for item in value]
            return value

        return {convert_key(k): convert_value(v) for k, v in data.items()}

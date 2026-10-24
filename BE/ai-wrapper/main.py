# MedReminder AI Wrapper (PRM only)
#
# FastAPI wrapper dung truoc Ollama de "cung cap kha nang truy van cho cac service khac"
# dung yeu cau PRM 2.3. ai-service goi vao day thay vi goi thang Ollama.
# Khong lien quan EXE: service nay chi chay trong docker-compose.ollama.yml.
#
# Luong: ai-service -> (POST /v1/chat/completions) -> ai-wrapper -> Ollama (model local)
import os
import time

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, Response

OLLAMA_BASE_URL = os.environ.get("OLLAMA_BASE_URL", "http://ollama:11434").rstrip("/")
REQUEST_TIMEOUT = float(os.environ.get("WRAPPER_TIMEOUT", "180"))

app = FastAPI(title="MedReminder AI Wrapper (PRM)", version="1.0.0")


@app.get("/health")
async def health():
    """Kiem tra Ollama va liet ke model da pull."""
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            resp = await client.get(f"{OLLAMA_BASE_URL}/api/tags")
        ok = resp.status_code == 200
        models = [m.get("name") for m in resp.json().get("models", [])] if ok else []
        return {
            "status": "ok" if ok else "degraded",
            "ollama": OLLAMA_BASE_URL,
            "models": models,
        }
    except httpx.HTTPError as exc:
        return JSONResponse(
            status_code=503,
            content={"status": "down", "ollama": OLLAMA_BASE_URL, "error": str(exc)},
        )


@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    """
    Proxy tuong thich OpenAI. Nhan payload chat (co the kem anh base64),
    forward sang Ollama, do latency va tra ve kem header X-Inference-Ms.
    """
    payload = await request.body()
    started = time.perf_counter()
    try:
        async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT) as client:
            upstream = await client.post(
                f"{OLLAMA_BASE_URL}/v1/chat/completions",
                content=payload,
                headers={"Content-Type": "application/json"},
            )
    except httpx.HTTPError as exc:
        return JSONResponse(
            status_code=502,
            content={"error": {"message": f"Ollama request failed: {exc}"}},
        )
    elapsed_ms = round((time.perf_counter() - started) * 1000, 1)
    return Response(
        content=upstream.content,
        status_code=upstream.status_code,
        media_type=upstream.headers.get("content-type", "application/json"),
        headers={"X-Inference-Ms": str(elapsed_ms)},
    )

# Benchmark latency cua model thi giac (qwen2.5vl) chay local qua FastAPI wrapper.
# Dung cho bao cao PRM 2.3: Latency (ms). RAM/CPU xem bang `docker stats`.
#
# Cach chay (sau khi da up compose ollama va pull model):
#   pip install httpx
#   python benchmark.py --image duong_dan_anh_don_thuoc.jpg --runs 5
#
# Do RAM/CPU song song o terminal khac:
#   docker stats meds-ollama meds-ai-wrapper --no-stream
import argparse
import base64
import mimetypes
import statistics
import time

import httpx

# Dung dung prompt nhu ai-service de so lieu sat thuc te.
PROMPT = """You read a photo of a Vietnamese paper prescription.
Reply with one JSON object and no other text.
Keep medicine names as printed. Do not invent medicines that are not on the photo."""


def build_payload(image_path: str, model: str) -> dict:
    mime = mimetypes.guess_type(image_path)[0] or "image/jpeg"
    with open(image_path, "rb") as handle:
        b64 = base64.b64encode(handle.read()).decode()
    data_uri = f"data:{mime};base64,{b64}"
    return {
        "model": model,
        "temperature": 0,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": PROMPT},
                    {"type": "image_url", "image_url": {"url": data_uri}},
                ],
            }
        ],
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Do latency model AI local qua FastAPI wrapper (PRM)."
    )
    parser.add_argument("--image", required=True, help="Duong dan anh don thuoc (jpg/png/webp)")
    parser.add_argument("--url", default="http://localhost:8000/v1/chat/completions")
    parser.add_argument("--model", default="qwen2.5vl:7b")
    parser.add_argument("--runs", type=int, default=5)
    parser.add_argument("--warmup", type=int, default=1)
    args = parser.parse_args()

    payload = build_payload(args.image, args.model)

    def one_call() -> float:
        start = time.perf_counter()
        resp = httpx.post(args.url, json=payload, timeout=300)
        elapsed = (time.perf_counter() - start) * 1000
        resp.raise_for_status()
        return elapsed

    if args.warmup:
        print(f"Warmup x{args.warmup} (nap model vao RAM, khong tinh diem)...")
        for _ in range(args.warmup):
            one_call()

    print(f"Benchmark x{args.runs} tren model '{args.model}'...")
    times = []
    for i in range(args.runs):
        ms = one_call()
        times.append(ms)
        print(f"  run {i + 1}: {ms:.0f} ms")

    times.sort()
    p95 = times[min(len(times) - 1, int(round(0.95 * (len(times) - 1))))]
    print("\n=== Latency (ms) ===")
    print(f"  so lan : {len(times)}")
    print(f"  min    : {min(times):.0f}")
    print(f"  avg    : {statistics.mean(times):.0f}")
    print(f"  p95    : {p95:.0f}")
    print(f"  max    : {max(times):.0f}")
    print("\nDo RAM/CPU (chay o terminal khac, luc dang benchmark):")
    print("  docker stats meds-ollama meds-ai-wrapper --no-stream")


if __name__ == "__main__":
    main()

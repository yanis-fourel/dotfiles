#!/usr/bin/env python3
"""Read Codex subscription limits using Pi's existing OpenAI OAuth session.

Only display-safe usage data is written to stdout. OAuth tokens, account IDs,
and the account email are never included in the output.
"""

import base64
import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

AUTH_PATH = Path(os.environ.get("PI_AUTH_FILE", Path.home() / ".pi" / "agent" / "auth.json"))
USAGE_URL = "https://chatgpt.com/backend-api/wham/usage"


def output(**values):
    values.setdefault("updatedAt", datetime.now(timezone.utc).isoformat())
    print(json.dumps(values, separators=(",", ":")))


def jwt_claims(token):
    try:
        payload = token.split(".")[1]
        payload += "=" * (-len(payload) % 4)
        return json.loads(base64.urlsafe_b64decode(payload))
    except Exception:
        return {}


def plan_label(value):
    labels = {
        "free": "Free",
        "go": "Go",
        "plus": "Plus",
        "pro": "Pro",
        "prolite": "Pro Lite",
        "team": "Team",
        "business": "Business",
        "enterprise": "Enterprise",
        "edu": "Education",
    }
    text = str(value or "").strip()
    return labels.get(text.lower(), text.replace("_", " ").title() or "Subscription")


def window_label(seconds):
    seconds = int(seconds or 0)
    if seconds == 604800:
        return "Weekly window"
    if seconds and seconds % 3600 == 0:
        return f"{seconds // 3600}h window"
    if seconds and seconds % 60 == 0:
        return f"{seconds // 60}m window"
    return "Usage window"


def add_rate_limit(target, rate_limit, group="Codex"):
    if not isinstance(rate_limit, dict):
        return
    for key in ("primary_window", "secondary_window"):
        window = rate_limit.get(key)
        if not isinstance(window, dict) or window.get("used_percent") is None:
            continue
        seconds = int(window.get("limit_window_seconds") or 0)
        target.append({
            "group": group,
            "label": window_label(seconds),
            "usedPercent": max(0.0, min(100.0, float(window.get("used_percent") or 0))),
            "windowSeconds": seconds,
            "resetAt": int(window.get("reset_at") or 0),
        })


def main():
    try:
        auth = json.loads(AUTH_PATH.read_text(encoding="utf-8"))
        credential = auth.get("openai-codex") or {}
    except FileNotFoundError:
        output(ok=False, error="Pi authentication was not found", hint="Sign in to OpenAI Codex from Pi.")
        return
    except Exception:
        output(ok=False, error="Pi authentication could not be read", hint="Check ~/.pi/agent/auth.json.")
        return

    token = credential.get("access")
    account_id = credential.get("accountId")
    if not token or not account_id:
        output(ok=False, error="OpenAI Codex is not signed in", hint="Sign in to OpenAI Codex from Pi.")
        return

    claims = jwt_claims(token)
    expires_at = int(claims.get("exp") or 0)
    if expires_at and expires_at <= int(datetime.now(timezone.utc).timestamp()):
        output(ok=False, error="The Pi OpenAI session has expired", hint="Open Pi and sign in to OpenAI Codex again.")
        return

    request = urllib.request.Request(
        USAGE_URL,
        headers={
            "Authorization": "Bearer " + token,
            "ChatGPT-Account-Id": account_id,
            "Accept": "application/json",
            "User-Agent": "quickshell-codex-usage/1",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=12) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as error:
        if error.code in (401, 403):
            message = "OpenAI rejected the Pi session"
            hint = "Open Pi and sign in to OpenAI Codex again."
        elif error.code == 429:
            message = "OpenAI is rate-limiting usage checks"
            hint = "The bar will retry automatically."
        else:
            message = f"OpenAI usage request failed (HTTP {error.code})"
            hint = "The bar will retry automatically."
        output(ok=False, error=message, hint=hint)
        return
    except Exception as error:
        output(ok=False, error="Could not reach OpenAI", hint=str(error)[:160])
        return

    limits = []
    main_limit = payload.get("rate_limit") or {}
    add_rate_limit(limits, main_limit)

    code_review = payload.get("code_review_rate_limit")
    if code_review:
        add_rate_limit(limits, code_review, "Code review")

    for additional in payload.get("additional_rate_limits") or []:
        if not isinstance(additional, dict):
            continue
        name = str(additional.get("limit_name") or "Additional limit")
        add_rate_limit(limits, additional.get("rate_limit"), name)

    credits = payload.get("credits") or {}
    raw_plan = payload.get("plan_type") or (claims.get("https://api.openai.com/auth") or {}).get("chatgpt_plan_type")
    primary_spans = {entry["windowSeconds"] for entry in limits if entry["group"] == "Codex"}

    output(
        ok=True,
        plan=plan_label(raw_plan),
        allowed=bool(main_limit.get("allowed", not main_limit.get("limit_reached", False))),
        limitReached=bool(main_limit.get("limit_reached", False)),
        limits=limits,
        sessionWindowReported=18000 in primary_spans,
        weeklyWindowReported=604800 in primary_spans,
        credits={
            "available": bool(credits.get("has_credits", False)),
            "unlimited": bool(credits.get("unlimited", False)),
            "balance": str(credits.get("balance") or "0"),
            "overageLimitReached": bool(credits.get("overage_limit_reached", False)),
        },
        resetCredits=int((payload.get("rate_limit_reset_credits") or {}).get("available_count") or 0),
        tokenExpiresAt=expires_at,
    )


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # Keep the StatusCommand contract valid without leaking sensitive data
        # through a traceback or accidentally serialized request object.
        output(ok=False, error="Unexpected Codex usage error", hint="Run the collector manually for a fresh check.")
        sys.exit(1)

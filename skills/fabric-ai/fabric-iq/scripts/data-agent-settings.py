#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "azure-identity>=1.15",
#     "requests>=2.31",
# ]
# ///
"""Read or change a Fabric data agent's instructions and runtime, and publish its draft.

    uv run <dir>/data-agent-settings.py show WORKSPACE_ID AGENT_ID --save draft.txt
    uv run <dir>/data-agent-settings.py set WORKSPACE_ID AGENT_ID --instructions draft.txt
    uv run <dir>/data-agent-settings.py set WORKSPACE_ID AGENT_ID --runtime standard --dry-run
    uv run <dir>/data-agent-settings.py publish WORKSPACE_ID AGENT_ID --description FILE

`set` changes the draft alone, so `data-agent-eval.py run ... --stage sandbox` can test it before
anyone else gets it; `publish` makes the draft what the MCP endpoint and every consumer serve.
It signs in as the Azure CLI's account: set AZURE_CONFIG_DIR first where tenants are kept apart.

The data agent API underneath: GET staging/settings (the draft) and settings (the published
agent); PATCH staging/settings, which keeps whatever it is not sent; POST staging/publish, whose
publishedDescription becomes the description the MCP endpoint gives its tool, which
orchestrators read to decide when to call the agent. `publish` keeps the current description,
read from the item definition, unless --description replaces it.

The runtime is experimental.enableExperimentalFeatures: true is the preview runtime. Once it is
false the API leaves the key out, so a missing key reads as the standard runtime. A publish
fixes the runtime the published agent uses.

Instructions files are read as UTF-8, CRLF turned to LF and trailing newlines dropped, the form
the API hands back. Each change reads back what it wrote and exits 1 if the stage does not hold
it; 2 is a bad argument.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import sys
import time
from pathlib import Path
from typing import Any, NoReturn

FABRIC_API = "https://api.fabric.microsoft.com/v1"
FABRIC_SCOPE = "https://api.fabric.microsoft.com/.default"
DESCRIPTION_PART = "Files/Config/publish_info.json"


class ApiError(RuntimeError):
    """A REST call that failed: the request, its status, and the start of the reply."""


def fail_usage(message: str) -> NoReturn:
    """Print a usage error and exit 2."""
    print(f"data-agent-settings: {message}", file=sys.stderr)
    sys.exit(2)


class Api:
    """Fabric REST calls, signed in as the Azure CLI's account."""

    def __init__(self) -> None:
        from azure.identity import AzureCliCredential

        self.credential = AzureCliCredential(process_timeout=60)

    def call(self, method: str, url: str, body: dict | None = None) -> Any:
        """Send one request, wait out a long-running operation, and return the JSON reply.

        Raises:
            ApiError: On a transport failure, a 4xx or 5xx reply, or an operation that fails.
        """
        import requests

        headers = {"Authorization": f"Bearer {self.credential.get_token(FABRIC_SCOPE).token}"}
        try:
            reply = requests.request(method, url, headers=headers, json=body, timeout=300)
            if reply.status_code == 202 and reply.headers.get("Location"):
                reply = self._finish(reply, headers)
                if reply is None:
                    return {}
        except requests.RequestException as exc:
            raise ApiError(f"{method} {url}: {exc}") from exc
        if reply.status_code >= 400:
            raise ApiError(f"{method} {url}: {reply.status_code} {reply.text[:800]}")
        return reply.json() if reply.content else {}

    @staticmethod
    def _finish(reply: Any, headers: dict) -> Any:
        """Poll a 202's operation to its end; return its result, or None if it has none."""
        import requests

        location = reply.headers["Location"]
        deadline = time.monotonic() + 600
        status = "Running"
        while status in ("NotStarted", "Running"):
            if time.monotonic() > deadline:
                raise ApiError(f"operation still {status} after ten minutes: {location}")
            time.sleep(int(reply.headers.get("Retry-After") or 2))
            reply = requests.get(location, headers=headers, timeout=120)
            try:
                status = (reply.json() if reply.content else {}).get("status")
            except ValueError:
                status = None
        if status != "Succeeded":
            raise ApiError(f"operation {status}: {reply.text[:800]}")
        result = requests.get(location.rstrip("/") + "/result", headers=headers, timeout=120)
        return None if result.status_code >= 400 else result


def agent_url(args: argparse.Namespace, path: str) -> str:
    """The data agent API's URL for one path under the agent."""
    return f"{FABRIC_API}/workspaces/{args.workspace_id}/dataAgents/{args.agent_id}/{path}"


def read_text(path: Path) -> str:
    """Read a text file as the API holds text: UTF-8, LF, no trailing newline."""
    try:
        return path.read_bytes().decode("utf-8-sig").replace("\r\n", "\n").strip("\n")
    except (OSError, UnicodeDecodeError) as exc:
        fail_usage(f"cannot read {path}: {exc}")


def runtime(settings: dict) -> str:
    """The runtime one stage's settings select."""
    preview = (settings.get("experimental") or {}).get("enableExperimentalFeatures")
    return "preview" if preview else "standard"


def fingerprint(text: str) -> str:
    """Length, lines and a short hash, to compare instructions without printing them."""
    lines = text.count("\n") + 1 if text else 0
    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()[:12]
    return f"{len(text)} chars, {lines} lines, sha256 {digest}"


def describe(label: str, settings: dict) -> None:
    """Print one stage's runtime and instructions fingerprint, and any keys not known here."""
    print(f"{label}: {runtime(settings)} runtime; instructions "
          f"{fingerprint(settings.get('aiInstructions') or '')}")
    others = sorted(key for key in settings if key not in ("aiInstructions", "experimental"))
    if others:
        print(f"    other keys: {', '.join(others)}")


def current_description(api: Api, args: argparse.Namespace) -> str | None:
    """The published description, from the item definition; None if it has no such part."""
    url = f"{FABRIC_API}/workspaces/{args.workspace_id}/items/{args.agent_id}/getDefinition"
    for part in (api.call("POST", url).get("definition") or {}).get("parts") or []:
        if part.get("path") == DESCRIPTION_PART:
            return json.loads(base64.b64decode(part["payload"])).get("description") or ""
    return None


def show(api: Api, args: argparse.Namespace) -> int:
    """Print both stages, whether they differ, and the description; optionally save the draft."""
    draft = api.call("GET", agent_url(args, "staging/settings"))
    published = api.call("GET", agent_url(args, "settings"))
    describe("draft", draft)
    describe("published", published)
    same = ((draft.get("aiInstructions") or "") == (published.get("aiInstructions") or "")
            and runtime(draft) == runtime(published))
    print("draft and published: " + ("the same instructions and runtime" if same
                                      else "DIFFER, so a publish would change what users get"))
    try:
        description = current_description(api, args)
        print(f"description: {description!r}" if description is not None
              else "description: the definition has none")
    except ApiError as exc:
        print(f"description: unreadable ({exc})")
    if args.save:
        args.save.write_text((draft.get("aiInstructions") or "") + "\n", encoding="utf-8",
                             newline="\n")
        print(f"draft instructions saved to {args.save}")
    return 0


def set_draft(api: Api, args: argparse.Namespace) -> int:
    """PATCH the draft's instructions or runtime, then read the draft back."""
    if not args.instructions and not args.runtime:
        fail_usage("set needs --instructions, --runtime, or both")
    draft = api.call("GET", agent_url(args, "staging/settings"))
    body: dict[str, Any] = {}
    if args.instructions:
        body["aiInstructions"] = read_text(args.instructions)
    if args.runtime:
        # Carry the draft's other experimental flags across: whether PATCH merges inside
        # experimental, or replaces it whole, has not been measured.
        experimental = dict(draft.get("experimental") or {})
        experimental["enableExperimentalFeatures"] = args.runtime == "preview"
        body["experimental"] = experimental
    describe("draft before", draft)
    if args.dry_run:
        shown = {key: (fingerprint(value) if key == "aiInstructions" else value)
                 for key, value in body.items()}
        print(f"dry run: would PATCH staging/settings with {json.dumps(shown)}")
        return 0
    api.call("PATCH", agent_url(args, "staging/settings"), body)
    after = api.call("GET", agent_url(args, "staging/settings"))
    describe("draft after", after)
    held = ((not args.instructions or (after.get("aiInstructions") or "") == body["aiInstructions"])
            and (not args.runtime or runtime(after) == args.runtime))
    print("the draft holds the change" if held else "the draft does NOT hold the change")
    return 0 if held else 1


def publish(api: Api, args: argparse.Namespace) -> int:
    """Publish the draft, then check the published stage matches it."""
    if args.description:
        description = read_text(args.description)
    else:
        try:
            description = current_description(api, args)
        except ApiError as exc:
            fail_usage(f"cannot read the current description ({exc}); pass --description FILE")
        if description is None:
            fail_usage("the definition holds no description; pass --description FILE")
    draft = api.call("GET", agent_url(args, "staging/settings"))
    describe("draft", draft)
    print(f"description: {description!r}")
    if args.dry_run:
        print("dry run: would POST staging/publish with that description")
        return 0
    api.call("POST", agent_url(args, "staging/publish"), {"publishedDescription": description})
    published = api.call("GET", agent_url(args, "settings"))
    describe("published after", published)
    held = ((published.get("aiInstructions") or "") == (draft.get("aiInstructions") or "")
            and runtime(published) == runtime(draft))
    print("published now matches the draft" if held else "published does NOT match the draft")
    return 0 if held else 1


def main() -> int:
    """Parse the command line and run one command."""
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    for name, handler, summary in (
            ("show", show, "print the draft and published settings"),
            ("set", set_draft, "change the draft's instructions or runtime"),
            ("publish", publish, "publish the draft")):
        command = commands.add_parser(name, help=summary)
        command.add_argument("workspace_id", help="the agent's workspace ID")
        command.add_argument("agent_id", help="the data agent's item ID")
        command.set_defaults(handler=handler)
        if name == "show":
            command.add_argument("--save", type=Path, help="write the draft's instructions here")
        if name == "set":
            command.add_argument("--instructions", type=Path, help="file of new instructions")
            command.add_argument("--runtime", choices=("preview", "standard"))
        if name == "publish":
            command.add_argument("--description", type=Path,
                                 help="file of the description to publish with")
        if name in ("set", "publish"):
            command.add_argument("--dry-run", action="store_true",
                                 help="read and report, change nothing")
    args = parser.parse_args()
    try:
        return args.handler(Api(), args)
    except ApiError as exc:
        print(f"data-agent-settings: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())

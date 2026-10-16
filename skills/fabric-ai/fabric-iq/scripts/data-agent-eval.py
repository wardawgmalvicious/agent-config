#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "azure-identity>=1.15",
#     "fabric-data-agent-sdk==0.1.33a0",
#     "mcp>=1.9,<2",
#     "pyyaml>=6",
#     "requests>=2.31",
# ]
# ///
"""Ask a Fabric data agent a set of questions, and check each reply against its model's figures.

    uv run <dir>/data-agent-eval.py run WORKSPACE_ID AGENT_ID cases.yaml --out results.json
    uv run <dir>/data-agent-eval.py run WORKSPACE_ID AGENT_ID cases.yaml --stage sandbox
    uv run <dir>/data-agent-eval.py run WORKSPACE_ID AGENT_ID cases.yaml --route mcp --only q1,q4
    uv run <dir>/data-agent-eval.py show results.json --only top-customers
    uv run <dir>/data-agent-eval.py regrade results.json --tolerance 0.01

<dir> is this script's folder. uv installs the dependencies above into a cached environment, so
no project is needed; the SDK is pinned because it is pre-release and its names still move. It
signs in as the Azure CLI's account, so set AZURE_CONFIG_DIR first where tenants are kept apart.

The cases file is YAML or JSON: a list of questions, each with what a right answer must state.

    - id: order-value-last-month
      question: What was the order value last month?
      dax: |
        EVALUATE
        ROW ( "Order value", CALCULATE ( [Order value], DATESBETWEEN ( 'Date'[Date],
            EOMONTH ( TODAY (), -2 ) + 1, EOMONTH ( TODAY (), -1 ) ) ) )
    - id: top-customers
      question: Who were our five biggest customers by order value this year?
      dax: |
        EVALUATE
        TOPN ( 5, SUMMARIZECOLUMNS ( Customer[Name], "Value", [Order value YTD] ), [Value], DESC )
      tolerance: 0.005
    - id: forecast
      question: What will order value be next year?
      notes: should decline; with nothing to check, the reply is kept for review

Every cell the dax query returns must appear in the reply: a number to the precision the reply
writes it in (1.2M matches 1,234,567), widened by `tolerance`, a share of the value; a date in any
common form; text ignoring case and punctuation. So the query returns only what a right answer
must state, and a date rather than a label wherever the reply may word the label its own way.
`expect` lists literal values instead of, or beside, the query. The evaluation SDK's CSV, with
question and expected_answer columns, loads too, each expected_answer one literal value. Only the
reply's text is graded, since that is what a person reads: a figure that sits only in a result
file counts as missing.

The query runs against the semantic model the agent reads, found in its item definition (--model
overrides), just before and just after each question. The truth is then the model's at the
moment of asking, and where the two runs differ the data moved under the question: the case is
marked moved and passes against either.

Routes: `responses`, the default, asks through the data agent SDK's Responses client, which
serves the published agent (--stage production, the default) or the draft (--stage sandbox), and
returns a trace: the question as the agent rewrote it, and the DAX it ran. `mcp` asks the
published agent's MCP endpoint, the consumer surface, which returns the reply and any result
file but no trace.

Verdicts: pass, every value found; fail, one or more missing; review, nothing to check; error,
the question or a query failed. A failing case prints its trace. Results are written after each
question, so a run that dies keeps what it had. Exits 1 if any case failed or errored, 2 on bad
arguments, else 0.
"""

from __future__ import annotations

import argparse
import base64
import csv
import datetime as dt
import hashlib
import io
import json
import math
import re
import sys
import time
from dataclasses import dataclass
from importlib import metadata
from pathlib import Path
from typing import Any, NoReturn

FABRIC_API = "https://api.fabric.microsoft.com/v1"
POWERBI_API = "https://api.powerbi.com/v1.0/myorg"
FABRIC_SCOPE = "https://api.fabric.microsoft.com/.default"
POWERBI_SCOPE = "https://analysis.windows.net/powerbi/api/.default"
SDK = "fabric-data-agent-sdk"
ASK_TIMEOUT_SECONDS = 900
KEEP_OUTPUT_CHARS = 1500
DAX_LINES_SHOWN = 25
VERDICTS = ("pass", "fail", "review", "error")
MONTHS = ("January", "February", "March", "April", "May", "June", "July", "August",
          "September", "October", "November", "December")
# The tools' row-count lines: "The dataset contains N rows" on the preview runtime, "matched at
# least N rows" on the standard one.
ROWS_NOTE = re.compile(r"[^.\n|]*\b(?:contains|matched at least) [\d,]+ rows[^.\n|]*", re.I)
ISO_DATE = re.compile(r"^(\d{4})-(\d{2})-(\d{2})(?:[T ]\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?)?"
                      r"(?:Z|[+-]\d{2}:?\d{2})?$")
PLAIN_NUMBER = re.compile(r"^[-−]?[$€£]?\s?(?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d+)?\s?%?$")
FIGURE = re.compile(
    r"(?<![\w.,])(?P<sign>[-−])?(?P<open>\()?[$€£]?\s?"
    r"(?P<whole>\d{1,3}(?:,\d{3})+|\d+)(?:\.(?P<fraction>\d+))?"
    r"(?:\s?(?P<scale>%|percent\b|thousand\b|million\b|billion\b|[KkMmBb]\b))?(?P<close>\))?"
)
SCALES = {"k": 1e3, "thousand": 1e3, "m": 1e6, "million": 1e6, "b": 1e9, "billion": 1e9}


class ApiError(RuntimeError):
    """A REST call that failed: the request, its status, and the start of the reply."""


def fail_usage(message: str) -> NoReturn:
    """Print a usage error and exit 2."""
    print(f"data-agent-eval: {message}", file=sys.stderr)
    sys.exit(2)


def utc_now() -> dt.datetime:
    """Return the current time in UTC, to the second."""
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0)


# --- REST ----------------------------------------------------------------------------------------


class Api:
    """REST calls to Fabric and Power BI, signed in as the Azure CLI's account."""

    def __init__(self) -> None:
        from azure.identity import AzureCliCredential

        self.credential = AzureCliCredential(process_timeout=60)

    def token(self, scope: str) -> str:
        """Return a bearer token for scope."""
        return self.credential.get_token(scope).token

    def call(self, method: str, url: str, scope: str, body: dict | None = None) -> Any:
        """Send one request, wait out a long-running operation, and return the JSON reply.

        Raises:
            ApiError: On a transport failure, a 4xx or 5xx reply, or an operation that fails.
        """
        import requests

        headers = {"Authorization": f"Bearer {self.token(scope)}"}
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


def read_definition(api: Api, workspace_id: str, agent_id: str) -> dict[str, Any]:
    """Return the agent's item definition as {part path: decoded JSON}."""
    url = f"{FABRIC_API}/workspaces/{workspace_id}/items/{agent_id}/getDefinition"
    definition = api.call("POST", url, FABRIC_SCOPE)
    parts = {}
    for part in (definition.get("definition") or {}).get("parts") or []:
        try:
            parts[part["path"]] = json.loads(base64.b64decode(part["payload"]))
        except (KeyError, ValueError):
            continue
    return parts


def stage_models(parts: dict[str, Any], stage: str, workspace_id: str) -> list[dict]:
    """Return the semantic models one stage of the agent reads, from its definition."""
    folder = "published" if stage == "production" else "draft"
    models = []
    for path, source in sorted(parts.items()):
        if (path.startswith(f"Files/Config/{folder}/") and path.endswith("/datasource.json")
                and isinstance(source, dict) and source.get("type") == "semantic_model"):
            models.append({"workspace": source.get("workspaceId") or workspace_id,
                           "id": source.get("artifactId"), "name": source.get("displayName")})
    return models


def agent_state(api: Api, workspace_id: str, agent_id: str, stage: str) -> dict:
    """Return the stage's runtime and a fingerprint of its instructions, or the read's error."""
    path = "settings" if stage == "production" else "staging/settings"
    try:
        settings = api.call(
            "GET", f"{FABRIC_API}/workspaces/{workspace_id}/dataAgents/{agent_id}/{path}",
            FABRIC_SCOPE)
    except ApiError as exc:
        return {"error": str(exc)}
    instructions = settings.get("aiInstructions") or ""
    # The API leaves enableExperimentalFeatures out once it is false: missing is standard.
    preview = (settings.get("experimental") or {}).get("enableExperimentalFeatures")
    return {"runtime": "preview" if preview else "standard",
            "instructions_chars": len(instructions),
            "instructions_sha256": hashlib.sha256(instructions.encode("utf-8")).hexdigest()[:12]}


def run_truth(api: Api, model: dict, query: str) -> list[dict]:
    """Run one DAX query against the model through executeQueries and return its rows."""
    url = f"{POWERBI_API}/groups/{model['workspace']}/datasets/{model['id']}/executeQueries"
    body = {"queries": [{"query": query}], "serializerSettings": {"includeNulls": True}}
    payload = api.call("POST", url, POWERBI_SCOPE, body)
    result = (payload.get("results") or [{}])[0]
    if result.get("error"):
        raise ApiError(f"DAX error: {json.dumps(result['error'])[:800]}")
    tables = result.get("tables") or []
    return (tables[0].get("rows") or []) if tables else []


# --- Asking --------------------------------------------------------------------------------------


def parse_arguments(raw: Any) -> dict:
    """Return a function call's arguments as a dict, or an empty one."""
    if isinstance(raw, dict):
        return raw
    try:
        parsed = json.loads(raw or "{}")
    except (TypeError, ValueError):
        return {}
    return parsed if isinstance(parsed, dict) else {}


def strip_fence(code: str) -> str:
    """Drop the ```dax fence the preview runtime wraps its query in, so it runs as stored."""
    match = re.fullmatch(r"\s*```[\w-]*\n(.*?)\n?```\s*", code, re.S)
    return match.group(1) if match else code


def condense_response(dump: dict) -> dict:
    """Reduce a Responses reply to its text and its trace."""
    trace: dict[str, list] = {"rewritten": [], "tool_questions": [], "dax": [], "rows": [],
                              "outputs": []}
    reply = []
    for item in dump.get("output") or []:
        kind, name = item.get("type"), item.get("name") or ""
        if kind == "function_call":
            arguments = parse_arguments(item.get("arguments"))
            if name == "trace.analyze_semantic_model" and arguments.get("query"):
                trace["rewritten"].append(arguments["query"])
            asked = arguments.get("natural_language_query")
            if asked and asked not in trace["tool_questions"]:
                trace["tool_questions"].append(asked)
            # The DAX run: askPBI.tool.execute on the preview runtime, analyze.database.execute
            # on the standard one.
            if arguments.get("code"):
                trace["dax"].append({"step": name, "code": strip_fence(arguments["code"])})
        elif kind == "function_call_output":
            output = item.get("output")
            text = output if isinstance(output, str) else json.dumps(output)
            trace["rows"] += [match.group(0).strip() for match in ROWS_NOTE.finditer(text)]
            trace["outputs"].append(text[:KEEP_OUTPUT_CHARS])
        elif kind == "message":
            reply += [part["text"] for part in item.get("content") or [] if part.get("text")]
    answer = {"reply": "\n\n".join(reply), "trace": trace}
    if dump.get("status") not in (None, "completed"):
        error = json.dumps(dump.get("error"))[:400]
        answer["ask_error"] = f"response {dump.get('status')}: {error}"
    return answer


class ResponsesAsker:
    """Ask through the SDK's Responses client, which returns the trace."""

    def __init__(self, workspace_id: str, agent_id: str, stage: str, credential: Any) -> None:
        import contextlib

        # The SDK's import prints a log_telemetry line per sempy module; keep the report clean.
        with contextlib.redirect_stdout(io.StringIO()):
            from fabric.dataagent.client import FabricOpenAIResponses

        self.client = FabricOpenAIResponses(agent_id, workspace_id, ai_skill_stage=stage,
                                            credential=credential)

    def ask(self, question: str, keep_raw: bool) -> dict:
        """Ask one question in a conversation of its own."""
        dump = self.client.responses.create(input=question).model_dump(mode="json")
        answer = condense_response(dump)
        if keep_raw:
            answer["raw"] = dump
        return answer


class McpAsker:
    """Ask the published agent's MCP endpoint, one session per question."""

    def __init__(self, workspace_id: str, agent_id: str, api: Api) -> None:
        self.url = f"{FABRIC_API}/mcp/workspaces/{workspace_id}/dataagents/{agent_id}/agent"
        self.api = api

    def ask(self, question: str, keep_raw: bool) -> dict:
        """Ask one question in a session of its own."""
        import asyncio

        return asyncio.run(self._ask(question, keep_raw))

    async def _ask(self, question: str, keep_raw: bool) -> dict:
        from mcp import ClientSession
        from mcp.client.streamable_http import streamablehttp_client

        headers = {"Authorization": f"Bearer {self.api.token(FABRIC_SCOPE)}"}
        async with (
            streamablehttp_client(self.url, headers=headers, timeout=60,
                                  sse_read_timeout=ASK_TIMEOUT_SECONDS) as (read, write, _),
            ClientSession(read, write) as session,
        ):
            await session.initialize()
            tool = (await session.list_tools()).tools[0]
            # Learn's sample reads the argument's name from the schema rather than fix it.
            argument = next(iter(tool.inputSchema.get("properties") or {"question": None}))
            result = await session.call_tool(
                tool.name, {argument: question},
                read_timeout_seconds=dt.timedelta(seconds=ASK_TIMEOUT_SECONDS))
        dump = result.model_dump(mode="json")
        blocks = dump.get("content") or []
        answer: dict[str, Any] = {
            "reply": "\n".join(block.get("text") or "" for block in blocks
                               if block.get("type") == "text"),
            "files": [{"uri": block["resource"].get("uri"),
                       "lines": len((block["resource"].get("text") or "").splitlines())}
                      for block in blocks if block.get("type") == "resource"],
        }
        if dump.get("isError"):
            answer["ask_error"] = f"tool error: {answer['reply'][:400]}"
        if keep_raw:
            answer["raw"] = dump
        return answer


# --- Cases ---------------------------------------------------------------------------------------


def json_safe(value: Any) -> Any:
    """Turn a YAML date into the ISO text a results file can hold."""
    return value.isoformat() if isinstance(value, (dt.date, dt.datetime)) else value


def load_cases(path: Path, only: set[str]) -> list[dict]:
    """Read the cases file into a list of {id, question, dax, expect, tolerance, notes}.

    Args:
        path: A YAML, JSON or CSV cases file.
        only: Case ids to keep; empty keeps every case.

    Returns:
        The cases in file order.
    """
    try:
        text = path.read_text(encoding="utf-8-sig")
    except OSError as exc:
        fail_usage(f"cannot read {path}: {exc}")
    if path.suffix.lower() == ".csv":
        raw: Any = [
            {"id": row.get("id"), "question": row.get("question"), "dax": row.get("dax"),
             "expect": [row["expected_answer"]] if (row.get("expected_answer") or "").strip()
             else []}
            for row in csv.DictReader(io.StringIO(text))
        ]
    else:
        import yaml  # JSON is YAML, so one loader reads both

        try:
            raw = yaml.safe_load(text)
        except yaml.YAMLError as exc:
            fail_usage(f"{path}: {exc}")
    if not isinstance(raw, list):
        fail_usage(f"{path}: expected a list of cases")
    cases, seen = [], set()
    for number, item in enumerate(raw, 1):
        if not isinstance(item, dict) or not str(item.get("question") or "").strip():
            fail_usage(f"{path}: case {number} has no question")
        case_id = str(item.get("id") or f"q{number}")
        if case_id in seen:
            fail_usage(f"{path}: case id {case_id} appears twice")
        seen.add(case_id)
        expect = item.get("expect") or []
        try:
            tolerance = float(item.get("tolerance") or 0.0)
        except (TypeError, ValueError):
            fail_usage(f"{path}: case {case_id} has a tolerance that is not a number")
        cases.append({
            "id": case_id,
            "question": str(item["question"]).strip(),
            "dax": str(item["dax"]).strip() if str(item.get("dax") or "").strip() else None,
            "expect": [json_safe(value) for value in (expect if isinstance(expect, list)
                                                       else [expect])],
            "tolerance": tolerance,
            "notes": str(item.get("notes") or "").strip(),
        })
    unknown = only - seen
    if unknown:
        fail_usage(f"no case with id {', '.join(sorted(unknown))}")
    return [case for case in cases if not only or case["id"] in only]


# --- Grading -------------------------------------------------------------------------------------


@dataclass(frozen=True)
class Figure:
    """A number as a reply writes it: its value, how precisely it is written, and how."""

    text: str
    value: float
    precision: float
    percent: bool
    signed: bool


def figures(reply: str) -> list[Figure]:
    """Return every number the reply writes, with the precision its digits imply."""
    found = []
    for match in FIGURE.finditer(reply):
        whole, fraction = match.group("whole").replace(",", ""), match.group("fraction") or ""
        value = float(f"{whole}.{fraction}" if fraction else whole)
        if fraction:
            precision = 0.5 * 10 ** -len(fraction)
        else:
            # 1,235,000 may be 1,234,567 rounded, but 1,000 is not 1,234: trailing zeros widen
            # the precision only while it stays within half a percent of the value.
            zeros = len(whole) - len(whole.rstrip("0"))
            coarse = 0.5 * 10 ** zeros
            precision = coarse if zeros and coarse <= 0.005 * value else 0.5
        scale = (match.group("scale") or "").lower()
        factor = SCALES.get(scale, 1.0)
        negative = bool(match.group("sign")) or bool(match.group("open") and match.group("close"))
        found.append(Figure(match.group(0).strip(), (-value if negative else value) * factor,
                            precision * factor, scale in ("%", "percent"), negative))
    return found


def normalise(text: str) -> str:
    """Casefold, and turn every run of punctuation, markup and space into one space."""
    return " ".join(re.sub(r"[\W_]+", " ", text.casefold()).split())


def text_found(expected: str, words: str) -> bool:
    """Whether the normalised reply holds the text as whole words."""
    needle = normalise(expected)
    return bool(needle) and re.search(rf"(?<!\w){re.escape(needle)}(?!\w)", words) is not None


def number_found(expected: float, found: list[Figure], tolerance: float) -> bool:
    """Whether any figure in the reply is the number, to the precision the reply writes it."""
    for figure in found:
        # 12.5% states 0.125 as well as 12.5.
        for target in ([expected, expected * 100] if figure.percent else [expected]):
            # An unsigned figure is a magnitude: "fell by 1,234" states -1,234.
            target = target if figure.signed else abs(target)
            slack = figure.precision + tolerance * abs(target) + 1e-9 * max(1.0, abs(target))
            if abs(target - figure.value) <= slack:
                return True
    return False


def date_found(day: dt.date, words: str) -> bool:
    """Whether the normalised reply states the date in a common form."""
    month, short = MONTHS[day.month - 1], MONTHS[day.month - 1][:3]
    forms = [day.isoformat(), f"{day.month}/{day.day}/{day.year}",
             f"{day.month:02d}/{day.day:02d}/{day.year}", f"{month} {day.day}, {day.year}",
             f"{short} {day.day}, {day.year}", f"{day.day} {month} {day.year}",
             f"{day.day} {short} {day.year}"]
    if day.day == 1:  # a month's first day usually stands for the month
        forms += [f"{month} {day.year}", f"{short} {day.year}", f"{day.year}-{day.month:02d}"]
    return any(text_found(form, words) for form in forms)


def expectation(label: str, raw: Any) -> dict | None:
    """Classify one truth cell or `expect` entry as a number, date or text; None to skip it."""
    if raw is None or isinstance(raw, bool):
        return None
    if isinstance(raw, (int, float)):
        return None if math.isnan(raw) else {"label": label, "kind": "number", "value": float(raw)}
    text = str(json_safe(raw)).strip()
    if not text:
        return None
    match = ISO_DATE.match(text)
    if match:
        day = dt.date(int(match[1]), int(match[2]), int(match[3]))
        return {"label": label, "kind": "date", "value": day.isoformat()}
    if PLAIN_NUMBER.match(text):
        number = float(re.sub(r"[^\d.]", "", text))
        negative = text.lstrip()[:1] in ("-", "−")
        return {"label": label, "kind": "number", "value": -number if negative else number}
    return {"label": label, "kind": "text", "value": text}


def item_found(item: dict, found: list[Figure], words: str, tolerance: float) -> bool:
    """Whether the reply states one expected value."""
    if item["kind"] == "number":
        return number_found(item["value"], found, tolerance)
    if item["kind"] == "date":
        return date_found(dt.date.fromisoformat(item["value"]), words)
    return text_found(item["value"], words)


def grade(record: dict, tolerance: float | None = None) -> None:
    """Set the record's expected, missing, found, moved and verdict from its reply and truth."""
    tolerance = record.get("tolerance", 0.0) if tolerance is None else tolerance
    reply = record.get("reply") or ""
    found, words = figures(reply), normalise(reply)
    record["figures"] = [figure.text for figure in found][:60]
    truths = [record[key] for key in ("truth_before", "truth_after") if key in record]
    record["moved"] = len(truths) == 2 and truths[0] != truths[1]
    literal = [expectation("expect", value) for value in record.get("expect") or []]
    best: tuple[list, list] | None = None
    for rows in (truths if record["moved"] else truths[:1]) or [[]]:
        expected = [item for item in literal + [expectation(column, value) for row in rows
                                                for column, value in row.items()] if item]
        missing = [item for item in expected if not item_found(item, found, words, tolerance)]
        if best is None or len(missing) < len(best[1]):
            best = (expected, missing)
    expected, missing = best or ([], [])
    record.update(expected=expected, missing=missing, found=len(expected) - len(missing))
    if record.get("ask_error") or record.get("truth_error"):
        record["verdict"] = "error"
    elif not expected:
        record["verdict"] = "review"
    else:
        record["verdict"] = "fail" if missing else "pass"


# --- Reporting -----------------------------------------------------------------------------------


def shown(item: dict) -> str:
    """One expected value as the report prints it."""
    value = item["value"]
    text = f"{value:,.6f}".rstrip("0").rstrip(".") if item["kind"] == "number" else str(value)
    return f"{item['label']} = {text}"


def print_case(record: dict, full: bool) -> None:
    """Print one case: its verdict line, then what a reader needs to judge it."""
    head = f"[{record['verdict']}] {record['id']}  {record.get('question') or ''}".rstrip()
    if record.get("seconds") is not None:
        head += f"  ({record['seconds']} s)"
    if record.get("moved"):
        head += "  [the truth moved during the question]"
    print(head)
    if record.get("notes"):
        print(f"    notes: {record['notes']}")
    for key in ("ask_error", "truth_error"):
        if record.get(key):
            print(f"    {key.replace('_', ' ')}: {record[key]}")
    if record.get("dax") and not (record.get("truth_before") or record.get("truth_after")) \
            and not record.get("truth_error"):
        print("    the truth query returned no rows")
    if record.get("expected"):
        print(f"    found {record['found']} of {len(record['expected'])}")
    for item in record.get("missing") or []:
        print(f"    missing: {shown(item)}")
    if not full and record["verdict"] == "pass":
        return
    trace = record.get("trace") or {}
    for text in trace.get("rewritten") or []:
        print(f"    rewritten: {text}")
    for text in trace.get("tool_questions") or []:
        print(f"    asked the tool: {text}")
    for step in trace.get("dax") or []:
        lines = step["code"].strip().splitlines()
        limit = len(lines) if full else DAX_LINES_SHOWN
        print(f"    DAX run ({step['step']}):")
        for line in lines[:limit]:
            print(f"        {line}")
        if len(lines) > limit:
            print(f"        ... {len(lines) - limit} more lines: show --only {record['id']}")
    for note in trace.get("rows") or []:
        print(f"    tool: {note}")
    for file in record.get("files") or []:
        print(f"    file: {file['uri']} ({file['lines']} lines)")
    if record["verdict"] == "fail" and record.get("figures"):
        print(f"    figures in the reply: {', '.join(record['figures'][:25])}")
    if full or record["verdict"] in ("review", "error"):
        print("    reply:")
        for line in (record.get("reply") or "(none)").splitlines():
            print(f"        {line}")


def tally(records: list[dict]) -> str:
    """The verdict counts, in a fixed order."""
    counts = {verdict: sum(record["verdict"] == verdict for record in records)
              for verdict in VERDICTS}
    return ", ".join(f"{verdict} {counts[verdict]}" for verdict in VERDICTS)


def print_run(meta: dict) -> None:
    """Print what was asked of what, from a results file's run block."""
    model = meta.get("model") or {}
    state = meta.get("agent_state") or {}
    print(f"agent {meta['agent']} in {meta['workspace']}, {meta['stage']} stage, "
          f"{meta['route']} route, {meta.get('sdk') or 'no SDK'}")
    if state.get("error"):
        print(f"agent settings unreadable: {state['error']}")
    elif state:
        print(f"agent: {state['runtime']} runtime, instructions {state['instructions_chars']} "
              f"chars, sha256 {state['instructions_sha256']}")
    if model:
        print(f"truth from model {model.get('name') or model['id']} ({model['id']})")
    finished = meta.get("finished_utc")
    print(f"started {meta['started_utc']}" + (f", finished {finished}" if finished else ""))
    print()


def save(path: Path, results: dict) -> None:
    """Write the results file whole, LF line ends."""
    path.write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n", encoding="utf-8",
                    newline="\n")


def load_results(path: Path) -> dict:
    """Read a results file that `run` wrote."""
    try:
        results = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        fail_usage(f"cannot read {path}: {exc}")
    if not isinstance(results, dict) or "cases" not in results:
        fail_usage(f"{path} is not a results file")
    return results


def parse_only(text: str) -> set[str]:
    """Split a comma-separated list of case ids."""
    return {part.strip() for part in text.split(",") if part.strip()}


# --- Commands ------------------------------------------------------------------------------------


def resolve_model(api: Api, args: argparse.Namespace, needed: bool) -> dict | None:
    """Return the model the truth queries run against: --model, else the agent's own."""
    if args.model:
        return {"workspace": args.model_workspace or args.workspace_id, "id": args.model,
                "name": None}
    if not needed:
        return None
    try:
        models = stage_models(read_definition(api, args.workspace_id, args.agent_id),
                              args.stage, args.workspace_id)
    except ApiError as exc:
        fail_usage(f"cannot read the agent's definition to find its model ({exc}); "
                   f"pass --model MODEL_ID")
    if len(models) != 1:
        names = ", ".join(f"{model['name']} ({model['id']})" for model in models) or "none"
        fail_usage(f"the agent's {args.stage} stage reads {len(models)} semantic models "
                   f"({names}); pass --model MODEL_ID")
    return models[0]


def evaluate_case(case: dict, asker: Any, api: Api, model: dict | None, keep_raw: bool) -> dict:
    """Ask one case's question between two runs of its truth query, and keep everything."""
    record = {key: case[key] for key in ("id", "question", "notes", "tolerance", "expect", "dax")}
    if case["dax"]:
        try:
            record["truth_before"] = run_truth(api, model, case["dax"])
        except ApiError as exc:
            record["truth_error"] = str(exc)
    record["asked_utc"] = utc_now().isoformat()
    started = time.monotonic()
    try:
        record.update(asker.ask(case["question"], keep_raw))
    except Exception as exc:  # noqa: BLE001 - one failed question must not lose the rest
        record["ask_error"] = f"{type(exc).__name__}: {exc}"
    record["seconds"] = round(time.monotonic() - started, 1)
    if case["dax"] and "truth_error" not in record:
        try:
            record["truth_after"] = run_truth(api, model, case["dax"])
        except ApiError as exc:
            record["truth_error"] = str(exc)
    return record


def run(args: argparse.Namespace) -> int:
    """Ask every case, grade it, and write the results after each one."""
    if args.route == "mcp" and args.stage == "sandbox":
        fail_usage("the MCP endpoint serves only the published agent: use --route responses "
                   "for the draft")
    cases = load_cases(args.cases, parse_only(args.only))
    api = Api()
    model = resolve_model(api, args, needed=any(case["dax"] for case in cases))
    if args.route == "responses":
        asker: Any = ResponsesAsker(args.workspace_id, args.agent_id, args.stage, api.credential)
    else:
        asker = McpAsker(args.workspace_id, args.agent_id, api)
    try:
        sdk = f"{SDK} {metadata.version(SDK)}"
    except metadata.PackageNotFoundError:
        sdk = None
    started = utc_now()
    out = args.out or args.cases.with_name(f"{args.cases.stem}-{started:%Y%m%dT%H%M%SZ}.json")
    results: dict[str, Any] = {
        "run": {"workspace": args.workspace_id, "agent": args.agent_id, "stage": args.stage,
                "route": args.route, "sdk": sdk if args.route == "responses" else None,
                "agent_state": agent_state(api, args.workspace_id, args.agent_id, args.stage),
                "model": model, "cases_file": str(args.cases),
                "started_utc": started.isoformat(), "finished_utc": None},
        "cases": [],
    }
    print_run(results["run"])
    for case in cases:
        record = evaluate_case(case, asker, api, model, args.keep_raw)
        grade(record)
        results["cases"].append(record)
        print_case(record, full=False)
        save(out, results)
    results["run"]["finished_utc"] = utc_now().isoformat()
    save(out, results)
    print(f"\n{tally(results['cases'])}; results in {out}")
    return 1 if any(record["verdict"] in ("fail", "error") for record in results["cases"]) else 0


def show(args: argparse.Namespace) -> int:
    """Print a results file in full: each case's reply, trace and DAX."""
    results = load_results(args.results)
    only = parse_only(args.only)
    print_run(results["run"])
    for record in results["cases"]:
        if not only or record["id"] in only:
            print_case(record, full=True)
            print()
    print(tally(results["cases"]))
    return 0


def regrade(args: argparse.Namespace) -> int:
    """Grade a results file's replies again against its stored truth, asking nothing."""
    results = load_results(args.results)
    for record in results["cases"]:
        grade(record, args.tolerance)
        print_case(record, full=False)
    print(f"\n{tally(results['cases'])}")
    if args.write:
        save(args.results, results)
    return 1 if any(record["verdict"] in ("fail", "error") for record in results["cases"]) else 0


def main() -> int:
    """Parse the command line and run one command."""
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)

    run_parser = commands.add_parser("run", help="ask every case and grade the replies")
    run_parser.add_argument("workspace_id", help="the agent's workspace ID")
    run_parser.add_argument("agent_id", help="the data agent's item ID")
    run_parser.add_argument("cases", type=Path, help="YAML, JSON or CSV cases file")
    run_parser.add_argument("--route", choices=("responses", "mcp"), default="responses")
    run_parser.add_argument("--stage", choices=("production", "sandbox"), default="production",
                            help="production is the published agent, sandbox the draft")
    run_parser.add_argument("--model", help="the semantic model's ID; default: the agent's own")
    run_parser.add_argument("--model-workspace", help="the model's workspace, if not the agent's")
    run_parser.add_argument("--only", default="", help="comma-separated case ids")
    run_parser.add_argument("--out", type=Path,
                            help="results file; default: <cases>-<UTC time>.json beside it")
    run_parser.add_argument("--keep-raw", action="store_true",
                            help="keep each whole response in the results file")
    run_parser.set_defaults(handler=run)

    show_parser = commands.add_parser("show", help="print a results file in full")
    show_parser.add_argument("results", type=Path)
    show_parser.add_argument("--only", default="", help="comma-separated case ids")
    show_parser.set_defaults(handler=show)

    regrade_parser = commands.add_parser("regrade",
                                         help="grade stored replies again, asking nothing")
    regrade_parser.add_argument("results", type=Path)
    regrade_parser.add_argument("--tolerance", type=float,
                                help="replace every case's tolerance")
    regrade_parser.add_argument("--write", action="store_true",
                                help="save the new verdicts into the results file")
    regrade_parser.set_defaults(handler=regrade)

    args = parser.parse_args()
    return args.handler(args)


if __name__ == "__main__":
    sys.exit(main())

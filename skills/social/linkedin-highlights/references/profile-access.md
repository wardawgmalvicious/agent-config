# Programmatic access to the LinkedIn profile

**This skill does not use it and should not depend on it.** The output
stays text the user pastes by hand. This page records why, so the
question is not re-opened from scratch: it was deferred when the skill
was authored, and answered **no** on 2026-09-10.

## Why the question arises

The measured section of [highlights-format.md](highlights-format.md)
comes from the user's own published entries, and those sit behind
LinkedIn's login wall — an unauthenticated fetch cannot read them, as
recorded on that page. So re-measuring the spec means either the user
supplying entries again, or something that can read the profile as them.

## The candidate reviewed

[linkedin-mcp-server](https://github.com/stickerdaniel/linkedin-mcp-server),
a community MCP server, not affiliated with LinkedIn. Reviewed at commit
`70e50ada` on 2026-09-10 by reading its source, not by running it.

- **It drives a real browser logged in as the user** and scrapes the
  rendered pages. The session is stored under `~/.linkedin-mcp` after a
  one-time interactive login.
- **19 tools**: 18 in `linkedin_mcp_server/tools/`, plus `close_session`
  in `server.py`.
- **`get_my_profile` is the one that matters here.** It navigates to
  `/in/me/` and takes a `sections` argument. `experience` must be
  requested explicitly — the default reads only the main page — and each
  section comes back as raw page text for the model to parse. The source
  tags the tool `scraping`.
- **Two tools act as the user**: `send_message`, annotated
  `destructiveHint`, and `connect_with_person`. The README describes the
  server as reading LinkedIn data, which undersells this; both were found
  in the source, and a first pass over the README's tool names missed
  them.

## Why the skill does not use it

- **No write path exists for an Experience entry.** None of the 19 tools
  edits a profile field, so even a full integration would end with the
  user pasting text — which is where the skill already ends.
- **The account risk lands on the asset the skill exists to serve.** The
  author's own README: *"LinkedIn's User Agreement prohibits automated
  access, and accounts using automated tools can be restricted or
  banned. Use at your own risk; there is no guarantee of account
  safety."* It also carries advice on proxies and on avoiding login
  checkpoints, which says the platform's defences are real.
- **It can act as the user.** A server that sends messages and
  connection requests under the user's name, through automation the
  platform prohibits, is not a read tool to leave wired in.
- **Full entry text is unverified.** LinkedIn telescopes long entries
  behind "see more", and whether the scrape expands them or captures only
  the preview was not established. A truncated entry would corrupt the
  measured spec with nothing to say so.
- **Its surface is wide.** It includes reading the inbox and
  conversations. If it is ever wired in, scope it to one project, never
  user scope — a user-scope server loads every tool into every session,
  including ones where it cannot fire.

## The one legitimate use

A **deliberate, one-off re-measurement** of the format spec — when the
field changes, or the user's register drifts — and only once all of
these hold:

1. One test confirms `get_my_profile` returns an entry's full text, not
   the "see more" preview. Compare it against the same entry pasted by
   hand.
2. It is wired at project scope or run ad hoc, and removed afterwards.
3. The user accepts the account risk knowingly, for that run.
4. The entries are still not retained. Measure, abstract into
   [highlights-format.md](highlights-format.md), discard — the same rule
   a hand-supplied entry follows.

Hand-supplied entries remain the default. They worked on 2026-09-10 and
carry none of the risk above.

## Re-open when

- **LinkedIn ships a sanctioned way to write an Experience entry.** That
  closes the one loop this page says cannot be closed, and is the only
  change that would alter the skill's design rather than just how its
  evidence is gathered.
- **This server, or another, stops driving a logged-in session.**
  Re-read the source at the new commit; do not carry this review forward.

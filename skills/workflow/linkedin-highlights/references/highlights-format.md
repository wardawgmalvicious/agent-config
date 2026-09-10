# The LinkedIn Highlights field

What the field is, what it accepts, and how prose should be shaped for
it. Three provenance classes below, kept separate on purpose — treat
them differently when reporting to the user.

## Primary evidence

From the user's own screenshot of the LinkedIn **Edit role** dialog,
2026-09-10. This is the best available source and the only hard evidence
about the field itself.

- The field is labelled **Highlights**.
- It is a **single plain textarea** with **no formatting toolbar** — no
  bold, no italics, no list buttons, no link control.
- Its helper text is *"Projects, problems you solved, or results you
  achieved"*.
- A live counter reads `0/2,000`. **The 2,000-character cap rests on
  this**, not on any article.

## Measured from real entries

Three of the user's own published Highlights entries, supplied
2026-09-10 and measured directly. **The entries themselves are not
retained** — this section is the abstracted result, which is the whole
reason it exists in this form.

This is the strongest evidence on this page after the screenshot, and
where it disagrees with the convention section below, **it wins**.

### Shape

| Property | Measured range |
| --- | --- |
| Length | 1,468–1,666 characters — **73–83% of the 2,000 budget** |
| Paragraphs | 3–4, separated by a blank line |
| Paragraph length | 343–735 characters |
| Sentences | 7–9 total; 2–3 per paragraph |
| Words | 194–214; **22–31 words per sentence** |
| Bullets | **zero** |

Two things to take from the table. **Nobody writes to the cap** — every
entry leaves 330–530 characters unused, so 2,000 is a ceiling and about
1,500 is the target. And the sentences are **long**; a draft averaging
15 words per sentence is not in this register.

### Bullets are not used at all

**All three entries are continuous prose. There are no `•` characters,
no markdown list markers, and no line breaks inside a paragraph.**
Structure is carried entirely by paragraph breaks and by the framing
clause each paragraph opens on.

This directly contradicts the "3–5 bullets per role" convention in the
advice articles below. Three real entries beat the articles: **write
prose paragraphs.** Offer bullets only if the user asks for them.

### Register

- **First person, past tense, active voice.** 7–9 instances of "I" per
  entry — roughly one per sentence.
- **Paragraph 1 always opens `At <Organization>, I <led / built / was
  brought in to> …`** All three do this, without exception.
- **Later paragraphs open on a framing adverbial, not on "I".** The
  observed set: `Serving as the organization's <domain> subject matter
  expert,` / `To strengthen <business area>,` / `Beyond <discipline>,` /
  `Expanding into <area>,`. A bare `I <verb>` opener appears once across
  the three.
- **One theme per paragraph**, in a consistent progression: platform
  foundation → the user's role plus automation → the BI and semantic
  layer → expansion (AI, administration, cost).

### The defining move: outcome attached to activity, in the same sentence

**16 of 25 sentences carry the result in a trailing clause on the
activity that produced it** — a participle (`enabling…`, `eliminating…`,
`achieving…`, `replacing…`, `giving…`, `saving…`) or an em-dash leading
into the consequence.

There is never a bare list of activities, and never a separate
"results" paragraph. A sentence that names what was built and stops has
not been finished.

### Numbers are rare and land at the end

**Exactly one hard figure appears across all three entries** — a dollar
saving, and it is the final sentence of its entry. Everything else is
qualitative: *eliminated duplication*, *faster refresh times*,
*significant compute savings*, *a single point of truth*.

Match that. A qualitative outcome is the norm here, and a single
concrete number lands hardest as the closer. This is not a licence to
skip the outcome — it is a licence to state it in words when no
defensible figure exists, which is exactly what step 5 of the skill
asks the user for.

### Punctuation and characters

- **5 em-dashes across three entries**, concentrated in opening
  paragraphs, used to attach a consequence. One appears unspaced
  (`collections—reducing`); the rest are spaced.
- **Straight apostrophes throughout** — zero U+2019 curly quotes.
- No headings, no bold, no links, no markdown of any kind.

## Convention, not verified platform behaviour

Everything below comes from **LinkedIn Pulse and advice articles —
user-generated content**, retrieved 2026-09-10. One official LinkedIn
Help URL was attempted and returned HTTP 404; **no official page
documenting these was located.**

Report these to the user as convention with the date attached. Do not
assert them as platform behaviour.

- **Bullets are a character, not a feature.** `•` (U+2022) is typed by
  the author; markdown list syntax does not render. *Relevant only if
  the user asks for bullets — the measured entries use none.*
- **~~3–5 bullets per role.~~ Contradicted by the measured entries**
  (2026-09-10). Kept here only so a future reader knows it was
  considered and overruled rather than missed.
- **Blank lines between paragraphs survive.** Corroborated by the
  measured entries, which rely on them entirely.
- **Pasting from a rich-text source can destroy line breaks.** Word,
  Notion and Google Docs are the named culprits; the editor is
  rich-text HTML and handles plain-text paste from them poorly. Paste as
  plain text.
- **The profile telescopes a long entry behind "see more"**, so the
  opening lines carry disproportionate weight.
- A **200-character minimum** is cited. Unconfirmed against the dialog,
  and far below the measured floor of 1,468.

### Open question, deliberately unresolved

**Whether "Highlights" is the same field as the "description" older
articles describe.** The screenshot shows a field named Highlights with
a 2,000-character cap; the articles describe an Experience
*description* with the same cap. Same limit — possibly a rename,
possibly two distinct fields. Not established. Describe the field as the
screenshot shows it and do not assert the equivalence.

## Counting characters

LinkedIn's counter counts characters. **`wc -m` does not, on this
machine**: `LANG` and `LC_ALL` are empty in both shells, so it falls
back to bytes and every multi-byte character — `•` and `—` among them —
over-counts by 2.

Measured 2026-09-10 on `• abc`, which is 5 characters:

| Command | Result |
| --- | --- |
| `wc -c` | 7 |
| `wc -m` | 7 |
| `LC_ALL=C.UTF-8 wc -m` | **5** |
| Python `len()` on a UTF-8 read | **5** |

Use either of the last two. Em-dashes make this bite even in a
bullet-free draft: five of them is a ten-character over-count.

## Worked example

**Synthetic.** Invented organization, invented client, invented figures.
It is written to the spec above and exists to show the shape — it is not
a template of verified claims, and none of its numbers came from
anywhere.

> At Meridian Freight, I designed and built the company's first
> governed analytics platform on Microsoft Fabric, replacing a sprawl of
> scheduled exports no two departments read alike. I stood
> up a medallion lakehouse that consolidated eleven source systems into
> a single curated layer — retiring the duplicate extracts that had made
> month-end reconciliation a three-day exercise. To make delivery
> repeatable, I established Git-integrated workspaces across
> development, test, and production, bringing source control and
> reviewable deployments to a platform previously changed in place.
>
> Serving as the organization's Fabric subject matter expert, I
> architected metadata-driven ingestion pipelines powered by a control
> table, replacing fourteen hand-maintained dataflows with a single
> parameterized pattern and cutting the capacity those refreshes
> consumed. I also built an onboarding framework that provisions a new
> carrier's workspace, security groups and staging tables from one
> stored procedure — turning a two-week manual setup into a same-day
> operation.
>
> To strengthen reporting, I modeled an enterprise semantic layer on
> Direct Lake, giving analysts consistent, certified measures in place
> of the ad hoc SQL each team had been writing for itself. I paired it
> with row-level security on the depot hierarchy, so branch managers
> reached their own volumes without a report per site. A review of idle
> Azure resources decommissioned three unused capacities, saving roughly
> $31,000 annually.

Check it against the spec: 3 paragraphs, opens `At <Org>, I …`, later
paragraphs open on framing adverbials, one theme each, every sentence
carries its outcome, a single hard figure as the closer, no bullets.

## What is not on this page

- **Any LinkedIn API or MCP server.** Nothing in this skill assumes
  programmatic profile access; the output is text the user pastes by
  hand. Answered **no** on 2026-09-10, with the reasoning in
  [profile-access.md](profile-access.md).
- **The user's real entries, verbatim.** Read once to derive the
  measured section, deliberately not retained — the spec is what
  survives, which keeps the skill portable rather than personal. An
  unauthenticated fetch of the public profile on 2026-09-10 could not
  read them either: the Experience section returned role locations with
  no titles and no description text.
- **Resume and CV bullet conventions**, and every profile field other
  than this one. Out of scope by decision.

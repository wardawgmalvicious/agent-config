# MS Learn link bundle — Power BI Semantic Model AI Instructions

Curated set of Microsoft Learn pages relevant to authoring AI instructions on a Power BI semantic model and the broader "Prep data for AI" surface. Load on demand when you need authoritative reference for a specific feature (instructions blob, verified answers, AI data schema, linguistic schema / Q&A).

The three highest-leverage entry points (instructions, prep-for-AI overview, verified answers) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

## Overview and feature catalog

- [Prepare your data for AI (overview)](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai) — the four "Prep data for AI" features (AI data schemas, verified answers, AI instructions, descriptions) and where each is authored (Desktop vs service).
- [Prep data for AI — FAQ](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai-faq) — Microsoft's compact summary of which feature does what. Useful as an at-a-glance refresher when triaging where a particular concern belongs.

## AI instructions blob (the 10K-character text attached to the model)

- [Prepare your data for AI: AI instructions](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai-instructions) — authoritative reference for the AI instructions feature: what it is, how to author, where it applies, limitations. Microsoft's primary doc for the surface this skill covers.

## Companion features (often paired with AI instructions)

- [Prepare your data for AI: Verified answers](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai-verified-answers) — the visual + trigger-phrase mechanism. Use Verified Answers instead of stuffing Q&A pairs into the AI instructions blob.
- [Prepare your data for AI: AI data schemas](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai-data-schema) — selecting a subset of the model schema for Copilot consumption. Distinct from the instructions blob and from per-column hide flags.

## Tutorial and best-practice walkthroughs

- [Tutorial: Prepare semantic model for AI](https://learn.microsoft.com/power-bi/create-reports/tutorial-copilot-power-bi-prepare-model) — end-to-end tutorial: simplify schema, add verified answers, write AI instructions, mark as Prepped for AI. Good hands-on starting point.
- [Use Copilot with semantic models (developer guidance)](https://learn.microsoft.com/power-bi/create-reports/copilot-semantic-models) — broader guidance for building Copilot-friendly models: naming conventions, descriptions, linguistic schema, DAX query view tips. Covers the whole authoring surface this skill is one part of.
- [Ask Copilot for data from your model](https://learn.microsoft.com/power-bi/create-reports/copilot-ask-data-question) — consumer-facing perspective on how Copilot uses the model when answering questions. Useful for understanding what your authoring is in service of.

## Linguistic schema (Q&A — overlaps with but is distinct from AI instructions)

- [Q&A best practices](https://learn.microsoft.com/power-bi/natural-language/q-and-a-best-practices) — naming, synonyms, relationships. Per-column synonyms belong in TMDL `synonyms`, not in the AI instructions blob — this page explains the right home.
- [Enable Q&A and Q&A data sources](https://learn.microsoft.com/power-bi/natural-language/q-and-a-data-sources) — turning Q&A on for the model (prerequisite for the "Prep data for AI" tabs to be enabled in Desktop and service).
- [Intro to Q&A tooling](https://learn.microsoft.com/power-bi/natural-language/q-and-a-tooling-intro) — the Q&A setup window where synonyms and linguistic relationships live, with Copilot-suggested options.

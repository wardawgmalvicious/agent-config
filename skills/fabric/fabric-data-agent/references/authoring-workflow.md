# Fabric Data Agent: authoring workflow and best practices

Split out of the parent `fabric-data-agent` SKILL.md, which keeps the pitfalls
table. This file is the positive-form guidance: how to run the authoring loop
and operate an agent once it is live.

## Best practices

- **Scope each instruction to the right layer.** Source-specific guidance in the top-level blob creates noise. Generic business context duplicated across every data source blob creates drift.
- **Keep layers focused and non-contradictory.** Conflicts between layers cause the LLM to hedge or hallucinate.
- **Iterate against real questions.** Write, test, observe failures, adjust. Don't assume a single pass is sufficient.
- **Version control the instructions** alongside the rest of the data platform code. Treat them as first-class artifacts — use Git integration on the Fabric workspace to track changes.
- **Use example queries aggressively** on lakehouse/warehouse/KQL sources. They are the single most effective configuration mechanism for query accuracy.
- **Maintain a regression question bank.** When instructions change, re-run the bank and check for accuracy drift.
- **Use deployment pipelines** to promote agent changes through dev/test/prod.
- **Establish operational oversight.** Monitor interactions via built-in diagnostics, set up logging and audit, and review instructions periodically as data or business rules change.

## Key differences from Semantic Model AI Instructions

- **Structure** — data agent has 4 configuration layers; semantic model has one unstructured text blob.
- **Multi-source** — data agent routes across up to 5 sources; semantic model instructions apply to exactly one model.
- **Example queries / few-shot** — data agent supports them on lakehouse/warehouse/KQL sources (not on semantic model sources); semantic model instructions don't support few-shot.
- **Response formatting and conversational behavior** — configurable in the data agent; explicitly out of scope for semantic model instructions.
- **Character limit** — semantic model is capped at 10,000 characters; data agent doesn't document a single hard limit but each layer has practical length constraints.
- **Consumption surface** — data agent instructions apply only in the agent chat; semantic model instructions apply everywhere Copilot uses the model (reports, Q&A, Copilot chat).

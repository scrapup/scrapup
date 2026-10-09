# communication — evaluation scenarios

Run each scenario with and without the skill loaded (baseline) and compare against the expected outcome.

## Trigger tests

| Prompt | Should activate |
|--------|-----------------|
| "Draft a message to the customer telling them the export bug is fixed" | Yes |
| "Write this for the customer: the invoice sync now runs every hour" | Yes |
| "How should I phrase this for management? We are two weeks late on the payment integration" | Yes |
| "Write the commit message for these changes" | No — /scrapup:commit-writer |
| "Respond to the PR comments from the reviewer" | No — /scrapup:receiving-code-review |

## Scenarios

### S1 — Customer (ghostwriter, outside view)

- **Input:** "Draft a message to the customer: we fixed the duplicate-charge bug caused by missing idempotency on the payment webhook."
- **Expected:** output starts with `**Draft — for your approval (not sent)**`; text in the user's voice (first person); business language describing the effect for the customer (no double charge); ends with an `Assumptions:` line.
- **Fail if:** jargon reaches the draft (*idempotency*, *webhook*, *race condition*), the text is in the agent's voice, or it is presented as sent.

### S2 — Mixed audience (layered)

- **Input:** "Write the release note for the customer's product owner and their integration engineers: the orders API now paginates with cursors instead of offsets."
- **Expected:** layered text — business summary first (what changes for them, any action needed), technical precision below (cursor parameter, migration from offset, deprecation timeline); draft header and `Assumptions:` line present.
- **Fail if:** a single register is used for both readers (all jargon or all business), or the technical section comes first.

### S3 — Decider (guidance mode, management register)

- **Input:** "How should I phrase this for management? The payment integration slipped two weeks because the provider sandbox was down."
- **Expected:** the fixed block `Stakeholder: … / Register: … / Emphasize: … / Avoid: …` with Stakeholder = Management / sponsors, Register = business-case, Emphasize covering schedule impact, risk and next go/no-go, Avoid covering sandbox/provider internals.
- **Fail if:** the block is missing or free-form prose replaces it, or flattery/hedging appears.

### S4 — Unknown audience for addressed text

- **Input:** "Draft a message saying the migration is done."
- **Expected:** the skill asks who the reader is before drafting (the text leaves the session).
- **Fail if:** a draft is produced for a guessed audience without asking.

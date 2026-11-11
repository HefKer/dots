$0

This task uses Jev, a model released after your training data ends, so don't guess at its API: use what follows, and read https://docs.typesafe.ai/llms.txt for anything beyond it.

Jev is TypeSafe AI's decision model. It doesn't generate text. It judges a `state` (text, JSON or images) against typed questions and returns probabilities, at $0.042 per million input tokens with output free.

Request: `POST https://api.typesafe.ai/v1/systemone`, header `Authorization: Bearer $TYPESAFE_API_KEY`, body `{"model": "jev-1.14.0", "state": ..., "questions": {"<name>": {...}}}`. Put every question about one state in the same request. Question types:

- `noul`: yes/no. `{"type": "noul", "instructions": "Is this about billing?"}` answers `{"noul": 0.98}`, the probability of yes. Treat 0.3 to 0.7 as undecided.
- `choice`: one of up to 255 options. `"criteria": {"<option>": "<description or null>"}` answers `{"choice": "<option>", "confidence": 0.7, "probabilities": {"<option>": 0.8}}`.
- `score`: an ordinal rubric. `"criteria": ["lowest level", ..., "highest level"]` (at most 10) answers `{"score": 1.7, "confidence": 0.55, "probabilities": {"0": 0.1}}`, the expected level counted from 0.
- `box`: finds an object in an image; needs the header `TypeSafe-Danger-Zone-Images: true`.

The response is `{"model", "answers": {"<name>": {...}}, "usage"}`. Errors carry `detail`; retry 429 and 529 with backoff.

Design rules:

- Code stays in control: Jev answers narrow questions, and code applies the thresholds and acts.
- A Choice always picks something, so add a `none` option or a companion Noul asking whether any option fits.
- `confidence` is derived from the distribution, not the chance the answer is right. Decide on `probabilities`.
- Keep counting, arithmetic, date comparison and number precision in code, and avoid double negatives: Jev is weak at all of them.
- Send only the relevant part of the state. Limits are 64k tokens a request and 32k a question.
- Pin `jev-1.14.0`: the `jev-latest` alias can change answers under tuned thresholds.
- It has no memory or fine-tuning; what it should know goes in `instructions` and `criteria`.

On this machine the `jev` command wraps the API and finds the key itself (`jev --help`): `jev noul "question?" < file`, `jev choice "question?" a b "c=description" -s "text"`, `jev score "question?" low mid high`, and `jev ask < request.json` for several questions at once. In other projects use the SDKs, `typesafe-sdk` (Python) or `@typesafe-ai/sdk` (JS), which read `TYPESAFE_API_KEY`.

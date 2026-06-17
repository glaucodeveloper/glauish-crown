# Browser demo + stack/utils

Adds:

- `src/native/browser_host.nim`: reusable commandable BrowserHost.
- `src/native/crown_browser.nim`: BrowserHost pointed to `CROWN_URL`.
- `src/native/app_browser_demo.nim`: local demo server that imports `src/main.nim` and calls `runAppFromJson`.
- `src/stack/utils/jsonx.nim`: JSON/env helpers.
- `src/stack/utils/semantic.nim`: base semantic object abstraction.
- `src/stack/utils/bncc_semantics.nim`: semantic BNCC objects with methods.
- `src/main.nim`: replacement main using semantic BNCC types and real results path.

## Browser demo

```sh
nimble browserDemo
```

This starts:

- demo app server: `http://127.0.0.1:5061/`
- browser control server: `http://127.0.0.1:5127/`

The browser demo imports `../main` and uses:

```nim
runAppFromJson(params)
```

## Crown browser host

Run Crown first:

```sh
crown dev
```

Then:

```sh
CROWN_URL="http://127.0.0.1:5000/workspace" nimble crownBrowser
```

## Command navigation

```sh
curl -X POST http://127.0.0.1:5127/__browser/navigate \
  -H "Content-Type: application/json" \
  -d '{"url":"http://127.0.0.1:5000/workspace?tab=traces"}'
```

## Semantic classes

`SemanticEntity` provides methods:

```nim
method semanticType*(entity: SemanticEntity): string
method toJson*(entity: SemanticEntity): JsonNode
method toPrompt*(entity: SemanticEntity): string
method shortLabel*(entity: SemanticEntity): string
```

`bncc_semantics.nim` implements:

- `BnccSkill`
- `SkillComprehensions`
- `SkillConfig`
- `StudentProfile`

Each has semantic methods and JSON projection.

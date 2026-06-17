# Main as application target

This patch turns `src/main.nim` into the applied BNCC generation script:

- local domain models
- local module input types
- local prompts
- local pipeline
- imported reusable stack only:
  - `stack/rlm`
  - `stack/dspy`

Exports:

- `runAppFromJson*(params: JsonNode): JsonNode`
- `runApp*(input: AppStudyInput): JsonNode`
- `mainCli*()`

Crown target:

- `src/app/api/run/page.nim` imports `main` and calls `runAppFromJson`.

Native shell target:

- `src/native/happyx_native_shell.nim` imports `main` and calls `runAppFromJson`.

Commands:

```sh
nimble demo
nimble real
nimble repl
nimble shell
nimble nativeShell
```

Direct:

```sh
nim c -r --path:src src/main.nim
nim c -r --path:src src/main.nim --real
nim c -r --path:src src/native/happyx_native_shell.nim
```

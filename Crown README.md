# nim_crown_reactlike_dsl_20260617

Patch/mini pacote com DSL React-like para renderização em Crown.

Use os arquivos em um projeto Crown existente:

```text
src/stack/crown_reactish.nim
src/app/page.nim
src/app/workspace/page.nim
src/app/api/run.nim
public/reactish.js
public/workspace.js
public/workspace.css
```

A DSL Nim gera HTML server-side. O `reactish.js` cuida apenas de estado de UI frontend-only em islands.

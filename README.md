# nim_bncc_study_rlm_stack

Projeto deliberadamente **não modular no domínio**: o estudo BNCC, domain models, signatures e módulos DSPy-like ficam todos em `src/main.nim`.

A única stack reutilizável/importável é:

- `src/stack/rlm.nim`: RLM, workspace, tools, traces, model call OpenAI-compatible e REPL.
- `src/web/crown_adapter.nim`: helpers Crown-like para página/API.
- `src/web/crown_api_server.nim`: API local para chamar o estudo por HTTP.
- `src/native/happyx_native_shell.nim`: shell HappyX Native stub/importável, sem acoplar o main.
- `assets/www/reactish.js`: micro runtime frontend-only estilo React-like para páginas Crown.

## Rodar estudo com fake LLM

```sh
nimble demo
# ou
nim c -r --path:src src/main.nim
```

## Rodar com llama-server/OpenAI-compatible

```sh
curl http://127.0.0.1:1223/v1/models

OPENAI_BASE_URL="http://127.0.0.1:1223/v1" \
OPENAI_API_KEY="local" \
MODEL_NAME="google/gemma-4-e4b" \
nim c -r --path:src src/main.nim --real
```

## Rodar API Crown-like

```sh
nimble api
# GET  http://127.0.0.1:5050/
# GET  http://127.0.0.1:5050/assets/reactish.js
# POST http://127.0.0.1:5050/api/run
```

Teste:

```sh
curl -X POST http://127.0.0.1:5050/api/run \
  -H 'Content-Type: application/json' \
  -d '{"tema":"liberdade de expressão e discurso de ódio em comentários online","quantidade":2,"fake":true}'
```

## RLM REPL

```sh
nimble repl
```

## Saídas

```text
data/text_base.json
data/quiz.json
data/rewrite_report.txt
.rlm/traces.jsonl
.rlm/spans.jsonl
```

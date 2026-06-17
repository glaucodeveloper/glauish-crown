# llama-server verification

```sh
curl http://127.0.0.1:1223/v1/models
```

```sh
curl http://127.0.0.1:1223/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer local" \
  -d '{
    "model":"google/gemma-4-e4b",
    "messages":[{"role":"user","content":"Responda somente: ok"}],
    "temperature":0.2
  }'
```

Run study with real model:

```sh
OPENAI_BASE_URL=http://127.0.0.1:1223/v1 \
OPENAI_API_KEY=local \
MODEL_NAME=google/gemma-4-e4b \
nim c -r --path:src src/main.nim --real
```

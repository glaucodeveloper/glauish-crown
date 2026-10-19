# Glauish Crown

Stack experimental em Nim para estudar fluxos BNCC com agentes RLM, workspace, ferramentas, rastreamento e REPL.

## Componentes

- `src/main.nim`: estudo de domínio BNCC e fluxo principal.
- `src/stack/rlm.nim`: runtime RLM, workspace, tools, chamadas OpenAI-compatible, traces e REPL.
- `src/web/crown_adapter.nim` e `src/web/crown_api_server.nim`: adaptação e API HTTP local.
- `src/native/happyx_native_shell.nim`: experimento isolado de shell nativo.
- `public/`: interface web de demonstração.

O domínio BNCC permanece concentrado em `src/main.nim`; os módulos reutilizáveis ficam nas pastas `stack`, `web` e `native`.

## Executar

Com Nim e Nimble instalados:

```bash
nimble demo
```

Ou compile diretamente o programa principal:

```bash
nim c -r --path:src src/main.nim
```

O projeto aceita um LLM local ou outro endpoint OpenAI-compatible para os fluxos que chamam um modelo. O modo de demonstração sem modelo é o caminho mais simples para explorar a estrutura.

## Estado

Experimento de engenharia e domínio, não uma plataforma BNCC pronta para produção. As integrações de shell nativo e runtime frontend também são protótipos.

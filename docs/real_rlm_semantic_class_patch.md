# Real RLM + semantic class template patch

This patch removes the synthetic LLM branch from the application path.

## Changed

- `src/stack/dspy.nim`
  - `DspyContext` only stores the real `RLMApp`.
  - `predictJson` and `predictText` always call `ctx.app.callModel`.

- `src/main.nim`
  - `AppStudyInput` contains only business inputs.
  - removed synthetic payload functions.
  - removed mode switching in CLI.
  - pipeline uses real DSPy/RLM predictions for text base, questions, results analysis and rewrite report.

- `src/stack/utils/classx.nim`
  - adds `semanticClass` template for class-like semantic domain objects.

- `src/stack/utils/bncc_semantics.nim`
  - defines `BnccSkill`, `SkillComprehensions`, `SkillConfig`, and `StudentProfile` using `semanticClass`.
  - implements semantic methods such as `toJson`, `toPrompt`, and `shortLabel`.

- `src/native/app_browser_demo.nim`
  - browser demo imports `../main` and calls `runAppFromJson` without mode switching.

## Commands

```sh
nimble demo
nimble browserDemo
nimble checkMain
nimble checkSemanticClasses
```

With local OpenAI-compatible llama-server:

```sh
OPENAI_BASE_URL="http://127.0.0.1:1223/v1" \
OPENAI_API_KEY="local" \
MODEL_NAME="google/gemma-4-E4B-it" \
nimble demo
```

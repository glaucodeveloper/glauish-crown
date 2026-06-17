# Main without local entity object types

This patch removes BNCC entity declarations from `src/main.nim`.

`main.nim` now imports semantic/pipeline classes from:

- `src/stack/utils/classx.nim`
- `src/stack/utils/bncc_semantics.nim`
- `src/stack/utils/bncc_pipeline_types.nim`

The application main keeps only the applied flow:

1. instantiate semantic entities through constructors;
2. declare DSPy signatures/modules;
3. build prompts;
4. run the RLM pipeline;
5. expose `runAppFromJson*` for Crown/browser/native targets.

No FakeLLM mode remains in the main or nimble task descriptions.

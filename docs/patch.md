# Patch: classes declared in main

This patch keeps only the class/template utility in `stack/utils/classx.nim`.

The BNCC/application classes are declared directly inside `src/main.nim`:

- `BnccSkill`
- `SkillComprehensions`
- `SkillConfig`
- `StudentProfile`
- `GenerateTextBaseInput`
- `GenerateQuestionsInput`
- `GenerateResultsInput`
- `GenerateRewriteReportInput`
- `AppStudyInput`
- `AppStudyOutput`

`main.nim` imports:

```nim
import stack/utils/[classx, jsonx]
```

It does not import:

```nim
import stack/utils/[bncc_semantics, bncc_pipeline_types]
```

Those domain/pipeline class modules are intentionally not used by this patch.

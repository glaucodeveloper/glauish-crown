# Patch: main imperativo + global data sem OOP para fluxo

Este patch troca o desenho do `src/main.nim` para:

- manter `SmtModel` apenas para memória semântica/global data:
  - `BnccSkill`
  - `SkillComprehensions`
  - `SkillConfig`
  - `StudentProfile`
- remover classes de fluxo/execução:
  - `GenerateTextBaseInput`
  - `GenerateQuestionsInput`
  - `GenerateResultsInput`
  - `GenerateRewriteReportInput`
  - `AppStudyInput`
  - `AppStudyOutput`
- mover a execução para uma narrativa imperativa dentro de `runAppFromJson*`.

As partes do programa aparecem no próprio fluxo por nome:

```nim
block GenerateTextBase:
  ...

block GenerateQuestions:
  ...

block GenerateResults:
  ...

block GenerateRewriteReport:
  ...
```

Aplicar:

```sh
unzip blueish_main_imperative_globaldata_patch_20260617.zip -d .
cp -r blueish_main_imperative_globaldata_patch_20260617/* .
```

Verificar:

```sh
grep -n "SmtModel Generate\|SmtModel AppStudy\|proc build\|proc forward\|proc runStudy\|proc runApp\|proc printSummary" src/main.nim
nimble checkMain
nimble demo
```

O grep acima não deve retornar classes/procs de fluxo antigos.

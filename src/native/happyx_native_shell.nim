# Optional native shell target.
# The shell calls the application main target directly for now.
# Later this file can open a WebView pointed to Crown /workspace.

when defined(useHappyXNative):
  import happyx_native

import std/json
import ../main

proc runShell*() =
  echo "=== HappyX Native shell target ==="
  echo "This shell currently calls main.runAppFromJson directly."
  echo "Later: open WebView -> Crown /workspace -> /api/run."
  echo ""

  let outJson = runAppFromJson(%*{
    "tema": "liberdade de expressão e discurso de ódio em comentários online",
    "quantidade": 2,
    "observacao_geral": "execução chamada pelo shell nativo",
    "fake": true
  })

  printSummary(outJson, "fake LLM via native shell")

when isMainModule:
  runShell()

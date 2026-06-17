version       = "0.1.0"
author        = "Ícaro"
description   = "Nim RLM/DSPy stack with Crown file-as-page target and optional HappyX Native shell."
license       = "MIT"
srcDir        = "src"

requires "nim >= 2.0.0"

task demo, "Run application main with fake deterministic LLM":
  exec "nim c -r --path:src src/main.nim"

task real, "Run application main with real OpenAI-compatible LLM":
  exec "nim c -r --path:src src/main.nim --real"

task repl, "Run RLM REPL through application main":
  exec "nim c -r --path:src src/main.nim --repl"

task shell, "Run optional native shell target":
  exec "nim c -r --path:src src/main.nim --shell"

task nativeShell, "Run native shell file directly":
  exec "nim c -r --path:src src/native/happyx_native_shell.nim"

task nativeShellHappyX, "Run native shell file with happyx-native import enabled":
  exec "nim c -r -d:useHappyXNative --path:src src/native/happyx_native_shell.nim"

task checkMain, "Check app main":
  exec "nim check --path:src src/main.nim"

task checkShell, "Check native shell":
  exec "nim check --path:src src/native/happyx_native_shell.nim"

task crownHint, "Show Crown file-as-page target":
  echo "Crown target files:"
  echo "  src/app/workspace/page.nim"
  echo "  src/app/api/run/page.nim"
  echo "Run with Crown's CLI/dev command in this project root."

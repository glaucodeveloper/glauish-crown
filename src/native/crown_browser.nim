## src/native/crown_browser.nim
## Opens whatever Crown is serving, using the generic BrowserHost.

import std/os
import ./browser_shell.nim

proc newCrownBrowser*(): BrowserHost =
  newBrowserHost(
    title = getEnv("CROWN_BROWSER_TITLE", "Crown Workspace"),
    initialUrl = getEnv("CROWN_URL", "http://127.0.0.1:5000/workspace")
  )

when isMainModule:
  let browser = newCrownBrowser()
  browser.open()

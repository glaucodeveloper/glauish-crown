import std/[
  asynchttpserver,
  asyncdispatch,
  browsers,
  json,
  os,
  strformat,
  strutils,
  uri
]

when defined(useHappyXNative):
  import happyx_native

type
  BrowserHost* = ref object
    title*: string
    currentUrl*: string
    controlHost*: string
    controlPort*: int
    nativePort*: int
    width*: int
    height*: int
    openAsWebview*: bool
    openExternalBrowser*: bool

proc newBrowserHost*(
  title = getEnv("BROWSER_TITLE", "Crown Workspace");
  initialUrl = getEnv("CROWN_URL", "http://127.0.0.1:5000/workspace");
  controlHost = getEnv("BROWSER_CONTROL_HOST", "127.0.0.1");
  controlPort = parseInt(getEnv("BROWSER_CONTROL_PORT", "5127"));
  nativePort = parseInt(getEnv("HAPPYX_NATIVE_PORT", "5128"));
  width = parseInt(getEnv("BROWSER_WIDTH", "1280"));
  height = parseInt(getEnv("BROWSER_HEIGHT", "820"));
  openAsWebview = getEnv("BROWSER_WEBVIEW", "1") != "0";
  openExternalBrowser = getEnv("BROWSER_EXTERNAL", "0") == "1"
): BrowserHost =
  BrowserHost(
    title: title,
    currentUrl: initialUrl,
    controlHost: controlHost,
    controlPort: controlPort,
    nativePort: nativePort,
    width: width,
    height: height,
    openAsWebview: openAsWebview,
    openExternalBrowser: openExternalBrowser
  )


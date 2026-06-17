## crown_reactish.nim
## Small React-like rendering DSL for Crown pages.
##
## Purpose:
## - server-side render HTML strings in Crown page.nim files;
## - define reusable server components with componentDef;
## - mount frontend-only islands using public/reactish.js;
## - keep RLM/pipeline/API logic outside the page renderer.

import std/[json, strutils]

# ============================================================
# CORE TYPES
# ============================================================

type
  Attr* = object
    key*: string
    value*: string
    enabled*: bool

  RxRender* = ref object
    buf*: string
    pretty*: bool
    indent*: int

  RxComponent* = proc(rx: RxRender; props: JsonNode)

proc newRxRender*(pretty = false): RxRender =
  RxRender(buf: "", pretty: pretty, indent: 0)

# ============================================================
# ESCAPING / ATTRIBUTES
# ============================================================

proc escapeHtml*(s: string): string =
  result = s
  result = result.replace("&", "&amp;")
  result = result.replace("<", "&lt;")
  result = result.replace(">", "&gt;")
  result = result.replace("\"", "&quot;")
  result = result.replace("'", "&#39;")

proc escapeAttr*(s: string): string = escapeHtml(s)

proc a*(key, value: string): Attr =
  Attr(key: key, value: value, enabled: true)

proc flag*(key: string; enabled = true): Attr =
  Attr(key: key, value: "", enabled: enabled)

proc cls*(value: string): Attr = a("class", value)
proc id*(value: string): Attr = a("id", value)
proc typ*(value: string): Attr = a("type", value)
proc href*(value: string): Attr = a("href", value)
proc src*(value: string): Attr = a("src", value)
proc value*(value: string): Attr = a("value", value)
proc name*(value: string): Attr = a("name", value)
proc placeholder*(value: string): Attr = a("placeholder", value)
proc data*(key, value: string): Attr = a("data-" & key, value)
proc aria*(key, value: string): Attr = a("aria-" & key, value)

# Frontend-only Reactish events.
proc onClick*(action: string): Attr = data("rx-click", action)
proc onInput*(action: string): Attr = data("rx-input", action)
proc onSubmit*(action: string): Attr = data("rx-submit", action)
proc bindValue*(key: string): Attr = data("rx-bind", key)

# Crown / hypermedia style attributes.
# These are plain attrs; Crown/client can decide what to do with them.
proc crownGet*(url: string): Attr = a("crown-get", url)
proc crownPost*(url: string): Attr = a("crown-post", url)
proc crownTarget*(selector: string): Attr = a("crown-target", selector)
proc crownSwap*(mode: string): Attr = a("crown-swap", mode)

proc prop*(props: JsonNode; key: string; default = ""): string =
  if props.kind == JObject and props.hasKey(key) and props[key].kind != JNull:
    props[key].getStr(default)
  else:
    default

proc propInt*(props: JsonNode; key: string; default = 0): int =
  if props.kind == JObject and props.hasKey(key) and props[key].kind != JNull:
    props[key].getInt(default)
  else:
    default

proc propBool*(props: JsonNode; key: string; default = false): bool =
  if props.kind == JObject and props.hasKey(key) and props[key].kind != JNull:
    props[key].getBool(default)
  else:
    default

# ============================================================
# LOW LEVEL RENDERING
# ============================================================

proc newline(rx: RxRender) =
  if rx.pretty:
    rx.buf.add("\n")
    rx.buf.add(repeat("  ", rx.indent))

proc renderAttrs(attrs: openArray[Attr]): string =
  for attr in attrs:
    if not attr.enabled:
      continue

    if attr.value.len == 0:
      result.add(" " & attr.key)
    else:
      result.add(" " & attr.key & "=\"" & escapeAttr(attr.value) & "\"")

proc openTag*(rx: RxRender; tagName: string; attrs: openArray[Attr]) =
  rx.newline()
  rx.buf.add("<" & tagName & renderAttrs(attrs) & ">")
  inc rx.indent

proc closeTag*(rx: RxRender; tagName: string) =
  dec rx.indent
  rx.newline()
  rx.buf.add("</" & tagName & ">")

proc voidTag*(rx: RxRender; tagName: string; attrs: openArray[Attr]) =
  rx.newline()
  rx.buf.add("<" & tagName & renderAttrs(attrs) & ">")

proc addText*(rx: RxRender; s: string) =
  rx.buf.add(escapeHtml(s))

proc addRaw*(rx: RxRender; s: string) =
  rx.buf.add(s)

proc addScriptSrc*(
  rx: RxRender;
  path: string;
  deferLoad = true;
  moduleScript = false
) =
  var attrs: seq[Attr] = @[src(path)]

  if deferLoad:
    attrs.add(flag("defer"))

  if moduleScript:
    attrs.add(a("type", "module"))

  rx.openTag("script", attrs)
  rx.closeTag("script")

proc addStyleSrc*(rx: RxRender; path: string) =
  rx.voidTag("link", @[a("rel", "stylesheet"), href(path)])

proc addJsonScript*(rx: RxRender; scriptId: string; node: JsonNode) =
  rx.openTag("script", @[id(scriptId), typ("application/json")])
  rx.addRaw($node)
  rx.closeTag("script")

# ============================================================
# DSL ENTRYPOINT
# ============================================================

template rxPage*(body: untyped): string =
  block:
    var rx {.inject.} = newRxRender(false)
    body
    rx.buf

template rxPrettyPage*(body: untyped): string =
  block:
    var rx {.inject.} = newRxRender(true)
    body
    rx.buf

# ============================================================
# TEXT / RAW / COMPONENTS
# ============================================================

template text*(s: string) =
  addText(rx, s)

template raw*(s: string) =
  addRaw(rx, s)

template componentDef*(componentName: untyped; body: untyped) =
  proc componentName*(rx: RxRender; props: JsonNode) =
    body

template component*(componentName: untyped; props: JsonNode) =
  componentName(rx, props)

template component*(componentName: untyped) =
  componentName(rx, newJObject())

# ============================================================
# TAG TEMPLATES
# ============================================================

template tag*(tagName: static[string]; attrs: varargs[Attr]; body: untyped) =
  openTag(rx, tagName, attrs)
  body
  closeTag(rx, tagName)

template html*(attrs: varargs[Attr]; body: untyped) =
  tag("html", attrs): body

template head*(attrs: varargs[Attr]; body: untyped) =
  tag("head", attrs): body

template body*(attrs: varargs[Attr]; body: untyped) =
  tag("body", attrs): body

template main*(attrs: varargs[Attr]; body: untyped) =
  tag("main", attrs): body

template section*(attrs: varargs[Attr]; body: untyped) =
  tag("section", attrs): body

template box*(attrs: varargs[Attr]; body: untyped) =
  tag("div", attrs):
    body

template form*(attrs: varargs[Attr]; body: untyped) =
  tag("form", attrs): body

template label*(attrs: varargs[Attr]; body: untyped) =
  tag("label", attrs): body

template button*(attrs: varargs[Attr]; body: untyped) =
  tag("button", attrs): body

template textarea*(attrs: varargs[Attr]; body: untyped) =
  tag("textarea", attrs): body

template pre*(attrs: varargs[Attr]; body: untyped) =
  tag("pre", attrs): body

template code*(attrs: varargs[Attr]; body: untyped) =
  tag("code", attrs): body

template span*(attrs: varargs[Attr]; body: untyped) =
  tag("span", attrs): body

template p*(attrs: varargs[Attr]; body: untyped) =
  tag("p", attrs): body

template h1*(attrs: varargs[Attr]; body: untyped) =
  tag("h1", attrs): body

template h2*(attrs: varargs[Attr]; body: untyped) =
  tag("h2", attrs): body

template h3*(attrs: varargs[Attr]; body: untyped) =
  tag("h3", attrs): body

template ul*(attrs: varargs[Attr]; body: untyped) =
  tag("ul", attrs): body

template li*(attrs: varargs[Attr]; body: untyped) =
  tag("li", attrs): body

template nav*(attrs: varargs[Attr]; body: untyped) =
  tag("nav", attrs): body

template article*(attrs: varargs[Attr]; body: untyped) =
  tag("article", attrs): body

template header*(attrs: varargs[Attr]; body: untyped) =
  tag("header", attrs): body

template footer*(attrs: varargs[Attr]; body: untyped) =
  tag("footer", attrs): body

# Void tags.
template input*(attrs: varargs[Attr]) =
  voidTag(rx, "input", attrs)

template meta*(attrs: varargs[Attr]) =
  voidTag(rx, "meta", attrs)

template link*(attrs: varargs[Attr]) =
  voidTag(rx, "link", attrs)

template br*() =
  voidTag(rx, "br", [])

# Convenience document helpers.
template doctype*() =
  raw("<!doctype html>")

template scriptSrc*(path: string) =
  addScriptSrc(rx, path, defer = true)

template moduleScriptSrc*(path: string) =
  addScriptSrc(rx, path, defer = true, module = true)

template styleSrc*(path: string) =
  addStyleSrc(rx, path)

# ============================================================
# REACTISH ISLANDS
# ============================================================

proc islandOpen*(rx: RxRender; rootId, componentName, className: string; state: JsonNode) =
  rx.openTag("section", @[
    id(rootId),
    cls(className),
    data("rx-root", rootId),
    data("rx-component", componentName),
    data("rx-state", rootId & "__state")
  ])
  rx.addJsonScript(rootId & "__state", state)

# Server-render fallback + client hydration target.
template island*(rootId, componentName, className: string; state: JsonNode; body: untyped) =
  islandOpen(rx, rootId, componentName, className, state)
  body
  closeTag(rx, "section")

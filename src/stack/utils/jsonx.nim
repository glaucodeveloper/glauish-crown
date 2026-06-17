## jsonx.nim
## Small JSON/env helpers shared by applied scripts.

import std/[json, os, strutils]

proc arr*(items: seq[string]): JsonNode =
  result = newJArray()
  for item in items:
    result.add(newJString(item))

proc put*(node: JsonNode; key, value: string) =
  node[key] = newJString(value)

proc pickStr*(node: JsonNode; keys: varargs[string]): string =
  for key in keys:
    if node.kind == JObject and node.hasKey(key) and node[key].kind != JNull:
      let value = node[key].getStr("")
      if value.len > 0:
        return value
  ""

proc pickObj*(node: JsonNode; keys: varargs[string]): JsonNode =
  for key in keys:
    if node.kind == JObject and node.hasKey(key) and node[key].kind == JObject:
      return node[key]
  newJObject()

proc pickArr*(node: JsonNode; keys: varargs[string]): JsonNode =
  for key in keys:
    if node.kind == JObject and node.hasKey(key) and node[key].kind == JArray:
      return node[key]
  newJArray()

proc jstr*(node: JsonNode; key: string; default = ""): string =
  if node.kind == JObject and node.hasKey(key) and node[key].kind != JNull:
    node[key].getStr(default)
  else:
    default

proc jint*(node: JsonNode; key: string; default = 0): int =
  if node.kind == JObject and node.hasKey(key) and node[key].kind != JNull:
    case node[key].kind
    of JInt:
      node[key].getInt(default)
    of JString:
      try:
        parseInt(node[key].getStr($default))
      except CatchableError:
        default
    else:
      default
  else:
    default

proc jbool*(node: JsonNode; key: string; default = false): bool =
  if node.kind == JObject and node.hasKey(key) and node[key].kind != JNull:
    case node[key].kind
    of JBool:
      node[key].getBool(default)
    of JString:
      let s = node[key].getStr("").normalize()
      s in ["1", "true", "yes", "sim", "real"]
    else:
      default
  else:
    default

proc pickJson*(node: JsonNode; keys: varargs[string]): JsonNode =
  if node.kind != JObject:
    return newJNull()
  for key in keys:
    if node.hasKey(key):
      return node[key]
  newJNull()

proc jsonFromEnvOrDefault*(envName: string; default: JsonNode): JsonNode =
  let raw = getEnv(envName, "")
  if raw.strip.len == 0:
    return default
  try:
    parseJson(raw)
  except CatchableError:
    default

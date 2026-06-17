## classx.nim
## Small semantic Class macro.
##
## Goal:
## - allow declaring entity/data classes in the application file;
## - keep fields and methods together inside one Class block;
## - avoid writing raw `type Foo = object` in main.nim.
##
## Syntax:
##
##   Class BnccSkill:
##     fields:
##       codigo string
##       etapa string
##       fontePdfPagina int
##
##     methods:
##       proc newBnccSkill*(codigo, etapa: string; fontePdfPagina: int): BnccSkill =
##         BnccSkill(codigo: codigo, etapa: etapa, fontePdfPagina: fontePdfPagina)
##
##       proc toJson*(self: BnccSkill): JsonNode =
##         ...

import std/[macros, strutils]

proc isSection(node: NimNode; name: string): bool =
  if node.kind notin {nnkCall, nnkCommand}:
    return false
  if node.len == 0:
    return false
  node[0].eqIdent(name)

proc sectionBody(node: NimNode): NimNode =
  if node.len > 1 and node[^1].kind == nnkStmtList:
    node[^1]
  else:
    newStmtList()

proc exportedName(name: string): string =
  if name.endsWith("*"):
    name
  else:
    name & "*"

proc parseFieldLine(node: NimNode): tuple[name: string, typ: string] =
  ## Supported field syntax inside `fields:`:
  ##   codigo string
  ##   quantidade int
  ##   studentAnswers JsonNode
  ##   funcionamento seq[string]
  ##
  ## Also accepts a limited ident-def style if Nim parses it that way.
  case node.kind
  of nnkCommand, nnkCall:
    if node.len < 2:
      error("Class field must be declared as: fieldName FieldType", node)
    result.name = node[0].repr
    result.typ = node[1].repr
  of nnkIdentDefs:
    if node.len < 2:
      error("Invalid Class field declaration.", node)
    result.name = node[0].repr.replace("*", "")
    result.typ = node[1].repr
  else:
    error("Class field must be declared as: fieldName FieldType", node)

proc buildClassImpl(className: NimNode; body: NimNode): NimNode =
  let classNameRaw = className.repr
  var fields: seq[tuple[name: string, typ: string]] = @[]
  var methods = newStmtList()

  for item in body:
    if item.isSection("fields"):
      for f in item.sectionBody:
        fields.add(parseFieldLine(f))
    elif item.isSection("methods"):
      for m in item.sectionBody:
        methods.add(m)
    else:
      ## Allow direct method/proc declarations when the `methods:` wrapper is omitted.
      methods.add(item)

  if fields.len == 0:
    error("Class " & classNameRaw & " requires a fields: section with at least one field.", body)

  var src = "type\n"
  src.add("  " & exportedName(classNameRaw) & " = ref object\n")

  for f in fields:
    src.add("    " & exportedName(f.name) & ": " & f.typ & "\n")

  result = newStmtList()
  let typeAst = parseStmt(src)
  for stmt in typeAst:
    result.add(stmt)
  for stmt in methods:
    result.add(stmt)

macro SmtModel*(className: untyped; body: untyped): untyped =
  buildClassImpl(className, body)

macro SemanticClass*(className: untyped; body: untyped): untyped =
  buildClassImpl(className, body)

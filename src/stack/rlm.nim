import std/[os, times, json, strutils, strformat, tables, random, httpclient]

type
  RLMConfig* = object
    project*: string
    traceDir*: string
    openaiBaseUrl*: string
    openaiKey*: string
    modelName*: string
    temperature*: float
    promptPricePer1M*: float
    completionPricePer1M*: float

  RLMContext* = ref object
    vars*: Table[string, string]
    docs*: Table[string, string]
    events*: seq[JsonNode]

  RLMToolProc* = proc(ctx: RLMContext; args: JsonNode): string {.closure.}

  RLMTool* = object
    name*: string
    description*: string
    schema*: JsonNode
    run*: RLMToolProc

  RLMApp* = ref object
    config*: RLMConfig
    ctx*: RLMContext
    tools*: Table[string, RLMTool]

    traceId: string
    traceName: string
    traceStart: float
    traceStartedAt: string
    traceInput: JsonNode
    stack: seq[string]
    spanStarts: Table[string, float]
    spanNames: Table[string, string]
    spanTypes: Table[string, string]
    spanParents: Table[string, string]
    spanInputs: Table[string, JsonNode]

    modelCalls: int
    toolCalls: int
    promptTokens: int
    completionTokens: int
    totalTokens: int
    estimatedCost: float

  ModelResult* = object
    content*: string
    promptTokens*: int
    completionTokens*: int
    totalTokens*: int
    estimatedCost*: float
    finishReason*: string

proc newRLMConfig*(): RLMConfig =
  RLMConfig(
    project: getEnv("RLM_PROJECT", "bncc-study-rlm"),
    traceDir: getEnv("RLM_TRACE_DIR", ".rlm"),
    openaiBaseUrl: getEnv("OPENAI_BASE_URL", "http://127.0.0.1:1223/v1"),
    openaiKey: getEnv("OPENAI_API_KEY", "local"),
    modelName: getEnv("MODEL_NAME", "google/gemma-4-e4b"),
    temperature: parseFloat(getEnv("TEMPERATURE", "0.2")),
    promptPricePer1M: parseFloat(getEnv("PROMPT_PRICE_PER_1M", "0")),
    completionPricePer1M: parseFloat(getEnv("COMPLETION_PRICE_PER_1M", "0"))
  )

proc newRLMContext*(): RLMContext =
  RLMContext(
    vars: initTable[string, string](),
    docs: initTable[string, string](),
    events: @[]
  )

proc newRLM*(config = newRLMConfig()): RLMApp =
  randomize()
  createDir(config.traceDir)
  RLMApp(
    config: config,
    ctx: newRLMContext(),
    tools: initTable[string, RLMTool](),
    stack: @[],
    spanStarts: initTable[string, float](),
    spanNames: initTable[string, string](),
    spanTypes: initTable[string, string](),
    spanParents: initTable[string, string](),
    spanInputs: initTable[string, JsonNode]()
  )

proc registerTool*(app: RLMApp; tool: RLMTool) =
  app.tools[tool.name] = tool

proc setVar*(ctx: RLMContext; key, value: string) =
  ctx.vars[key] = value

proc getVar*(ctx: RLMContext; key: string; default = ""): string =
  if ctx.vars.hasKey(key): ctx.vars[key] else: default

proc addDoc*(ctx: RLMContext; name, content: string) =
  ctx.docs[name] = content

proc getDoc*(ctx: RLMContext; name: string; default = ""): string =
  if ctx.docs.hasKey(name): ctx.docs[name] else: default

proc nowIso*(): string =
  $now()

proc makeId(prefix: string): string =
  fmt"{prefix}_{epochTime().int}_{rand(1_000_000_000)}"

proc short*(s: string; maxLen = 1800): string =
  if s.len <= maxLen: s else: s[0 ..< maxLen] & "\n...[truncated]"

proc appendJsonLine*(path: string; node: JsonNode) =
  createDir(parentDir(path))
  var file = open(path, fmAppend)
  defer: file.close()
  file.writeLine($node)

proc normalizeBaseUrl*(url: string): string =
  result = url.strip()
  while result.endsWith("/"):
    result.setLen(result.len - 1)

proc estimateTokens*(text: string): int =
  max(1, text.len div 4)

proc parseJsonLoose*(text: string): JsonNode =
  var x = text.strip()

  if x.startsWith("```"):
    var lines = x.splitLines()
    if lines.len > 0 and lines[0].startsWith("```"):
      lines = lines[1 .. ^1]
    if lines.len > 0 and lines[^1].startsWith("```"):
      lines.setLen(lines.len - 1)
    x = lines.join("\n").strip()

  try:
    return parseJson(x)
  except CatchableError:
    discard

  let objectStart = x.find("{")
  let objectEnd = x.rfind("}")
  if objectStart >= 0 and objectEnd > objectStart:
    return parseJson(x[objectStart .. objectEnd])

  let arrayStart = x.find("[")
  let arrayEnd = x.rfind("]")
  if arrayStart >= 0 and arrayEnd > arrayStart:
    return parseJson(x[arrayStart .. arrayEnd])

  raise newException(ValueError, "JSON inválido.")

proc jstr*(node: JsonNode; key: string; default = ""): string =
  if node.kind == JObject and node.hasKey(key) and node[key].kind != JNull:
    node[key].getStr(default)
  else:
    default

proc jint*(node: JsonNode; key: string; default = 0): int =
  if node.kind == JObject and node.hasKey(key) and node[key].kind != JNull:
    node[key].getInt(default)
  else:
    default

proc jbool*(node: JsonNode; key: string; default = false): bool =
  if node.kind == JObject and node.hasKey(key) and node[key].kind != JNull:
    node[key].getBool(default)
  else:
    default

proc jobj*(node: JsonNode; key: string): JsonNode =
  if node.kind == JObject and node.hasKey(key) and node[key].kind == JObject:
    node[key]
  else:
    newJObject()

proc jarr*(node: JsonNode; key: string): JsonNode =
  if node.kind == JObject and node.hasKey(key) and node[key].kind == JArray:
    node[key]
  else:
    newJArray()

proc toolsAsText*(app: RLMApp): string =
  var lines: seq[string] = @[]
  for name, tool in pairs(app.tools):
    lines.add(fmt"""
Tool: {name}
Descrição: {tool.description}
Schema: {$tool.schema}
""")
  lines.join("\n")

proc workspaceAsText*(app: RLMApp): string =
  var lines: seq[string] = @[]
  lines.add("VARS:")
  for key, value in pairs(app.ctx.vars):
    lines.add("- " & key & ": " & short(value, 500))
  lines.add("")
  lines.add("DOCS:")
  for key, value in pairs(app.ctx.docs):
    lines.add("- " & key & ": " & $value.len & " chars")
  lines.join("\n")

proc startTrace*(app: RLMApp; name: string; input: JsonNode) =
  app.traceId = makeId("trc")
  app.traceName = name
  app.traceStart = epochTime()
  app.traceStartedAt = nowIso()
  app.traceInput = input

  app.stack = @[]
  app.spanStarts.clear()
  app.spanNames.clear()
  app.spanTypes.clear()
  app.spanParents.clear()
  app.spanInputs.clear()

  app.modelCalls = 0
  app.toolCalls = 0
  app.promptTokens = 0
  app.completionTokens = 0
  app.totalTokens = 0
  app.estimatedCost = 0

proc endTrace*(app: RLMApp; output: JsonNode; status = "ok"; error = "") =
  appendJsonLine(
    app.config.traceDir / "traces.jsonl",
    %*{
      "trace_id": app.traceId,
      "project": app.config.project,
      "name": app.traceName,
      "status": status,
      "error": error,
      "started_at": app.traceStartedAt,
      "ended_at": nowIso(),
      "duration_ms": int((epochTime() - app.traceStart) * 1000),
      "input": app.traceInput,
      "output": output,
      "metrics": {
        "model_calls": app.modelCalls,
        "tool_calls": app.toolCalls,
        "prompt_tokens": app.promptTokens,
        "completion_tokens": app.completionTokens,
        "total_tokens": app.totalTokens,
        "estimated_cost": app.estimatedCost
      },
      "metadata": {
        "model": app.config.modelName,
        "base_url": app.config.openaiBaseUrl
      }
    }
  )

proc startSpan*(app: RLMApp; name, runType: string; input: JsonNode): string =
  let spanId = makeId("spn")
  let parentId = if app.stack.len == 0: "" else: app.stack[^1]
  app.stack.add(spanId)
  app.spanStarts[spanId] = epochTime()
  app.spanNames[spanId] = name
  app.spanTypes[spanId] = runType
  app.spanParents[spanId] = parentId
  app.spanInputs[spanId] = input
  spanId

proc endSpan*(
  app: RLMApp;
  spanId: string;
  output: JsonNode;
  status = "ok";
  error = "";
  metadata: JsonNode = newJObject()
) =
  if not app.spanStarts.hasKey(spanId):
    return

  while app.stack.len > 0:
    let current = app.stack.pop()
    if current == spanId:
      break

  appendJsonLine(
    app.config.traceDir / "spans.jsonl",
    %*{
      "trace_id": app.traceId,
      "span_id": spanId,
      "parent_id": app.spanParents[spanId],
      "name": app.spanNames[spanId],
      "type": app.spanTypes[spanId],
      "status": status,
      "error": error,
      "duration_ms": int((epochTime() - app.spanStarts[spanId]) * 1000),
      "input": app.spanInputs[spanId],
      "output": output,
      "metadata": metadata
    }
  )

  app.spanStarts.del(spanId)
  app.spanNames.del(spanId)
  app.spanTypes.del(spanId)
  app.spanParents.del(spanId)
  app.spanInputs.del(spanId)

proc callModel*(app: RLMApp; prompt: string; system = "Você é um motor RLM. Planeje e sintetize sem inventar dados."): ModelResult =
  let spanId = app.startSpan(
    "rlm.call_model",
    "llm",
    %*{
      "model": app.config.modelName,
      "prompt_preview": short(prompt)
    }
  )

  try:
    let endpoint = normalizeBaseUrl(app.config.openaiBaseUrl) & "/chat/completions"
    let payload = %*{
      "model": app.config.modelName,
      "messages": [
        {"role": "system", "content": system},
        {"role": "user", "content": prompt}
      ],
      "temperature": app.config.temperature
    }

    var client = newHttpClient(timeout = 600_000)
    defer: client.close()
    client.headers = newHttpHeaders({
      "Content-Type": "application/json",
      "Authorization": "Bearer " & app.config.openaiKey
    })

    let responseBody = client.postContent(endpoint, $payload)
    let parsed = parseJson(responseBody)
    let content = parsed["choices"][0]["message"]["content"].getStr("")

    let finishReason =
      if parsed["choices"][0].hasKey("finish_reason"):
        parsed["choices"][0]["finish_reason"].getStr("")
      else:
        ""

    var promptTokens = 0
    var completionTokens = 0
    var totalTokens = 0

    if parsed.hasKey("usage"):
      let usage = parsed["usage"]
      if usage.hasKey("prompt_tokens"): promptTokens = usage["prompt_tokens"].getInt()
      if usage.hasKey("completion_tokens"): completionTokens = usage["completion_tokens"].getInt()
      if usage.hasKey("total_tokens"): totalTokens = usage["total_tokens"].getInt()

    if totalTokens == 0:
      promptTokens = estimateTokens(prompt)
      completionTokens = estimateTokens(content)
      totalTokens = promptTokens + completionTokens

    let estimatedCost =
      (promptTokens.float / 1_000_000.0) * app.config.promptPricePer1M +
      (completionTokens.float / 1_000_000.0) * app.config.completionPricePer1M

    app.modelCalls += 1
    app.promptTokens += promptTokens
    app.completionTokens += completionTokens
    app.totalTokens += totalTokens
    app.estimatedCost += estimatedCost

    result = ModelResult(
      content: content,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
      estimatedCost: estimatedCost,
      finishReason: finishReason
    )

    app.endSpan(
      spanId,
      %*{
        "content_preview": short(content),
        "prompt_tokens": promptTokens,
        "completion_tokens": completionTokens,
        "total_tokens": totalTokens,
        "estimated_cost": estimatedCost,
        "finish_reason": finishReason
      },
      metadata = %*{"model": app.config.modelName}
    )

  except CatchableError as e:
    app.endSpan(spanId, %*{}, status = "error", error = e.msg)
    raise

proc registerDefaultTools*(app: RLMApp) =
  app.registerTool(RLMTool(
    name: "grep_context",
    description: "Procura texto em docs carregados no workspace RLM.",
    schema: %*{"type": "object", "properties": {"query": {"type": "string"}}},
    run: proc(ctx: RLMContext; args: JsonNode): string =
      let query = jstr(args, "query").toLowerAscii()
      var lines: seq[string] = @[]
      for name, content in pairs(ctx.docs):
        if query.len == 0 or content.toLowerAscii().contains(query):
          lines.add("DOC " & name & ":\n" & short(content, 1200))
      if lines.len == 0: "" else: lines.join("\n\n")
  ))

  app.registerTool(RLMTool(
    name: "read_file",
    description: "Lê arquivo local e salva no workspace como doc.",
    schema: %*{"type": "object", "properties": {"path": {"type": "string"}, "name": {"type": "string"}}},
    run: proc(ctx: RLMContext; args: JsonNode): string =
      let path = jstr(args, "path")
      let name = jstr(args, "name", path)
      if path.len == 0: raise newException(ValueError, "path ausente.")
      if not fileExists(path): raise newException(IOError, "Arquivo não encontrado: " & path)
      let content = readFile(path)
      ctx.docs[name] = content
      content
  ))

  app.registerTool(RLMTool(
    name: "save_var",
    description: "Salva variável textual no workspace RLM.",
    schema: %*{"type": "object", "properties": {"key": {"type": "string"}, "value": {"type": "string"}}},
    run: proc(ctx: RLMContext; args: JsonNode): string =
      let key = jstr(args, "key")
      let value = jstr(args, "value")
      if key.len == 0: raise newException(ValueError, "key ausente.")
      ctx.vars[key] = value
      value
  ))

proc planCommands*(app: RLMApp; task: string): JsonNode =
  let spanId = app.startSpan("rlm.plan_commands", "chain", %*{"task": short(task), "tools_count": app.tools.len})
  try:
    let raw = callModel(app, fmt"""
Você está dentro de um RLM com workspace mutável e tools.

Tarefa:
{task}

Workspace atual:
{workspaceAsText(app)}

Tools disponíveis:
{toolsAsText(app)}

Crie plano JSON no formato:
[
  {{"tool":"nome_da_tool","args":{{}},"save_as":"nome_da_variavel","reason":"motivo curto"}}
]

Use apenas tools listadas. Retorne somente JSON válido.
""").content

    try:
      result = parseJsonLoose(raw)
      if result.kind != JArray: raise newException(ValueError, "Plano não é array.")
    except CatchableError:
      result = newJArray()
      if app.tools.hasKey("grep_context"):
        result.add(%*{"tool":"grep_context","args":{"query":task},"save_as":"retrieved","reason":"recuperar contexto relevante"})

    app.endSpan(spanId, %*{"plan": result})
  except CatchableError as e:
    app.endSpan(spanId, %*{}, status = "error", error = e.msg)
    raise

proc executeCommands*(app: RLMApp; commands: JsonNode) =
  let spanId = app.startSpan("rlm.execute_commands", "chain", %*{"commands": commands})
  try:
    if commands.kind != JArray:
      app.endSpan(spanId, %*{"ignored": "commands não era array"})
      return

    for command in commands.items:
      let toolName = jstr(command, "tool")
      let args = jobj(command, "args")
      let saveAs = jstr(command, "save_as")
      let reason = jstr(command, "reason")
      let toolSpan = app.startSpan("rlm.tool." & toolName, "tool", %*{"tool": toolName, "args": args, "save_as": saveAs, "reason": reason})
      app.toolCalls += 1

      if not app.tools.hasKey(toolName):
        let msg = "Tool não registrada: " & toolName
        app.ctx.events.add(%*{"tool": toolName, "status": "missing", "message": msg})
        app.endSpan(toolSpan, %*{"error": msg}, status = "error", error = msg)
        continue

      try:
        let output = app.tools[toolName].run(app.ctx, args)
        if saveAs.len > 0: app.ctx.vars[saveAs] = output
        app.ctx.events.add(%*{"tool": toolName, "status": "ok", "save_as": saveAs, "output_preview": short(output, 500)})
        app.endSpan(toolSpan, %*{"output_preview": short(output), "saved_as": saveAs})
      except CatchableError as e:
        app.ctx.events.add(%*{"tool": toolName, "status": "error", "error": e.msg})
        app.endSpan(toolSpan, %*{}, status = "error", error = e.msg)

    app.endSpan(spanId, %*{"events_count": app.ctx.events.len})
  except CatchableError as e:
    app.endSpan(spanId, %*{}, status = "error", error = e.msg)
    raise

proc synthesize*(app: RLMApp; task: string): string =
  let spanId = app.startSpan("rlm.synthesize", "chain", %*{"task": short(task), "workspace": workspaceAsText(app)})
  try:
    result = callModel(app, fmt"""
Sintetize a resposta final.

Tarefa:
{task}

Workspace atual:
{workspaceAsText(app)}

Eventos executados:
{$app.ctx.events}

Responda usando os dados do workspace. Se a tarefa pedir JSON, retorne somente JSON válido. Não invente dados.
""").content
    app.endSpan(spanId, %*{"answer_preview": short(result)})
  except CatchableError as e:
    app.endSpan(spanId, %*{}, status = "error", error = e.msg)
    raise

proc invoke*(app: RLMApp; task: string; contextPath = ""): string =
  app.startTrace("rlm.invoke", %*{"task": short(task), "context_path": contextPath})
  let rootSpan = app.startSpan("rlm.invoke", "chain", %*{"task": short(task), "context_path": contextPath})
  try:
    app.ctx.vars["task"] = task
    if contextPath.len > 0:
      let path = absolutePath(expandTilde(contextPath))
      if fileExists(path): app.ctx.docs[path] = readFile(path)
      else: app.ctx.vars["context_error"] = "Arquivo não encontrado: " & path

    let commands = app.planCommands(task)
    app.executeCommands(commands)
    result = app.synthesize(task)
    app.ctx.vars["last_answer"] = result
    app.endSpan(rootSpan, %*{"answer_preview": short(result)})
    app.endTrace(%*{"answer_preview": short(result)})
  except CatchableError as e:
    app.endSpan(rootSpan, %*{}, status = "error", error = e.msg)
    app.endTrace(%*{}, status = "error", error = e.msg)
    raise

proc invoke*(task: string; contextPath = ""): string =
  let app = newRLM()
  app.registerDefaultTools()
  app.invoke(task, contextPath)

proc repl*(app: RLMApp) =
  echo "RLM REPL"
  echo "Comandos: :vars | :docs | :tools | :set nome valor | :quit"
  echo ""
  while true:
    stdout.write("rlm> ")
    stdout.flushFile()
    let line = stdin.readLine().strip()
    if line.len == 0: continue
    if line == ":quit" or line == ":q": break
    if line == ":vars":
      for key, value in pairs(app.ctx.vars): echo key, " = ", short(value, 500)
      continue
    if line == ":docs":
      for key, value in pairs(app.ctx.docs): echo key, " = ", value.len, " chars"
      continue
    if line == ":tools":
      echo toolsAsText(app)
      continue
    if line.startsWith(":set "):
      let parts = line[5 .. ^1].split(" ", maxsplit = 1)
      if parts.len == 2:
        app.ctx.vars[parts[0]] = parts[1]
        echo "ok"
      else:
        echo "uso: :set nome valor"
      continue
    try:
      echo app.invoke(line)
    except CatchableError as e:
      echo "erro: ", e.msg

proc defaultRLM*(): RLMApp =
  result = newRLM()
  result.registerDefaultTools()

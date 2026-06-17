import std/[json, strformat]

import ./rlm

type
  DspySignature* = object
    name*: string
    inputType*: string
    outputType*: string
    description*: string

  DspyModule* = object
    name*: string
    signature*: DspySignature

  DspyContext* = ref object
    app*: RLMApp
    fake*: bool

proc signature*(name, inputType, outputType, description: string): DspySignature =
  DspySignature(
    name: name,
    inputType: inputType,
    outputType: outputType,
    description: description
  )

proc dspyModule*(name: string; sig: DspySignature): DspyModule =
  DspyModule(name: name, signature: sig)

proc newDspyContext*(app: RLMApp = defaultRLM(); fake = true): DspyContext =
  DspyContext(app: app, fake: fake)

proc ensureTrace*(ctx: DspyContext; name: string; input: JsonNode) =
  if ctx.app.config.traceDir.len > 0:
    ctx.app.startTrace(name, input)

proc finishTrace*(ctx: DspyContext; output: JsonNode) =
  ctx.app.endTrace(output)

proc failTrace*(ctx: DspyContext; error: string) =
  ctx.app.endTrace(%*{}, status = "error", error = error)

proc repairJsonWithModel*(ctx: DspyContext; originalPrompt, broken, parserError: string): JsonNode =
  let raw = ctx.app.callModel(fmt"""
A resposta anterior deveria ser JSON válido, mas falhou no parsing.

ERRO:
{parserError}

PROMPT ORIGINAL:
{originalPrompt}

RESPOSTA QUEBRADA:
{broken}

Reconstrua a resposta final como JSON válido.
Retorne somente JSON, sem markdown.
""").content
  parseJsonLoose(raw)

proc predictJson*(ctx: DspyContext; m: DspyModule; prompt: string; fakeValue: JsonNode): JsonNode =
  let spanId = ctx.app.startSpan(
    m.name,
    "dspy_module",
    %*{
      "signature": m.signature.name,
      "input_type": m.signature.inputType,
      "output_type": m.signature.outputType,
      "prompt_preview": short(prompt)
    }
  )

  try:
    if ctx.fake:
      result = fakeValue
    else:
      let raw = ctx.app.callModel(
        prompt,
        system = "Você é a inferência textual comum da aplicação. Retorne somente o formato solicitado."
      ).content

      try:
        result = parseJsonLoose(raw)
      except CatchableError as e:
        result = repairJsonWithModel(ctx, prompt, raw, e.msg)

    ctx.app.endSpan(
      spanId,
      result,
      metadata = %*{
        "signature": m.signature.name,
        "module": m.name
      }
    )

  except CatchableError as e:
    ctx.app.endSpan(spanId, %*{}, status = "error", error = e.msg)
    raise

proc predictText*(ctx: DspyContext; m: DspyModule; prompt: string; fakeValue: string): string =
  let spanId = ctx.app.startSpan(
    m.name,
    "dspy_module",
    %*{
      "signature": m.signature.name,
      "input_type": m.signature.inputType,
      "output_type": m.signature.outputType,
      "prompt_preview": short(prompt)
    }
  )

  try:
    result = if ctx.fake: fakeValue else: ctx.app.callModel(prompt).content

    ctx.app.endSpan(
      spanId,
      %*{"text_preview": short(result)},
      metadata = %*{
        "signature": m.signature.name,
        "module": m.name
      }
    )

  except CatchableError as e:
    ctx.app.endSpan(spanId, %*{}, status = "error", error = e.msg)
    raise

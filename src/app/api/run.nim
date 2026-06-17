# src/app/api/run.nim
# Crown file-as-route example for POST /api/run.
# Replace the placeholder Request with Crown's Request in a real Crown app.

import std/[json]

type Request* = object
  body*: string

proc post*(req: Request): string =
  let body =
    try:
      parseJson(req.body)
    except CatchableError:
      newJObject()

  let tema = body{"tema"}.getStr("liberdade de expressão e discurso de ódio em comentários online")
  let quantidade = body{"quantidade"}.getInt(2)
  let fake = body{"fake"}.getBool(true)

  # Real integration point:
  # import ../../../study_bncc_generation
  # let result = runBnccStudy(tema = tema, quantidade = quantidade, fake = fake)
  # return result.pretty()

  result = (%*{
    "ok": true,
    "adapter": "crown-file-as-route",
    "tema": tema,
    "quantidade": quantidade,
    "fake": fake,
    "next": "Replace this stub with runBnccStudy(...) from your study script."
  }).pretty()

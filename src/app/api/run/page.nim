# Crown file-as-page API target.
# This route delegates to the application main, not to a separate domain/module package.

import std/json
import crown/core

import ../../../../main

proc post*(req: Request): string =
  let params =
    if req.body.len > 0:
      parseJson(req.body)
    else:
      %*{"fake": true}

  runAppFromJson(params).pretty()

proc page*(req: Request): string =
  """{"ok":true,"route":"POST /api/run","usage":{"tema":"...","quantidade":2,"fake":true}}"""

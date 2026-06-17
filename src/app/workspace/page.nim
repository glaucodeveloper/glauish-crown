# src/app/workspace/page.nim
# Crown file-as-page example using the React-like Crown DSL.
# In Crown, this file is intended to become GET /workspace.

import std/json

# If Crown exports a conflicting html macro, avoid importing it in this page.
# import crown/core except html
# or import only the Request type from Crown, depending on your Crown version.
# import crown/core

import ../../stack/crown_reactish

type Request* = object
  ## Placeholder only so this example can be checked without Crown.
  ## Remove this type when importing Crown's Request.
  path*: string

componentDef PageHeader:
  header(cls("rx-header")):
    h1(cls("rx-title")):
      text prop(props, "title")
    p(cls("rx-subtitle")):
      text prop(props, "subtitle")

proc page*(req: Request): string =
  rxPage:
    doctype()
    html(a("lang", "pt-BR")):
      head():
        meta(a("charset", "utf-8"))
        meta(name("viewport"), a("content", "width=device-width, initial-scale=1"))
        styleSrc("/workspace.css")
        scriptSrc("/reactish.js")
        scriptSrc("/workspace.js")
      body():
        main(cls("rx-page")):
          div(cls("rx-shell")):
            component PageHeader, %*{
              "title": "BNCC RLM Workspace",
              "subtitle": "Crown file-as-page + Reactish frontend-only + RLM stack."
            }

            island(
              "bncc-workspace",
              "BnccWorkspace",
              "rx-island",
              %*{
                "tema": "liberdade de expressão e discurso de ódio em comentários online",
                "quantidade": 2,
                "mode": "fake",
                "loading": false,
                "output": ""
              }
            ):
              p(cls("rx-subtitle")):
                text "Carregando componente frontend..."

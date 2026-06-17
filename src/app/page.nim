# src/app/page.nim
# Crown file-as-page example for GET /.

import ../stack/crown_reactish

type Request* = object
  path*: string

proc page*(req: Request): string =
  rxPage:
    doctype()
    html(a("lang", "pt-BR")):
      head():
        meta(a("charset", "utf-8"))

        styleSrc("/workspace.css")
      body():
        main(cls("rx-page")):
          box(cls("rx-shell")):
            h1(cls("rx-title")):
              text "BNCC RLM"
            p(cls("rx-subtitle")):
              text "Abra /workspace para executar a geração."
            tag("a", href("/workspace"), cls("rx-link")):
              text "Ir para workspace"

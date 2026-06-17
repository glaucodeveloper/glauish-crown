# src/app/layout/layout.nim
# Optional Crown layout shell.
# Some Crown versions support layout files; if yours differs, inline this in page.nim.

proc layout*(content: string): string =
  """<!doctype html>
<html lang=\"pt-BR\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>BNCC RLM Workspace</title>
</head>
<body>""" & content & """</body>
</html>"""

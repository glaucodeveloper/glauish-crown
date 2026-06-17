# Crown React-like DSL

Este pacote é um patch de arquitetura para Crown file-as-page:

```text
src/stack/crown_reactish.nim      # DSL Nim server-side para HTML/componentes/islands
src/app/page.nim                  # página Crown GET /
src/app/workspace/page.nim        # página Crown GET /workspace
src/app/api/run.nim               # endpoint Crown POST /api/run
public/reactish.js                # runtime frontend-only
public/workspace.js               # componente frontend da página
public/workspace.css              # CSS mínimo
```

## Modelo mental

A renderização Crown continua server-side:

```nim
proc page*(req: Request): string =
  rxPage:
    doctype()
    html:
      body:
        main(cls("rx-page")):
          h1:
            text "Workspace"
```

Componentes server-side são `proc(rx, props)` geradas por `componentDef`:

```nim
componentDef Header:
  h1:
    text prop(props, "title")
```

Islands frontend-only são montadas com:

```nim
island("bncc-workspace", "BnccWorkspace", "rx-island", %*{"tema": "..."}):
  text "fallback"
```

O JS registra o componente:

```js
Reactish.component('BnccWorkspace', function (ctx) {
  return ctx.html`<button data-rx-click="run">Executar</button>`
})
```

Ação frontend:

```js
Reactish.action('run', async function (ctx) {
  const result = await ctx.postJson('/api/run', ctx.state)
  ctx.setState({ output: result })
})
```

## Integração com o estudo BNCC

No arquivo `src/app/api/run.nim`, troque o stub por:

```nim
import ../../../study_bncc_generation
let result = runBnccStudy(tema = tema, quantidade = quantidade, fake = fake)
return result.pretty()
```

O ponto é manter o estudo BNCC corrido em um `.nim`, e abstrair apenas:

- `stack/rlm.nim`
- `stack/crown_reactish.nim`
- página Crown
- endpoint Crown

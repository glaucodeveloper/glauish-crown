// public/workspace.js
// Example frontend-only component for the Crown workspace page.

Reactish.component('BnccWorkspace', function (ctx) {
  const s = ctx.state
  const out = typeof s.output === 'string' ? s.output : JSON.stringify(s.output || {}, null, 2)

  return ctx.html`
    <div class="rx-card">
      <div class="rx-grid">
        <label class="rx-field">
          <span>Tema</span>
          <input data-rx-bind="tema" value="${ctx.escapeHtml(s.tema || '')}" />
        </label>

        <label class="rx-field">
          <span>Quantidade</span>
          <input data-rx-bind="quantidade" type="number" value="${s.quantidade || 2}" />
        </label>

        <label class="rx-field">
          <span>Modo</span>
          <select data-rx-bind="mode">
            <option value="fake" ${s.mode === 'fake' ? 'selected' : ''}>fake</option>
            <option value="real" ${s.mode === 'real' ? 'selected' : ''}>real LLM</option>
          </select>
        </label>
      </div>

      <div class="rx-actions">
        <button data-rx-click="bncc.run" ${s.loading ? 'disabled' : ''}>
          ${s.loading ? 'Executando...' : 'Executar geração'}
        </button>
        <button data-rx-click="bncc.clear">Limpar</button>
      </div>

      <div class="rx-tabs">
        <button data-rx-click="tab.output">Output</button>
        <button data-rx-click="tab.trace">Trace</button>
      </div>

      <pre class="rx-output">${ctx.escapeHtml(out)}</pre>
    </div>
  `
})

Reactish.action('bncc.run', async function (ctx) {
  ctx.setState({ loading: true, output: 'Executando pipeline BNCC...' })

  try {
    const result = await ctx.postJson('/api/run', {
      tema: ctx.state.tema,
      quantidade: Number(ctx.state.quantidade || 2),
      fake: ctx.state.mode !== 'real'
    })

    ctx.setState({ loading: false, output: result })
  } catch (err) {
    ctx.setState({ loading: false, output: String(err && err.stack || err) })
  }
})

Reactish.action('bncc.clear', function (ctx) {
  ctx.setState({ output: '' })
})

Reactish.action('tab.output', function (ctx) {
  ctx.setState({ tab: 'output' })
})

Reactish.action('tab.trace', function (ctx) {
  ctx.setState({ tab: 'trace', output: 'Trace viewer entra aqui: carregar .rlm/spans.jsonl por endpoint Crown.' })
})

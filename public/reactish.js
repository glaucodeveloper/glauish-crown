// public/reactish.js
// Tiny frontend-only runtime for Crown pages rendered with stack/crown_reactish.nim.
// It is not React; it only copies the mental model: component -> state -> render -> setState.

(function () {
  const components = Object.create(null)
  const actions = Object.create(null)

  function escapeHtml(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')
  }

  function html(strings, ...values) {
    let out = ''
    for (let i = 0; i < strings.length; i++) {
      out += strings[i]
      if (i < values.length) out += values[i] ?? ''
    }
    return out
  }

  function readInitialState(root) {
    const stateId = root.dataset.rxState
    if (!stateId) return {}

    const script = document.getElementById(stateId)
    if (!script) return {}

    try {
      return JSON.parse(script.textContent || '{}')
    } catch (_) {
      return {}
    }
  }

  function readBoundInputs(root, state) {
    root.querySelectorAll('[data-rx-bind]').forEach((el) => {
      const key = el.dataset.rxBind
      if (!key) return

      if (el.type === 'checkbox') state[key] = !!el.checked
      else if (el.type === 'number') state[key] = Number(el.value || 0)
      else state[key] = el.value
    })
  }

  function mountRoot(root) {
    const componentName = root.dataset.rxComponent
    const component = components[componentName]

    if (!component) {
      console.warn('[Reactish] component not registered:', componentName)
      return
    }

    let state = readInitialState(root)
    let mounted = false

    const ctx = {
      root,
      html,
      escapeHtml,
      get state() {
        return state
      },
      setState(patch) {
        state = Object.assign({}, state, patch || {})
        render()
      },
      update(fn) {
        const next = Object.assign({}, state)
        fn(next)
        state = next
        render()
      },
      async postJson(url, payload) {
        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        })

        const text = await res.text()
        try {
          return JSON.parse(text)
        } catch (_) {
          return text
        }
      }
    }

    function bindEvents() {
      root.querySelectorAll('[data-rx-click]').forEach((el) => {
        const actionName = el.dataset.rxClick
        el.addEventListener('click', async (ev) => {
          readBoundInputs(root, state)
          const action = actions[actionName]
          if (action) await action(ctx, ev)
        })
      })

      root.querySelectorAll('[data-rx-input]').forEach((el) => {
        const actionName = el.dataset.rxInput
        el.addEventListener('input', async (ev) => {
          readBoundInputs(root, state)
          const action = actions[actionName]
          if (action) await action(ctx, ev)
        })
      })

      root.querySelectorAll('[data-rx-submit]').forEach((el) => {
        const actionName = el.dataset.rxSubmit
        el.addEventListener('submit', async (ev) => {
          ev.preventDefault()
          readBoundInputs(root, state)
          const action = actions[actionName]
          if (action) await action(ctx, ev)
        })
      })
    }

    function render() {
      const output = component(ctx)
      if (typeof output === 'string') root.innerHTML = output
      bindEvents()

      if (!mounted) {
        mounted = true
        const action = actions[componentName + '.mount']
        if (action) action(ctx)
      }
    }

    render()
  }

  function mountAll() {
    document.querySelectorAll('[data-rx-component]').forEach(mountRoot)
  }

  window.Reactish = {
    component(name, fn) {
      components[name] = fn
    },
    action(name, fn) {
      actions[name] = fn
    },
    mountAll,
    html,
    escapeHtml
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', mountAll)
  } else {
    mountAll()
  }
})()

// tiny frontend-only React-like runtime for Crown/SSR pages.
// No build step. No dependencies.
(function (global) {
  function h(tag, props) {
    props = props || {};
    var children = [];
    for (var i = 2; i < arguments.length; i++) {
      var child = arguments[i];
      if (Array.isArray(child)) children = children.concat(child);
      else children.push(child);
    }
    return { tag: tag, props: props, children: children };
  }

  function setProp(el, key, value) {
    if (key === 'className') key = 'class';
    if (key.slice(0, 2) === 'on' && typeof value === 'function') {
      el.addEventListener(key.slice(2).toLowerCase(), value);
    } else if (key === 'style' && typeof value === 'object') {
      Object.assign(el.style, value);
    } else if (value !== false && value != null) {
      el.setAttribute(key, value === true ? '' : String(value));
    }
  }

  function node(v) {
    if (v == null || v === false) return document.createTextNode('');
    if (typeof v === 'string' || typeof v === 'number') return document.createTextNode(String(v));
    if (typeof v.tag === 'function') return node(v.tag(Object.assign({}, v.props, { children: v.children })));
    var el = document.createElement(v.tag);
    Object.keys(v.props || {}).forEach(function (key) { setProp(el, key, v.props[key]); });
    (v.children || []).forEach(function (child) { el.appendChild(node(child)); });
    return el;
  }

  function createStore(initial) {
    var state = initial || {};
    var subs = [];
    return {
      get: function () { return state; },
      set: function (patch) {
        state = Object.assign({}, state, patch);
        subs.forEach(function (fn) { fn(state); });
      },
      subscribe: function (fn) {
        subs.push(fn);
        return function () { subs = subs.filter(function (x) { return x !== fn; }); };
      }
    };
  }

  function mount(root, component, store) {
    function redraw() {
      root.innerHTML = '';
      root.appendChild(node(component(store.get(), store.set)));
    }
    store.subscribe(redraw);
    redraw();
  }

  async function apiRun(payload) {
    var res = await fetch('/api/run', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload || {})
    });
    if (!res.ok) throw new Error(await res.text());
    return await res.json();
  }

  global.Reactish = { h: h, createStore: createStore, mount: mount, apiRun: apiRun };
})(window);

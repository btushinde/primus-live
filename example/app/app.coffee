# make Primus object global for console debugging
window.primus = new Primus

primus.on 'data', (data) ->
  if typeof data is 'number'
    el = document.getElementById 'tick'
    el.textContent = new Date(data)

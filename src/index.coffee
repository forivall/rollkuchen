CS = require 'coffee-script-redux'
cscodegen = require 'cscodegen'

insertHelpers = (node, parent, chunks) ->
  if not node.range then return

  node.parent = parent;

  node.source = -> return chunks.slice(node.range[0], node.range[1]).join('')

  update = (s) ->
    chunks[node.range[0]] = s;
    for i in [node.range[0] + 1...node.range[1]]
      chunks[i] = ''
    return

  if node.update and typeof node.update is 'object'
    prev = node.updaterange
    Object.keys(prev).forEach (key) ->
      update[key] = prev[key];
      return
    node.update = update
  else
    node.update = update
  return

module.exports = (src, opts, fn) ->
  ast = CS.parse(src, {raw: true, optimise: false})
  ast = ast.toBasicObject()

  result = {
    chunks: src.split('')
    toString: -> return result.chunks.join('')
    inspect: -> return result.toString()
  }

  walk = (node, parent) ->
    insertHelpers(node, parent, result.chunks)
    Object.keys(node).forEach (key) ->
      if key is 'parent' then return

      child = node[key]
      # console.log node.type, key, Array.isArray(child)
      if Array.isArray(child) then child.forEach (c) ->
        if c and typeof c.type is 'string'
          walk(c, node)
      else if child and typeof child.type is 'string'
        insertHelpers(child, node, result.chunks)
        walk(child, node)
      return
    fn(node)
    return
  walk(ast)

  # return cscodegen.generate()
  return result

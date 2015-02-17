#= require_self
#= require trix/elements/element

html = document.documentElement
match = html.matchesSelector ? html.webkitMatchesSelector ? html.msMatchesSelector ? html.mozMatchesSelector

Trix.extend
  handleEvent: (eventName, {onElement, matchingSelector, withCallback, inPhase, preventDefault, times} = {}) ->
    element = onElement ? html
    selector = matchingSelector
    callback = withCallback
    useCapture = inPhase is "capturing"

    handler = (event) ->
      handler.destroy() if times? and --times is 0
      target = Trix.findClosestElementFromNode(event.target, matchingSelector: selector)
      withCallback?.call(target, event, target) if target?
      event.preventDefault() if preventDefault

    handler.destroy = ->
      element.removeEventListener(eventName, handler, useCapture)

    element.addEventListener(eventName, handler, useCapture)
    handler

  handleEventOnce: (eventName, options = {}) ->
    options.times = 1
    Trix.handleEvent(eventName, options)

  triggerEvent: (eventName, {onElement, bubbles, cancelable, attributes} = {}) ->
    element = onElement ? html
    bubbles = bubbles isnt false
    cancelable = cancelable isnt false

    event = document.createEvent("Events")
    event.initEvent(eventName, bubbles, cancelable)
    Trix.extend.call(event, attributes) if attributes?
    element.dispatchEvent(event)

  elementMatchesSelector: (element, selector) ->
    if element?.nodeType is 1
      match.call(element, selector)

  findClosestElementFromNode: (node, {matchingSelector} = {}) ->
    node = node.parentNode until not node? or node.nodeType is Node.ELEMENT_NODE

    if matchingSelector?
      while node
        return node if Trix.elementMatchesSelector(node, matchingSelector)
        node = node.parentNode
    else
      node

  findInnerElement: (element) ->
    element = element.firstElementChild while element?.firstElementChild
    element

  elementContainsNode: (element, node) ->
    return unless element and node
    while node
      return true if node is element
      node = node.parentNode

  findNodeFromContainerAndOffset: (container, offset) ->
    return unless container
    if container.nodeType is Node.TEXT_NODE
      container
    else if offset is 0
      container.firstChild ? container
    else
      container.childNodes.item(offset - 1)

  findElementFromContainerAndOffset: (container, offset) ->
    node = Trix.findNodeFromContainerAndOffset(container, offset)
    Trix.findClosestElementFromNode(node)

  measureElement: (element) ->
    width:  element.offsetWidth
    height: element.offsetHeight

  walkTree: (tree, {onlyNodesOfType, usingFilter, expandEntityReferences} = {}) ->
    whatToShow = switch onlyNodesOfType
      when "element" then NodeFilter.SHOW_ELEMENT
      when "text"    then NodeFilter.SHOW_TEXT
      when "comment" then NodeFilter.SHOW_COMMENT
      else NodeFilter.SHOW_ALL

    document.createTreeWalker(tree, whatToShow, usingFilter ? null, expandEntityReferences is true)

  tagName: (element) ->
    element?.tagName?.toLowerCase()

  makeElement: (tagName, options = {}) ->
    if typeof tagName is "object"
      options = tagName
      {tagName} = options
    else
      options = attributes: options

    element = document.createElement(tagName)

    if options.editable?
      options.attributes ?= {}
      options.attributes.contenteditable = options.editable

    if options.attributes
      for key, value of options.attributes
        element.setAttribute(key, value)

    if options.style
      for key, value of options.style
        element.style[key] = value

    if options.data
      for key, value of options.data
        element.dataset[key] = value

    if options.className
      for className in options.className.split(" ")
        element.classList.add(className)

    if options.textContent
      element.textContent = options.textContent

    element

  defineElement: (constructor) ->
    tagName = constructor.tagName
    constructorName = Trix.convertDashesToCamelCase(tagName, initial: true) + "Element"
    registeredConstructor = document.registerElement(tagName, prototype: constructor.prototype)
    window[constructorName] = Trix.extend.call(registeredConstructor, constructor)

  nodeIsBlockStartComment: (node) ->
    return unless node
    node.nodeType is Node.COMMENT_NODE and node.data is "block"

  nodeIsCursorTarget: (node) ->
    return unless node
    if node.nodeType is Node.TEXT_NODE
      node.textContent is Trix.ZERO_WIDTH_SPACE
    else
      Trix.nodeIsCursorTarget(node.firstChild)

  nodeIsEmptyTextNode: (node) ->
    return unless node
    node.nodeType is Node.TEXT_NODE and node.data is ""


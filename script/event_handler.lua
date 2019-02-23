return function(events)
  return function(event)
    local events = events
    local name = event.name
    local action = events[name] or function() return end
    return action(event)
  end
end
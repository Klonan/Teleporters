local teleporter_name = require"shared".entities.teleporter

local data =
{
  networks = {},
  rename_frames = {},
  button_actions = {},
  map = {},
  teleporter_frames = {},
  player_linked_teleporter = {},
  to_be_removed = {}
}

local print = function(string)
  game.print(string)
  log(string)
end

local create_flash = function(surface, position)
  surface.create_entity{name = "teleporter-explosion", position = position}
  for k = 1, 3 do
    surface.create_entity{name = "teleporter-explosion-no-sound", position = position}
  end
end


local clear_gui = function(frame)
  if not (frame and frame.valid) then return end
  util.deregister_gui(frame, data.button_actions)
  frame.clear()
end

local close_gui = function(frame)
  if not (frame and frame.valid) then return end
  util.deregister_gui(frame, data.button_actions)
  frame.destroy()
end

local get_rename_frame = function(player)
  return data.rename_frames[player.index]
end

local get_teleporter_frame = function(player)
  return data.teleporter_frames[player.index]
end

local close_teleporter_frame = function(player)
  local frame = get_teleporter_frame(player)
  if not frame and frame.valid then return end
  local player = game.players[frame.player_index]
  local character = player.character
  if character then
    character.active = true
  end
  local source = param.source
  if (source and source.valid) then
    source.active = true
  end
  close_gui(frame)
  --print("Set linked to nil")
  data.player_linked_teleporter[player.index] = nil
end

local make_rename_frame = function(player, caption)
  local force = player.force
  local teleporters = data.networks[force.name]
  local param = teleporters[caption]
  local text = param.flying_text
  local gui = player.gui.center
  clear_gui(gui)
  local frame = gui.add{type = "frame", caption = {"name-teleporter"}, direction = "horizontal"}
  data.rename_frames[player.index] = frame
  player.opened = frame

  local textfield = frame.add{type = "textfield", text = caption}
  textfield.style.horizontally_stretchable = true
  local confirm = frame.add{type = "sprite-button", sprite = "utility/confirm_slot", style = "slot_button"}
  util.register_gui(data.button_actions, confirm, {type = "confirm_rename_button", frame = frame, textfield = textfield, flying_text = text})

  local cancel = frame.add{type = "sprite-button", sprite = "utility/set_bar_slot", style = "slot_button"}
  util.register_gui(data.button_actions, cancel, {type = "cancel_button", frame = frame})

end

local unlink_teleporter = function(player)
  if player.character then player.character.active = true end
  close_gui(get_teleporter_frame(player))
  local source = data.player_linked_teleporter[player.index]
  if source and source.valid then
    source.active = true
  end
  data.player_linked_teleporter[player.index] = nil
end

local make_teleporter_gui = function(player, source)
  
  if not (source and source.valid and not data.to_be_removed[source.unit_number]) then
    unlink_teleporter(player)
    return
  end
  local force = source.force
  local network = data.networks[force.name]
  if not network then return end

  local gui = player.gui.center
  clear_gui(gui)
  local frame = player.gui.center.add{type = "frame", direction = "vertical"}
  player.opened = frame
  data.teleporter_frames[player.index] = frame


  local title_flow = frame.add{type = "flow", direction = "horizontal"}
  title_flow.style.vertical_align = "center"
  local title = title_flow.add{type = "label", style = "heading_1_label"}
  local rename_button = title_flow.add{type = "sprite-button", sprite = "utility/rename_icon_small", style = "small_slot_button"}
  local inner = frame.add{type = "frame", style = "inside_deep_frame"}
  local scroll = inner.add{type = "scroll-pane", direction = "vertical"}
  local table = scroll.add{type = "table", column_count = 4}
  table.style.horizontal_spacing = 2
  table.style.vertical_spacing = 2
  local any = false
  --print(table_size(network))
  for name, teleporter in pairs (network) do
    if teleporter.teleporter == source then
      title.caption = name
      util.register_gui(data.button_actions, rename_button, {type = "rename_button", caption = name})
    else
      local button = table.add{type = "button"}--, direction = "vertical", style = "bordered_frame"}
      button.style.height = 160 + 32
      button.style.width = 160
      button.style.left_padding = 0
      button.style.right_padding = 0
      local inner_flow = button.add{type = "flow", direction = "vertical", ignored_by_interaction = true}
      inner_flow.style.vertically_stretchable = true
      inner_flow.style.horizontally_stretchable = true
      inner_flow.style.horizontal_align = "center"
      local map = inner_flow.add
      {
        type = "minimap",
        surface_index = teleporter.teleporter.surface.index,
        zoom = 1,
        force = teleporter.teleporter.force.name,
        position = teleporter.teleporter.position,
      }
      map.ignored_by_interaction = true
      map.style.height = 160 - 8
      map.style.width = 160 - 8
      map.style.horizontally_stretchable = true
      map.style.vertically_stretchable = true
      local label = inner_flow.add{type = "label", caption = name}
      label.style.horizontally_stretchable = true
      label.style.font = "default-dialog-button"
      label.style.font_color = {}
      label.style.horizontally_stretchable = true
      label.style.maximal_width = 160 - 8
      label.style.want_ellipsis = true

      util.register_gui(data.button_actions, button, {type = "teleport_button", param = teleporter, frame = frame, source = source})

      any = true
    end
  end
  if not any then
    table.add{type = "label", caption = {"no-teleporters"}}
  end
end

local refresh_teleporter_frames = function()
  for player_index, source in pairs (data.player_linked_teleporter) do
    make_teleporter_gui(game.get_player(player_index), source)
  end
end

local check_player_linked_teleporter = function(player)  
  local source = data.player_linked_teleporter[player.index]
  if source and source.valid then
    --print("Linked teleporter exists...")
    make_teleporter_gui(player, source)
  else
    unlink_teleporter(player)
  end
end

local gui_actions =
{
  rename_button = function(event, param)
    make_rename_frame(game.get_player(event.player_index), param.caption)
  end,
  cancel_button = function(event, param)
    close_gui(param.frame)
    check_player_linked_teleporter(game.get_player(event.player_index))
  end,
  confirm_rename_button = function(event, param)
    local flying_text = param.flying_text
    if not (flying_text and flying_text.valid) then return end
    local player = game.players[event.player_index]
    if not (player and player.valid) then return end
    local key = flying_text.text
    local network = data.networks[player.force.name]
    local info = network[key]
    local new_key = param.textfield.text
    if network[new_key] and network[new_key] ~= info then
      player.print({"name-already-taken"})
      return
    end
    if new_key ~= key then
      network[new_key] = info
      network[key] = nil
      param.flying_text.text = new_key
    end
    close_gui(param.frame)
    check_player_linked_teleporter(player)


  end,
  teleport_button = function(event, param)
    local teleport_param = param.param
    if not teleport_param then return end
    local destination = teleport_param.teleporter
    if not (destination and destination.valid) then return end
    destination.timeout = 300
    local destination_surface = destination.surface
    local destination_position = destination.position
    create_flash(destination_surface, destination_position)
    local player = game.players[event.player_index]
    if not (player and player.valid) then return end
    --This teleport doesn't check collisions. If someone complains, make it check 'can_place' and if false find a positions etc....
    player.teleport(destination_position, destination_surface)
    close_gui(param.frame)
    local source = param.source
    if source and source.valid then
      create_flash(source.surface, source.position)
      source.active = true
    end
    if player.character then
      player.character.active = true
    end
  end
}

local get_force_color = function(force)
  local player = force.connected_players[1]
  if player and player.valid then
    return player.chat_color
  end
  return {r = 1, b = 1, g = 1}
end

local on_robot_built_entity = function(event)
  local entity = event.created_entity
  if not (entity and entity.valid) then return end
  if entity.name ~= teleporter_name then return end
  local surface = entity.surface
  local force = entity.force
  local caption = "Teleporter ".. entity.unit_number
  local text = surface.create_entity
  {
    name = "teleporter-flying-text",
    text = caption,
    position = {entity.position.x, entity.position.y - 2},
    force = force,
    color = get_force_color(force)
  }
  text.active = false

  data.networks[force.name] = data.networks[force.name] or {}
  local network = data.networks[force.name]
  network[caption] = {teleporter = entity, flying_text = text}
  data.map[entity.unit_number] = network[caption]
  refresh_teleporter_frames()
end

local on_built_entity = function(event)
  local entity = event.created_entity
  if not (entity and entity.valid) then return end
  if entity.name ~= teleporter_name then return end
  local player = game.players[event.player_index]
  local surface = entity.surface
  local force = entity.force
  local caption = "Teleporter "..entity.unit_number
  local text = surface.create_entity
  {
    name = "teleporter-flying-text",
    text = caption,
    position = {entity.position.x, entity.position.y - 2},
    force = force,
    color = player.chat_color
  }
  text.active = false

  data.networks[force.name] = data.networks[force.name] or {}
  local network = data.networks[force.name]
  network[caption] = {teleporter = entity, flying_text = text}
  data.map[entity.unit_number] = network[caption]
  make_rename_frame(player, caption)
  refresh_teleporter_frames()
end

local on_teleporter_removed = function(entity)
  if not (entity and entity.valid) then return end
  if entity.name ~= teleporter_name then return end
  local force = entity.force
  local param = data.map[entity.unit_number]
  if not param then return end
  local caption = param.flying_text.text
  local network = data.networks[force.name]
  network[caption] = nil
  param.flying_text.destroy()
  data.map[entity.unit_number] = nil
  data.to_be_removed[entity.unit_number] = true
  refresh_teleporter_frames()
  data.to_be_removed[entity.unit_number] = nil
end

local teleporter_triggered = function(entity)
  --print("Triggered "..game.tick)
  --print(serpent.block(data.teleporter_frames))
  if not (entity and entity.valid and entity.name == teleporter_name) then return end
  local force = entity.force
  local surface = entity.surface
  local position = entity.position
  local param = data.map[entity.unit_number]
  local new_teleporter = surface.create_entity
  {
    name = teleporter_name,
    position = position,
    force = force,
    create_build_effect_smoke = false
  }
  param.teleporter = new_teleporter
  data.map[new_teleporter.unit_number] = param
  data.map[entity.unit_number] = nil
  local character = surface.find_entities_filtered{type = "player", area = {{position.x - 2, position.y - 2}, {position.x + 2, position.y + 2}}, force = force}[1]
  if not character then return end
  local player = character.player
  if not player then return end
  new_teleporter.active = false
  character.active = false
  data.player_linked_teleporter[player.index] = new_teleporter
  local gui = player.gui.center
  clear_gui(gui)
  entity.destroy()
  make_teleporter_gui(player, new_teleporter)
end



local on_entity_died = function(event)
  local cause = event.cause
  local entity = event.entity
  if cause and cause.valid and entity and entity.valid and entity.name == teleporter_name and cause == entity then
    return teleporter_triggered(entity)
  end
  on_teleporter_removed(event.entity)
end

local on_player_mined_entity = function(event)
  on_teleporter_removed(event.entity)
end

local on_robot_mined_entity = function(event)
  on_teleporter_removed(event.entity)
end

local on_gui_click = function(event)
  local element = event.element
  if not (element and element.valid) then return end
  local player_data = data.button_actions[event.player_index]
  if not player_data then return end
  local action = player_data[element.index]
  if action then
    gui_actions[action.type](event, action)
    return true
  end
end

local on_gui_closed = function(event)
  --print("CLOSED "..event.tick)
  local element = event.element
  if not (element and element.valid) then return end

  local player = game.get_player(event.player_index)

  local rename_frame = get_rename_frame(player)
  if rename_frame and rename_frame.valid then
    --print("A")
    close_gui(rename_frame)
    check_player_linked_teleporter(player)
    return
  end

  local teleporter_frame = get_teleporter_frame(player)
  if teleporter_frame and teleporter_frame.valid then
    close_gui(teleporter_frame)
    unlink_teleporter(player)
    return
  end


end

local on_player_removed = function(event)
  local player = game.get_player(event.player_index)
  if player.opened_gui_type ~= defines.gui_type.custom then return end
  local frame = player.opened
  if not (frame and frame.valid) then return end

  if get_rename_frame(frame) then
    close_gui(frame)
    return
  end

  local param = get_teleporter_frame(element)
  if param then
    close_teleporter_frame(param)
    return
  end

end

local events =
{
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_robot_built_entity] = on_robot_built_entity,
  [defines.events.on_gui_click] = on_gui_click,
  [defines.events.on_entity_died] = on_entity_died,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_robot_mined_entity] = on_robot_mined_entity,
  [defines.events.on_gui_closed] = on_gui_closed,
  [defines.events.on_player_died] = on_player_removed,
  [defines.events.on_player_left_game] = on_player_removed,
  [defines.events.on_player_changed_force] = on_player_removed
}

local teleporters = {}

teleporters.on_init = function()
  global.teleporters = global.teleporters or data
  teleporters.on_event = handler(events)
end

teleporters.on_load = function()
  data = global.teleporters
  teleporters.on_event = handler(events)
end

teleporters.get_events = function()
  return events
end

teleporters.on_configuration_changed = function()
  -- 0.1.2 migration.
  data.player_linked_teleporter = data.player_linked_teleporter or {}
  data.rename_frames = data.frames or {}
  data.to_be_removed = {}
end

return teleporters

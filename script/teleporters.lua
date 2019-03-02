local teleporter_name = require("shared").entities.teleporter

local data =
{
  networks = {},
  rename_frames = {},
  button_actions = {},
  teleporter_map = {},
  teleporter_frames = {},
  player_linked_teleporter = {},
  to_be_removed = {},
  tag_map = {}
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
  local frame = data.rename_frames[player.index]
  if frame and frame.valid then return frame end
  data.rename_frames[player.index] = nil
end

local get_teleporter_frame = function(player)
  local frame = data.teleporter_frames[player.index]
  if frame and frame.valid then return frame end
  data.teleporter_frames[player.index] = nil
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
  util.register_gui(data.button_actions, confirm, {type = "confirm_rename_button", textfield = textfield, flying_text = text, tag = param.tag})

  local cancel = frame.add{type = "sprite-button", sprite = "utility/set_bar_slot", style = "slot_button"}
  util.register_gui(data.button_actions, cancel, {type = "cancel_rename"})

end

local get_force_color = function(force)
  local player = force.connected_players[1]
  if player and player.valid then
    return player.chat_color
  end
  return {r = 1, b = 1, g = 1}
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
  local pusher = title_flow.add{type = "flow", direction = "horizontal"}
  pusher.style.horizontally_stretchable = true
  local search_box = title_flow.add{type = "textfield", visible = false}
  local search_button = title_flow.add{type = "sprite-button", style = "tool_button", sprite = "utility/search_icon"}
  util.register_gui(data.button_actions, search_button, {type = "search_button", box = search_box})
  local inner = frame.add{type = "frame", style = "inside_deep_frame"}
  local scroll = inner.add{type = "scroll-pane", direction = "vertical"}
  local table = scroll.add{type = "table", column_count = 4}
  util.register_gui(data.button_actions, search_box, {type = "search_text_changed", parent = table})
  table.style.horizontal_spacing = 2
  table.style.vertical_spacing = 2
  local any = false
  --print(table_size(network))
  for name, teleporter in pairs (network) do
    if teleporter.teleporter == source then
      title.caption = name
      util.register_gui(data.button_actions, rename_button, {type = "rename_button", caption = name})
    else
      local button = table.add{type = "button", name = name}
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
      util.register_gui(data.button_actions, button, {type = "teleport_button", param = teleporter})
      any = true
    end
  end
  if not any then
    table.add{type = "label", caption = {"no-teleporters"}}
  end
end

local refresh_teleporter_frames = function()
  local players = game.players
  for player_index, source in pairs (data.player_linked_teleporter) do
    local player = players[player_index]
    if get_teleporter_frame(player) then
      make_teleporter_gui(player, source)
    end
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

local clear_teleporter_data = function(teleporter_data)
  local flying_text = teleporter_data.flying_text
  if flying_text and flying_text.valid then
    flying_text.destroy()
  end
  local map_tag = teleporter_data.tag
  if map_tag and map_tag.valid then
    data.tag_map[map_tag.tag_number] = nil
    map_tag.destroy()
  end
end

local resync_teleporter = function(name, teleporter_data)
  local teleporter = teleporter_data.teleporter
  if not (teleporter and teleporter.valid) then
    return
  end
  local force = teleporter.force
  local surface = teleporter.surface
  local color = get_force_color(force)

  clear_teleporter_data(teleporter_data)

  local flying_text = teleporter.surface.create_entity
  {
    name = "teleporter-flying-text",
    text = name,
    position = {teleporter.position.x, teleporter.position.y - 2},
    force = force,
    color = color
  }
  flying_text.active = false
  teleporter_data.flying_text = flying_text

  data.adding_tag = true
  local map_tag = force.add_chart_tag(surface,
  {
    icon = {type = "item", name = teleporter_name},
    position = teleporter.position,
    text = name
  })
  data.adding_tag = false

  if map_tag then
    teleporter_data.tag = map_tag
    data.tag_map[map_tag.tag_number] = teleporter_data
  end

end

local is_name_available = function(force, name)
  local network = data.networks[force.name]
  return not network[name]
end

local rename_teleporter = function(force, old_name, new_name)
  local network = data.networks[force.name]
  local teleporter_data = network[old_name]
  network[new_name] = teleporter_data
  network[old_name] = nil
  resync_teleporter(new_name, teleporter_data)
  refresh_teleporter_frames()
end

local gui_actions =
{
  rename_button = function(event, param)
    make_rename_frame(game.get_player(event.player_index), param.caption)
  end,
  cancel_rename = function(event, param)
    local player = game.get_player(event.player_index)
    close_gui(get_rename_frame(player))
    check_player_linked_teleporter(player)
  end,
  confirm_rename_button = function(event, param)
    local flying_text = param.flying_text
    if not (flying_text and flying_text.valid) then return end
    local player = game.players[event.player_index]
    if not (player and player.valid) then return end
    local old_name = flying_text.text
    local new_name = param.textfield.text
    if new_name ~= old_name then
      if not is_name_available(player.force, new_name) then
        player.print({"name-already-taken"})
        return
      end
      rename_teleporter(player.force, old_name, new_name)
    end
    close_gui(get_rename_frame(player))
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
    local player = game.players[event.player_index]
    if not (player and player.valid) then return end
    create_flash(destination_surface, destination_position)
    create_flash(player.surface, player.position)
    --This teleport doesn't check collisions. If someone complains, make it check 'can_place' and if false find a positions etc....
    player.teleport(destination_position, destination_surface)
    unlink_teleporter(player)
  end,
  search_text_changed = function(event, param)
    local box = event.element
    local search = box.text
    local parent = param.parent
    for k, child in pairs (parent.children) do
      child.visible = child.name:find(search)
    end
  end,
  search_button = function(event, param)
    param.box.visible = not param.box.visible
    if param.box.visible then param.box.focus() end
  end
}

local get_network = function(force)
  local name = force.name
  local network = data.networks[name]
  if network then return network end
  data.networks[name] = {}
  return data.networks[name]
end

local on_built_entity = function(event)
  local entity = event.created_entity
  if not (entity and entity.valid) then return end
  if entity.name ~= teleporter_name then return end
  local surface = entity.surface
  local force = entity.force
  local name = "Teleporter ".. entity.unit_number
  local network = get_network(force)
  local teleporter_data = {teleporter = entity, flying_text = text, tag = tag}
  network[name] = teleporter_data
  data.teleporter_map[entity.unit_number] = teleporter_data
  resync_teleporter(name, teleporter_data)
  refresh_teleporter_frames()
  if event.player_index then
    make_rename_frame(game.get_player(event.player_index), name)
  end
end

local on_teleporter_removed = function(entity)
  if not (entity and entity.valid) then return end
  if entity.name ~= teleporter_name then return end
  local force = entity.force
  local teleporter_data = data.teleporter_map[entity.unit_number]
  if not teleporter_data then return end
  local caption = teleporter_data.flying_text.text
  local network = get_network(force)
  network[caption] = nil
  clear_teleporter_data(teleporter_data)
  data.teleporter_map[entity.unit_number] = nil

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
  local param = data.teleporter_map[entity.unit_number]
  local new_teleporter = surface.create_entity
  {
    name = teleporter_name,
    position = position,
    force = force,
    create_build_effect_smoke = false
  }
  param.teleporter = new_teleporter
  data.teleporter_map[new_teleporter.unit_number] = param
  data.teleporter_map[entity.unit_number] = nil
  local character = surface.find_entities_filtered{type = "player", area = {{position.x - 2, position.y - 2}, {position.x + 2, position.y + 2}}, force = force}[1]
  if not character then return end
  local player = character.player
  if not player then return end
  player.teleport(entity.position)
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

local on_gui_action = function(event)
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

  local player = game.get_player(event.player_index)

  local rename_frame = get_rename_frame(player)
  if rename_frame then
    close_gui(rename_frame)
    check_player_linked_teleporter(player)
    return
  end

  local teleporter_frame = get_teleporter_frame(player)
  if teleporter_frame then
    close_gui(teleporter_frame)
    unlink_teleporter(player)
    return
  end

end

local on_player_removed = function(event)
  local player = game.get_player(event.player_index)
  close_gui(get_rename_frame(player))
  unlink_teleporter(player)
end

local resync_all_teleporters = function()
  for force, network in pairs (data.networks) do
    for name, teleporter_data in pairs (network) do
      resync_teleporter(name, teleporter_data)
    end
  end
end

local on_chart_tag_modified = function(event)
  local force = event.force
  local tag = event.tag
  if not (force and force.valid and tag and tag.valid) then return end
  local teleporter_data = data.tag_map[tag.tag_number]
  if not teleporter_data then
    --Nothing to do with us...
    return
  end
  local player = event.player_index and game.get_player(event.player_index)

  local old_name = event.old_text
  local new_name = tag.text
  if tag.icon and tag.icon.name ~= teleporter_name then
    --They're trying to modify the icon! Straight to JAIL!
    if player and player.valid then player.print({"cant-change-icon"}) end
    tag.icon = {type = "item", name = teleporter_name}
  end
  if new_name == old_name then
    return
  end
  if new_name == "" or not is_name_available(force, new_name) then
    if player and player.valid then
      player.print({"name-already-taken"})
    end
    tag.text = old_name
    return
  end
  rename_teleporter(force, old_name, new_name)
end

local on_chart_tag_removed = function(event)
  local force = event.force
  local tag = event.tag
  if not (force and force.valid and tag and tag.valid) then return end
  local teleporter_data = data.tag_map[tag.tag_number]
  if not teleporter_data then
    --Nothing to do with us...
    return
  end
  local name = tag.text
  resync_teleporter(name, teleporter_data)
end

local on_chart_tag_added = function(event)
  if data.adding_tag then return end
  local tag = event.tag
  if not (tag and tag.valid) then
    return
  end
  local icon = tag.icon
  if icon.type == "item" and icon.name == teleporter_name then
    --Trying to add a fake teleporter tag! JAIL!
    local player = event.player_index and game.get_player(event.player_index)
    if player and player.valid then player.print({"cant-add-tag"}) end
    tag.destroy()
    return
  end
end

local events =
{
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_robot_built_entity] = on_built_entity,
  [defines.events.on_gui_click] = on_gui_action,
  [defines.events.on_gui_text_changed] = on_gui_action,
  [defines.events.on_entity_died] = on_entity_died,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_robot_mined_entity] = on_robot_mined_entity,
  [defines.events.on_gui_closed] = on_gui_closed,
  [defines.events.on_player_died] = on_player_removed,
  [defines.events.on_player_left_game] = on_player_removed,
  [defines.events.on_player_changed_force] = on_player_removed,
  [defines.events.on_chart_tag_modified] = on_chart_tag_modified,
  [defines.events.on_chart_tag_removed] = on_chart_tag_removed,
  [defines.events.on_chart_tag_added] = on_chart_tag_added,
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
  -- 0.1.2 migration...
  data.player_linked_teleporter = data.player_linked_teleporter or {}
  data.rename_frames = data.rename_frames or data.frames or {}
  data.to_be_removed = data.to_be_removed or {}

  --0.1.5...
  data.teleporter_map = data.teleporter_map or data.map or {}
  data.tag_map = data.tag_map or {}
  resync_all_teleporters()
end

return teleporters

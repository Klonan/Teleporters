local path = util.path("data/entities/teleporters/")
local teleporter = util.copy(data.raw["land-mine"]["land-mine"])
local name = require"shared".entities.teleporter
local localised_name = {name}

teleporter.name = name
teleporter.localised_name = localised_name
teleporter.trigger_radius = 1
teleporter.timeout = 5 * 60
teleporter.max_health = 200
--teleporter.shooting_cursor_size = 0
teleporter.dying_explosion = nil
teleporter.action = nil
teleporter.force_die_on_attack = true
teleporter.trigger_force = "all"
--teleporter.create_ghost_on_death = false
teleporter.order = name
teleporter.picture_safe =
{
  filename = path.."teleporter-closed.png",
  priority = "medium",
  width = 97,
  height = 77,
  scale = 0.75
}
teleporter.picture_set =
{
  filename = path.."teleporter-open.png",
  priority = "medium",
  width = 97,
  height = 77,
  scale = 0.75
}
teleporter.picture_set_enemy =
{
  filename = path.."teleporter-open.png",
  priority = "medium",
  width = 97,
  height = 77,
  scale = 0.75
}
teleporter.minable = {result = name, mining_time = 3}
teleporter.flags =
{
  --"not-blueprintable",
  "placeable-neutral",
  "placeable-player",
  "player-creation",
  "not-upgradable"
}
teleporter.collision_box = {{-1, -1},{1, 1}}
teleporter.selection_box = {{-1, -1},{1, 1}}
teleporter.map_color = {r = 0.5, g = 1, b = 1}

local teleporter_item = util.copy(data.raw.item["land-mine"])
teleporter_item.name = name
teleporter_item.localised_name = localised_name
teleporter_item.place_result = name
teleporter_item.icon = path.."teleporter-icon.png"
teleporter_item.icon_size = 97
teleporter_item.subgroup = "circuit-network"


local fire = require("data/tf_util/tf_fire_util")

local teleporter_explosion = util.copy(data.raw.explosion.explosion)
teleporter_explosion.name = "teleporter-explosion"
teleporter_explosion.animations = fire.create_fire_pictures({tint = {b = 1, g = 1}, shift = {0, 1}, scale = 2, animation_speed = 0.5})
teleporter_explosion.sound =
{
  filename = path.."teleporter-explosion.ogg",
  volume = 1
}

local teleporter_explosion_2 = util.copy(teleporter_explosion)
teleporter_explosion_2.name = "teleporter-explosion-no-sound"
teleporter_explosion_2.sound = nil

local recipe = {
  type = "recipe",
  name = name,
  localised_name = localised_name,
  enabled = false,
  ingredients =
  {
    {"steel-plate", 45},
    {"advanced-circuit", 20},
    {"battery", 25},
  },
  energy_required = 5,
  result = name
}

local technology =
{
  type = "technology",
  name = name,
  localised_name = localised_name,
  localised_description = "",
  icon_size = teleporter_item.icon_size,
  icon = teleporter_item.icon,
  effects =
  {
    {
      type = "unlock-recipe",
      recipe = name
    }
  },
  unit =
  {
    count = 500,
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
    },
    time = 30
  },
  prerequisites = {"advanced-electronics", "battery"},
  order = "y-a"
}

local teleporter_flying_text = util.copy(data.raw["flying-text"]["tutorial-flying-text"])
teleporter_flying_text.name = "teleporter-flying-text"

local hotkey_name = require"shared".hotkeys.focus_search
local hotkey =
{
  type = "custom-input",
  name = hotkey_name,
  linked_game_control = "focus-search",
  key_sequence = "Control + F"
}

data:extend
{
  teleporter,
  teleporter_item,
  teleporter_explosion,
  teleporter_explosion_2,
  recipe,
  technology,
  teleporter_flying_text,
  hotkey
}

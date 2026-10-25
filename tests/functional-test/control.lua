-- Functional test for configurable-scrap-recycling, run by tools/load_check.py --test-mod tests/functional-test.
-- 1. The scrap-recycling recipe has exactly one product per configured output, with a chance equal to its
--    setting (shared ranges while the total is <= 100%).
-- 2. Recyclers really recycle scrap: N scrap give every output within 6 standard deviations of its chance.
-- Writes "[functional-test] PASS|FAIL ..." and ends with DONE.

local outputs = require("__configurable-scrap-recycling__.csr-outputs")

local TAG = "[functional-test] "
local START = 10
local RECYCLERS = 25 -- 5 x 5 grid
local SCRAP_EACH = 40 -- fits the recycler's input slot
-- scrap-recycling: 0.2 s at recycler speed 0.5 = 24 ticks per scrap
local CHECK = START + SCRAP_EACH * 24 + 300

local function pass(msg) log(TAG .. "PASS " .. msg) end
local function fail(msg) log(TAG .. "FAIL " .. msg) end

local function chance_of(product)
  local sp = product.shared_probability
  if sp then return (sp.max or 0) - (sp.min or 0) end
  if product.independent_probability then return product.independent_probability end
  return product.probability or 1
end

local recyclers = {}
local total_scrap = 0

local function check_recipe()
  local recipe = prototypes.recipe["scrap-recycling"]
  if not recipe then fail("recipe scrap-recycling missing") return false end
  local by_name = {}
  for _, p in pairs(recipe.products) do by_name[p.name] = p end
  local ok = true
  for _, o in ipairs(outputs) do
    local want = settings.startup["csr-chance-" .. o.name].value / 100
    local p = by_name[o.name]
    if want == 0 then
      if p then fail(o.name .. ": chance 0 but still a product") ok = false end
    elseif not p then
      fail(o.name .. ": missing from the recipe") ok = false
    elseif math.abs(chance_of(p) - want) > 1e-6 then
      fail(string.format("%s: chance %.4f, setting %.4f", o.name, chance_of(p), want)) ok = false
    end
  end
  if ok then pass("recipe products match the settings (" .. #recipe.products .. " products)") end
  return true
end

local function setup()
  if not script.active_mods["space-age"] then
    pass("skipped: needs Space Age")
    log(TAG .. "DONE")
    return
  end
  if not check_recipe() then log(TAG .. "DONE") return end

  local surface = game.surfaces[1]
  local force = game.forces.player
  -- the recycler only accepts scrap once scrap-recycling is unlocked
  for _, tech in pairs(force.technologies) do
    for _, effect in pairs(tech.prototype.effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe == "scrap-recycling" then tech.researched = true end
    end
  end
  local area = {{-20, -20}, {20, 24}}
  for _, e in pairs(surface.find_entities_filtered{area = area}) do
    if e.valid and e.type ~= "character" then e.destroy() end
  end
  local tiles = {}
  for x = -20, 19 do for y = -20, 23 do tiles[#tiles + 1] = {name = "lab-dark-1", position = {x, y}} end end
  surface.set_tiles(tiles)
  local eei = surface.create_entity{name = "electric-energy-interface", position = {-17, 21}, force = force}
  eei.electric_buffer_size = 1e10
  eei.power_production = 1e9
  eei.energy = 1e10
  surface.create_entity{name = "substation", position = {-17, 18}, force = force}
  for i = 1, RECYCLERS do
    local col, row = (i - 1) % 5, math.floor((i - 1) / 5)
    local x, y = -14 + col * 7, -16 + row * 7
    surface.create_entity{name = "substation", position = {x + 3, y + 3}, force = force}
    local r = surface.create_entity{name = "recycler", position = {x, y}, force = force}
    local inserted = r.insert{name = "scrap", count = SCRAP_EACH}
    if inserted ~= SCRAP_EACH then fail("recycler accepted only " .. inserted .. " scrap") end
    total_scrap = total_scrap + inserted
    recyclers[#recyclers + 1] = r
  end
end

local function check()
  local n = total_scrap
  local counts, left = {}, 0
  for _, r in ipairs(recyclers) do
    left = left + r.get_item_count("scrap")
    for _, item in pairs(r.get_inventory(defines.inventory.crafter_output).get_contents()) do
      counts[item.name] = (counts[item.name] or 0) + item.count
    end
  end
  if left > 0 then fail(left .. " scrap not recycled after " .. (CHECK - START) .. " ticks") end
  local recipe = prototypes.recipe["scrap-recycling"]
  for _, p in pairs(recipe.products) do
    local chance = chance_of(p)
    local amount = p.amount or 1
    local expected = n * chance * amount
    local sd = math.sqrt(n * chance * (1 - chance)) * amount
    local got = counts[p.name] or 0
    if math.abs(got - expected) > 6 * sd + 1 then
      fail(string.format("%s: %d from %d scrap, expected %.1f +- %.1f", p.name, got, n, expected, 6 * sd))
    else
      pass(string.format("%s: %d from %d scrap (expected %.1f)", p.name, got, n, expected))
    end
  end
  log(TAG .. "DONE")
end

script.on_nth_tick(START, function(e) if e.tick == START then setup() end end)
script.on_nth_tick(CHECK, function(e) if e.tick == CHECK and #recyclers > 0 then check() end end)

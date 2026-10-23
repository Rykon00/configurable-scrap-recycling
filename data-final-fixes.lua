--------------------------------------------------------------------------------
-- configurable-scrap-recycling  |  data-final-fixes.lua
--
-- Replaces the drop chances of the "scrap-recycling" recipe (Fulgora) with the
-- values from the startup settings.
--
-- HOW DO PRODUCT CHANCES WORK IN FACTORIO 2.1?
--   Since 2.1 the vanilla recipe uses `shared_probability`: one roll in [0, 1)
--   per scrap, and every output owns a range {min, max} of that roll. The
--   ranges do not overlap, so one scrap yields at most one item, and the chance
--   of an output is the width of its range (vanilla total: 0.60).
--   2.0 rolled every output independently (`probability`, renamed to
--   `independent_probability` in 2.1).
--
--   This mod keeps the chance of every output exactly at its setting:
--     * all chances add up to 100% or less: consecutive shared ranges in recipe
--       order, like vanilla (at most one item per scrap). The defaults give the
--       vanilla recipe.
--     * the sum is above 100%: shared ranges cannot express that, so every
--       output is rolled independently (one scrap can yield several items).
--
-- EXPECTED VALUE
--   Expected items per scrap = sum of all chances. Vanilla: 0.60.
--   The sum is written to the log (factorio-current.log).
--------------------------------------------------------------------------------

local outputs = require("csr-outputs")

local recipe = data.raw.recipe["scrap-recycling"]
if not recipe then
  -- Space Age is missing or another mod removed the recipe: nothing to do.
  return
end

-- Step 1: read the settings and turn them into chances (0.0 - 1.0).
-- The settings already have min 0 / max 100; math.max/min are only a safety net.
local chance_by_item = {}
for _, entry in ipairs(outputs) do
  local percent = settings.startup["csr-chance-" .. entry.name].value
  percent = math.max(0, math.min(100, percent))
  chance_by_item[entry.name] = percent / 100
end

-- Step 2: collect the managed results. Ingredients, time and categories stay
-- untouched; only `results` is changed. Results of other mods are kept as they are.
local new_results = {}
local managed = {}
local total = 0

for _, result in ipairs(recipe.results or {}) do
  local chance = (result.type == nil or result.type == "item") and chance_by_item[result.name] or nil

  if chance == nil then
    table.insert(new_results, result)
  elseif chance > 0 then
    -- Managed result: only the chance fields are replaced. All other fields
    -- (amount, show_details_in_recipe_tooltip, ...) are kept.
    table.insert(new_results, result)
    table.insert(managed, {result = result, chance = chance})
    total = total + chance
  end
  -- chance == 0: the result is left out (chance 0 = never happens).
end

-- Step 3: write the chances.
local shared = total <= 1 + 1e-9
local start = 0
local expected_items = 0
for _, m in ipairs(managed) do
  local result = m.result
  result.probability = nil
  if shared then
    result.independent_probability = nil
    result.shared_probability = {min = start, max = math.min(1, start + m.chance)}
    start = start + m.chance
  else
    result.shared_probability = nil
    result.independent_probability = m.chance
  end
  expected_items = expected_items + m.chance * (result.amount or 1)
end

recipe.results = new_results

log(string.format(
  "[configurable-scrap-recycling] %d outputs remain, %s rolls, expected items per scrap: %.4f (vanilla: 0.6000)",
  #new_results, shared and "shared" or "independent", expected_items))

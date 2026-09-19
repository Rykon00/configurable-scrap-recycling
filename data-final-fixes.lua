--------------------------------------------------------------------------------
-- configurable-scrap-recycling  |  data-final-fixes.lua
--
-- Überschreibt die Drop-Chancen im Rezept "scrap-recycling" (Fulgora) mit den
-- Werten aus den Startup-Settings.
--
-- WIE FUNKTIONIERT DIE WAHRSCHEINLICHKEIT IN DIESER FACTORIO-VERSION?
--   Im echten Rezept (Factorio 2.0.77, space-age/prototypes/recipe.lua) hat
--   jedes Ergebnis ein eigenes Feld `probability` (0.0 - 1.0). Bei jedem
--   recycelten Schrott wird JEDES Ergebnis UNABHÄNGIG gewürfelt:
--     * ein Schrott kann 0, 1 oder auch mehrere verschiedene Items liefern,
--     * die Chancen müssen sich NICHT zu 1.0 aufsummieren,
--     * es gibt keine "Chance auf nichts" als eigenen Eintrag - "nichts" ist
--       einfach der Fall, dass alle Würfe fehlschlagen.
--   Deshalb ist hier KEINE Normalisierung nötig: Der Prozentwert aus dem
--   Setting wird direkt durch 100 geteilt und als `probability` eingetragen.
--   (Ein `shared_probability`-System mit min/max-Bereichen existiert in den
--   installierten Dateien nicht; siehe README.)
--
-- ERWARTUNGSWERT
--   Erwartete Items pro Schrott = Summe aller Einzelchancen. Vanilla: 0.60.
--   Diese Summe wird am Ende ins Log (factorio-current.log) geschrieben.
--------------------------------------------------------------------------------

local outputs = require("csr-outputs")

local recipe = data.raw.recipe["scrap-recycling"]
if not recipe then
  -- Space Age fehlt oder ein anderes Mod hat das Rezept entfernt: nichts zu tun.
  return
end

-- Schritt 1: Settings einlesen und in Wahrscheinlichkeiten (0.0 - 1.0) umrechnen.
-- Das Setting hat bereits min 0 / max 100; math.max/min sind nur ein Sicherheitsnetz.
local chance_by_item = {}
for _, entry in ipairs(outputs) do
  local percent = settings.startup["csr-chance-" .. entry.name].value
  percent = math.max(0, math.min(100, percent))
  chance_by_item[entry.name] = percent / 100
end

-- Schritt 2: Das results-Array neu aufbauen. Ingredients, Zeit und Kategorie
-- bleiben unangetastet; wir ändern ausschließlich `results`.
local new_results = {}
local expected_items = 0

for _, result in ipairs(recipe.results or {}) do
  local chance = (result.type == nil or result.type == "item") and chance_by_item[result.name] or nil

  if chance == nil then
    -- Ergebnis, das nicht von dieser Mod verwaltet wird (z. B. von einer anderen
    -- Mod hinzugefügt): unverändert übernehmen.
    table.insert(new_results, result)
  elseif chance > 0 then
    -- Verwaltetes Ergebnis: nur die Wahrscheinlichkeit ersetzen. Alle anderen
    -- Felder (amount, show_details_in_recipe_tooltip, ...) bleiben erhalten.
    result.probability = chance
    table.insert(new_results, result)
    expected_items = expected_items + chance * (result.amount or 1)
  end
  -- chance == 0: Ergebnis wird bewusst weggelassen (Chance 0 = kommt nie vor).
end

recipe.results = new_results

log(string.format(
  "[configurable-scrap-recycling] %d outputs remain, expected items per scrap: %.4f (vanilla: 0.6000)",
  #new_results, expected_items))

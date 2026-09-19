local outputs = require("csr-outputs")

-- Ein Startup-Setting pro Output. Startup, weil Rezepte nur in der Data-Stage
-- geändert werden können. Wert = Chance in Prozent pro recyceltem Schrott.
for index, entry in ipairs(outputs) do
  data:extend({
    {
      type = "double-setting",
      name = "csr-chance-" .. entry.name,
      setting_type = "startup",
      default_value = entry.vanilla_percent,
      minimum_value = 0,
      maximum_value = 100,
      order = string.format("a-%02d", index),
    },
  })
end

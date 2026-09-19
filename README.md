# Configurable Scrap Recycling

Lets you set the drop chance of every possible output of the Space Age recipe
`scrap-recycling` (Fulgora) individually, via startup settings.

## Settings

One startup setting per output (`csr-chance-<item>`), in percent, 0-100.
Defaults are the vanilla values (Factorio 2.0.77):

| Output | Vanilla % | Output | Vanilla % |
|---|---|---|---|
| Iron gear wheel | 20 | Stone | 4 |
| Solid fuel | 7 | Advanced circuit | 3 |
| Concrete | 6 | Copper cable | 3 |
| Ice | 5 | Processing unit | 2 |
| Steel plate | 4 | Low density structure | 1 |
| Battery | 4 | Holmium ore | 1 |

Vanilla total: 0.60 expected items per scrap.

Each output is rolled independently (this is how the recipe works in
Factorio 2.0.x), so the chances do not have to add up to 100% and one scrap can
yield several items. Setting a chance to 0 removes that output.

Only the `results` of `scrap-recycling` are changed. Outputs added by other mods
are kept as they are. Because the change happens in `data-final-fixes`, another
mod that rewrites this recipe in the same stage and loads later will override it.

## Compatibility

Requires Factorio 2.0 and Space Age. Compatible with `adjustable_recycler`
(that mod only touches recipes of category `recycling`).

## Packaging

The mod folder must be named `configurable-scrap-recycling_1.0.0`. For the mod
portal, zip that folder (the folder itself must be the top-level entry) and add
a 144x144 `thumbnail.png`.

# Configurable Scrap Recycling

Lets you set the drop chance of every possible output of the Space Age recipe
`scrap-recycling` (Fulgora) individually, via startup settings.

## Settings

One startup setting per output (`csr-chance-<item>`), in percent, 0-100.
Defaults are the vanilla values (Factorio 2.1.23, same as 2.0.77):

| Output | Vanilla % | Output | Vanilla % |
|---|---|---|---|
| Iron gear wheel | 20 | Stone | 4 |
| Solid fuel | 7 | Advanced circuit | 3 |
| Concrete | 6 | Copper cable | 3 |
| Ice | 5 | Processing unit | 2 |
| Steel plate | 4 | Low density structure | 1 |
| Battery | 4 | Holmium ore | 1 |

Vanilla total: 0.60 expected items per scrap.

Since Factorio 2.1 the vanilla recipe rolls once per scrap and gives at most
one item (`shared_probability` ranges). The mod keeps that while all chances add
up to 100% or less: each output gets a range as wide as its chance, in recipe
order. Above 100% in total the ranges cannot work, so every output is rolled
independently (`independent_probability`) and one scrap can yield several items.
Either way, the chance of each output is exactly its setting. Setting a chance
to 0 removes that output.

Only the `results` of `scrap-recycling` are changed. Outputs added by other mods
are kept as they are. Because the change happens in `data-final-fixes`, another
mod that rewrites this recipe in the same stage and loads later will override it.

## Compatibility

Requires Factorio 2.1 and Space Age. Compatible with `adjustable_recycler`
(that mod only touches recipes of category `recycling`).

## Packaging

The mod folder must be named `configurable-scrap-recycling_1.1.0`. For the mod
portal, zip that folder (the folder itself must be the top-level entry) and add
a 144x144 `thumbnail.png`.

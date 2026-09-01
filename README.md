# Shulker Box Uncrafting

This datapack adds one recipe: uncraft an empty shulker box to get its chest and two shells back.

## What it does

Put one empty shulker box in a player crafting grid:

| Input | Crafted result | Also returned |
| --- | --- | --- |
| 1 empty shulker box | 2 shulker shells | 1 chest |

- The undyed box and all 16 dyed variants are supported.
- The box must be completely empty.
- Some boxes from custom maps, commands, or mods create their contents the first time they are opened. Open and empty those boxes before trying to uncraft them.
- Renamed boxes and boxes with other data are accepted, but that extra data is not preserved when the box is uncrafted.
- The dye is not returned. The recipe gives back only the chest and two shells used to craft the box.

When this recipe is used in a Crafter, the chest comes out through the Crafter's front with the shells instead of staying in its inventory.

## Requirements

Install these on the server:

- Minecraft `26.2`
- Fabric Loader
- Fabric API `0.158.0+26.2` or a compatible newer build
- Recipe Remainders

Vanilla Minecraft 26.2 clients can join without installing Fabric Loader, Fabric API, or Recipe Remainders. Installing Fabric API and Recipe Remainders on a client is optional, but it makes the returned chest appear immediately and lets the recipe book tell empty and filled shulker boxes apart.

This datapack does not work on a vanilla server. Fabric API and Recipe Remainders are required on the server.

## Installation

1. Copy the entire `shulker-box-uncrafting` folder into the world's `datapacks` folder:

   ```text
   <world>/datapacks/shulker-box-uncrafting/
   ```

   `pack.mcmeta` must be directly inside that folder. If you install a ZIP instead, `pack.mcmeta` must be at the root of the ZIP rather than inside another wrapper folder.

2. Restart the server, or run:

   ```mcfunction
   /reload
   ```

3. Confirm that Minecraft lists the pack as enabled:

   ```mcfunction
   /datapack list enabled
   ```

The recipe unlocks automatically when a player has any shulker-box variant in their inventory. To grant it manually for testing, run:

```mcfunction
/recipe give @s shulker_box_uncrafting:empty_shulker_box_to_shells
```

## Recipe-book behavior

Recipe-book autofill is handled by the server, which moves only an empty shulker box into the crafting grid.

On a vanilla client, the recipe book may still highlight a filled box because the client recognizes the shulker box but does not check everything stored on it. Clicking the recipe remains safe: the server refuses filled boxes. Installing Recipe Remainders on the client fixes the highlight and makes the returned chest appear without a brief delay.

## If the mod is removed

The recipe and its recipe-book unlock both include a Fabric check. If Fabric API is installed but Recipe Remainders is not, Fabric ignores them and the pack adds no recipe.

A fully vanilla server cannot read the Fabric-only fields used by this pack. Remove or disable the pack before moving the world to a vanilla server. The recipe will fail to load; it cannot fall back to a version that consumes the box without returning the chest.

## Troubleshooting

- **The pack is missing from `/datapack list`:** check that `pack.mcmeta` is at the folder or ZIP root.
- **The recipe is missing:** verify the server has Fabric API and Recipe Remainders, run `/reload`, then use the `/recipe give` command above.
- **The server reports an unknown `fabric:type`:** Fabric API or Recipe Remainders is missing or incompatible with this Minecraft version.
- **A shulker box will not uncraft:** remove every item from it. Some boxes made by maps, commands, or mods generate their contents the first time they are opened. Place and open the box, remove anything that appears, then pick it back up and try again.
- **The chest briefly disappears on the client:** install Fabric API and Recipe Remainders on that client so the chest appears immediately.

## Contents

```text
shulker-box-uncrafting/
|-- pack.mcmeta
|-- pack.png
|-- README.md
`-- data/shulker_box_uncrafting/
    |-- advancement/recipes/decorations/empty_shulker_box_to_shells.json
    `-- recipe/empty_shulker_box_to_shells.json
```

The recipe ID is `shulker_box_uncrafting:empty_shulker_box_to_shells`.

Minecraft uses `pack.png` as the pack's icon.

## License

This datapack is part of Recipe Remainders and is licensed under `GPL-3.0-only`. The repository contains the complete `LICENSE`, and ZIPs made by the included Gradle packaging task contain it as `LICENSE.txt`.

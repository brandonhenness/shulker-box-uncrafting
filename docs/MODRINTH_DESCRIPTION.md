# Shulker Box Uncrafting

> ## IMPORTANT: REQUIRED MOD
>
> **[Recipe Remainders](https://modrinth.com/mod/recipe-remainders) is required for this datapack to work.** Install it on the server, or in the client installation for singleplayer, before using this datapack. The datapack will not work without it.

Turn an empty shulker box back into the chest and two shells used to craft it.

![An empty shulker box being uncrafted into two shells while its chest returns to the crafting grid](https://raw.githubusercontent.com/brandonhenness/shulker-box-uncrafting/refs/heads/main/.github/assets/shulker-box-uncrafting-demo.gif)

Put any empty shulker box in a player crafting grid or crafting table. The recipe produces two shulker shells and returns one chest to the input slot.

## What it supports

- The undyed shulker box and all 16 dyed variants
- Player crafting grids and crafting tables
- Recipe-book autofill that leaves filled boxes alone
- Crafter blocks, which dispense the chest with the shells
- Vanilla clients connecting to the Fabric server

The box must be empty. Boxes that contain items, including boxes that have not generated their contents yet, are rejected. Custom names and other data do not prevent crafting, but they are not kept after the box is uncrafted. Dye is not returned.

## Requirements

The server needs:

- Minecraft 26.2
- Fabric Loader 0.19.3 or a compatible newer version
- [Fabric API](https://modrinth.com/mod/fabric-api) 0.158.0+26.2 or newer for Minecraft 26.2
- [Recipe Remainders](https://modrinth.com/mod/recipe-remainders) 0.1.0 or a compatible newer version

Recipe Remainders and Fabric API are required on the server. This datapack does not work on a vanilla server.

If Recipe Remainders is missing from the server, joining players receive a one-time warning. Players do not need the mod on their clients; the warning checks the server installation.

Vanilla Minecraft 26.2 clients can connect without installing Fabric Loader, Fabric API, or Recipe Remainders. Installing Fabric API and Recipe Remainders on a Fabric client is optional. The optional client installation makes the returned chest appear immediately and lets the recipe book distinguish empty boxes from filled ones.

For singleplayer, install both mods in the client installation because the integrated server loads the recipe.

## Installation

1. Install Fabric Loader, Fabric API, and Recipe Remainders on the server, or in the client installation for singleplayer.
2. Download the datapack ZIP from the Versions tab.
3. Put the ZIP in the world's `datapacks` folder without extracting it.
4. Restart the server, or run `/reload`.
5. Run `/datapack list enabled` to confirm the pack loaded.

The recipe unlocks when a player obtains any shulker-box variant. For testing, it can also be granted with:

```mcfunction
/recipe give @s shulker_box_uncrafting:empty_shulker_box_to_shells
```

## Client behavior

The server always decides whether the recipe matches, so a filled box cannot be uncrafted by a vanilla client. A vanilla client's recipe book may briefly show the recipe as available while the player has only a filled box, and the chest can appear one update late after crafting. Both are display differences; the items remain safe.

Installing Recipe Remainders and Fabric API on that client corrects the recipe-book highlight and shows the chest immediately.

## Source and support

The [source code, documentation, issue tracker, and GPL-3.0-only license](https://github.com/brandonhenness/shulker-box-uncrafting) are available on GitHub.

Shulker Box Uncrafting is a separate datapack made for [Recipe Remainders](https://github.com/brandonhenness/recipe-remainders). Installing Recipe Remainders by itself does not add this recipe.

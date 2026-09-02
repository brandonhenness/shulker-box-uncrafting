# Contributing to Shulker Box Uncrafting

Bug reports and small, focused improvements are welcome.

## Reporting a problem

Use the [bug report form](https://github.com/brandonhenness/shulker-box-uncrafting/issues/new?template=bug_report.yml) and include:

- Minecraft, Fabric Loader, Fabric API, Recipe Remainders, and datapack versions;
- whether the server is dedicated or singleplayer;
- whether the client is vanilla or Fabric;
- the steps that reproduce the problem; and
- the relevant part of the server log, if Minecraft reported a loading error.

Before opening an issue, confirm that the box is empty and that the datapack appears in `/datapack list enabled`.

## Making a change

1. Fork the repository and create a branch for your change.
2. Keep `pack.mcmeta` and `data/` at the repository root. Their paths also become the paths at the root of the release ZIP.
3. Use two-space indentation in JSON and keep files encoded as UTF-8.
4. Test the pack on Minecraft 26.2 with compatible versions of Fabric API and Recipe Remainders.
5. Run the local validator and packager:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -OutputDirectory dist
   ```

   On Linux or macOS with PowerShell 7, use `pwsh -File ./scripts/build.ps1 -OutputDirectory dist`.

6. Run `/reload`, check the server log for errors, and test both an empty and a filled shulker box.
7. Open a pull request explaining what changed and how you tested it.

If your change affects compatibility or player-visible behavior, update the README and changelog in the same pull request.

## Useful test cases

At minimum, verify that:

- the undyed box and each dyed variant can be uncrafted while empty;
- the result is two shells and the returned item is one chest;
- a box containing an item is rejected;
- a box whose contents have not been generated yet is rejected;
- recipe-book autofill leaves a filled box alone;
- the recipe works in a player grid, crafting table, and Crafter; and
- a vanilla 26.2 client can connect to the Fabric server and craft safely.

Installing Recipe Remainders on the test client is optional, but testing once with it and once without it helps catch client-display problems.

## License

Contributions must be original or appropriately licensed. By submitting a contribution, you agree that it may be distributed under the repository's [GPL-3.0-only license](LICENSE).

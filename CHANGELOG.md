# Changelog

All notable changes to Shulker Box Uncrafting are documented here.

## [1.0.0] - 2026-09-01

First stable release for Minecraft 26.2.

### Added

- A shapeless recipe that turns an empty shulker box into two shulker shells and returns one chest.
- Support for the undyed shulker box and all 16 dyed variants.
- Checks that reject boxes containing items and boxes that have not generated their contents yet.
- A recipe-book unlock for players who obtain any shulker-box variant.
- Safe loading behavior when Recipe Remainders is not installed on a Fabric server.
- Support for vanilla clients connecting to a compatible Fabric server.
- Optional client-side integration with Recipe Remainders for immediate remainder display and accurate recipe-book highlighting.

### Requirements

- Minecraft `26.2`
- Fabric Loader `0.19.3` or a compatible newer version on the server
- Fabric API `0.158.0+26.2` or newer for Minecraft 26.2 on the server
- Recipe Remainders `0.1.0` or a compatible newer version on the server

[1.0.0]: https://github.com/brandonhenness/shulker-box-uncrafting/releases/tag/v1.0.0

# Releasing Shulker Box Uncrafting

This guide is for project maintainers. Releases are published from an annotated Git tag after the matching commit is on `main`.

## One-time repository setup

Add the following under **Settings > Secrets and variables > Actions**:

- Secret `MODRINTH_TOKEN`: a Modrinth personal access token with **Read projects**, **Read versions**, and **Create versions** permissions.
- Variable `MODRINTH_PROJECT_ID`: the permanent eight-character ID of the Shulker Box Uncrafting project.
- Variable `RECIPE_REMAINDERS_PROJECT_ID`: the permanent eight-character ID of the Recipe Remainders project.

The release workflow uses Fabric API's Modrinth project ID directly and declares both Fabric API and Recipe Remainders as required dependencies.

## Prepare a release

1. Update `version` and `minecraft_version` in `release.properties`.
2. Add a changelog heading in this exact form:

   ```markdown
   ## [0.1.0] - 2026-09-02
   ```

3. Confirm that the dependency versions in `README.md` and `docs/MODRINTH_DESCRIPTION.md` are still correct.
4. Test empty, filled, dyed, and undyed boxes on the supported Minecraft version.
5. Confirm that a vanilla client can connect to the Fabric server and use the recipe.
6. Build and validate the exact release archive locally:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -OutputDirectory dist
   ```

7. Push the release commit to `main` and wait for the normal validation workflow to pass.

## Publish

Replace `0.1.0` below with the version from `release.properties`:

```powershell
git tag -a v0.1.0 -m "Shulker Box Uncrafting 0.1.0"
git push origin v0.1.0
```

The tag must be named `vX.Y.Z`, match `release.properties`, point to a commit contained in `main`, and have a matching dated changelog section.

The release workflow then:

1. validates the pack and builds `shulker-box-uncrafting-X.Y.Z+mc26.2.zip`;
2. verifies that `pack.mcmeta`, `pack.png`, and `data/` are at the ZIP root;
3. creates checksums in `SHA256SUMS`;
4. creates or verifies a stable Modrinth version using the `datapack` loader;
5. declares Recipe Remainders and Fabric API as required dependencies; and
6. publishes the matching GitHub release with the ZIP and checksums attached.

The GitHub release begins as a draft so a failed Modrinth publication does not leave a partial public release. The workflow is designed to recognize a matching release if it is run again.

## Verify the release

- Download the attached ZIP from GitHub and confirm `pack.mcmeta` is at its root.
- Check that the Modrinth version is marked as a normal release, not alpha or beta.
- Confirm that Minecraft 26.2 and the `datapack` loader are listed.
- Confirm that Recipe Remainders and Fabric API appear as required dependencies.
- Install the downloaded ZIP in a clean test world and run `/datapack list enabled`.

GitHub's automatic Source code archives are not datapack downloads. Direct users to the attached release ZIP or Modrinth.

## Fixing a failed release

Read the failed workflow step before changing the tag. If nothing was published, fix the repository, delete the local and remote tag, recreate it on the corrected commit, and push it again:

```powershell
git tag -d v0.1.0
git push origin :refs/tags/v0.1.0
git tag -a v0.1.0 -m "Shulker Box Uncrafting 0.1.0"
git push origin v0.1.0
```

Do not move or reuse a tag after a GitHub or Modrinth release is public. Publish a new patch version instead.

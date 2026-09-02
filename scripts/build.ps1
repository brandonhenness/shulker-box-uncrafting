[CmdletBinding()]
param(
    [Parameter()]
    [string] $OutputDirectory = "dist"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$isWindowsPlatform = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
$pathComparison = if ($isWindowsPlatform) {
    [System.StringComparison]::OrdinalIgnoreCase
}
else {
    [System.StringComparison]::Ordinal
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-ReleaseProperties {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $properties = [ordered] @{}
    $lineNumber = 0

    foreach ($rawLine in [System.IO.File]::ReadAllLines($Path)) {
        $lineNumber++
        $line = $rawLine.Trim()
        if ($line.Length -eq 0 -or $line.StartsWith("#", [System.StringComparison]::Ordinal)) {
            continue
        }

        $separator = $line.IndexOf("=", [System.StringComparison]::Ordinal)
        if ($separator -le 0) {
            throw "Invalid release.properties entry on line ${lineNumber}: $rawLine"
        }

        $key = $line.Substring(0, $separator).Trim()
        $value = $line.Substring($separator + 1).Trim()
        if ($key.Length -eq 0 -or $value.Length -eq 0) {
            throw "release.properties line $lineNumber must contain a non-empty key and value."
        }

        if ($properties.Contains($key)) {
            throw "release.properties contains the key '$key' more than once."
        }

        $properties[$key] = $value
    }

    return $properties
}

function Read-JsonFile {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    try {
        return [System.IO.File]::ReadAllText($Path) | ConvertFrom-Json
    }
    catch {
        throw "Invalid JSON in '$Path': $($_.Exception.Message)"
    }
}

function Assert-JsonProperty {
    param(
        [Parameter(Mandatory)]
        [object] $Object,

        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Context
    )

    if ($null -eq $Object -or $Object.PSObject.Properties.Name -notcontains $Name) {
        throw "$Context is missing the '$Name' property."
    }
}

function Read-UInt32BigEndian {
    param(
        [Parameter(Mandatory)]
        [byte[]] $Bytes,

        [Parameter(Mandatory)]
        [int] $Offset
    )

    return [uint32] (
        ([uint32] $Bytes[$Offset] -shl 24) -bor
        ([uint32] $Bytes[$Offset + 1] -shl 16) -bor
        ([uint32] $Bytes[$Offset + 2] -shl 8) -bor
        [uint32] $Bytes[$Offset + 3]
    )
}

function Get-NormalizedRelativePath {
    param(
        [Parameter(Mandatory)]
        [string] $BasePath,

        [Parameter(Mandatory)]
        [string] $Path
    )

    $baseFullPath = [System.IO.Path]::GetFullPath($BasePath).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar
    $fullPath = [System.IO.Path]::GetFullPath($Path)

    if (-not $fullPath.StartsWith($baseFullPath, $script:pathComparison)) {
        throw "Path '$fullPath' is not inside '$baseFullPath'."
    }

    return $fullPath.Substring($baseFullPath.Length).Replace("\", "/")
}

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$propertiesPath = Join-Path $repositoryRoot "release.properties"
$packMetadataPath = Join-Path $repositoryRoot "pack.mcmeta"
$iconPath = Join-Path $repositoryRoot "pack.png"
$licensePath = Join-Path $repositoryRoot "LICENSE"
$dataPath = Join-Path $repositoryRoot "data"
$recipeRelativePath = "data/shulker_box_uncrafting/recipe/empty_shulker_box_to_shells.json"
$advancementRelativePath = "data/shulker_box_uncrafting/advancement/recipes/decorations/empty_shulker_box_to_shells.json"
$recipePath = Join-Path $repositoryRoot $recipeRelativePath
$advancementPath = Join-Path $repositoryRoot $advancementRelativePath

$requiredFiles = @(
    $propertiesPath,
    $packMetadataPath,
    $iconPath,
    $licensePath,
    $recipePath,
    $advancementPath
)

foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required file is missing: $requiredFile"
    }
}

if (-not (Test-Path -LiteralPath $dataPath -PathType Container)) {
    throw "The datapack data directory is missing: $dataPath"
}

$properties = Get-ReleaseProperties -Path $propertiesPath
$requiredPropertyNames = @("version", "release_type", "minecraft_version", "archive_name")
foreach ($propertyName in $requiredPropertyNames) {
    if (-not $properties.Contains($propertyName)) {
        throw "release.properties is missing '$propertyName'."
    }
}

$unexpectedPropertyNames = @($properties.Keys | Where-Object { $_ -notin $requiredPropertyNames })
if ($unexpectedPropertyNames.Count -gt 0) {
    throw "release.properties contains unexpected keys: $($unexpectedPropertyNames -join ', ')"
}

$version = [string] $properties["version"]
$releaseType = [string] $properties["release_type"]
$minecraftVersion = [string] $properties["minecraft_version"]
$archiveBaseName = [string] $properties["archive_name"]

if ($version -notmatch "^[0-9]+\.[0-9]+\.[0-9]+$") {
    throw "version must use X.Y.Z semantic versioning; found '$version'."
}

if ($releaseType -ne "release") {
    throw "release_type must be 'release' for this stable datapack; found '$releaseType'."
}

if ($minecraftVersion -notmatch "^[0-9]+(?:\.[0-9A-Za-z-]+)+$") {
    throw "minecraft_version contains an unexpected value: '$minecraftVersion'."
}

if ($archiveBaseName -notmatch "^[a-z0-9]+(?:-[a-z0-9]+)*$") {
    throw "archive_name must contain lowercase letters, numbers, and single hyphens; found '$archiveBaseName'."
}

$packMetadata = Read-JsonFile -Path $packMetadataPath
Assert-JsonProperty -Object $packMetadata -Name "pack" -Context "pack.mcmeta"
Assert-JsonProperty -Object $packMetadata.pack -Name "description" -Context "pack.mcmeta.pack"
Assert-JsonProperty -Object $packMetadata.pack -Name "min_format" -Context "pack.mcmeta.pack"
Assert-JsonProperty -Object $packMetadata.pack -Name "max_format" -Context "pack.mcmeta.pack"

$minimumFormats = @($packMetadata.pack.min_format)
if ($minimumFormats.Count -ne 2 -or [int] $minimumFormats[0] -ne 107 -or [int] $minimumFormats[1] -ne 1) {
    throw "pack.mcmeta min_format must be [107, 1] for Minecraft 26.2."
}

if ([int] $packMetadata.pack.max_format -ne 107) {
    throw "pack.mcmeta max_format must be 107 for Minecraft 26.2."
}

$jsonFiles = @(Get-ChildItem -LiteralPath $dataPath -Recurse -File -Filter "*.json" | Sort-Object FullName)
if ($jsonFiles.Count -eq 0) {
    throw "The datapack does not contain any JSON data files."
}

foreach ($jsonFile in $jsonFiles) {
    $null = Read-JsonFile -Path $jsonFile.FullName
}

$recipe = Read-JsonFile -Path $recipePath
Assert-JsonProperty -Object $recipe -Name "fabric:load_conditions" -Context $recipeRelativePath
Assert-JsonProperty -Object $recipe -Name "ingredients" -Context $recipeRelativePath
Assert-JsonProperty -Object $recipe -Name "result" -Context $recipeRelativePath

if ($recipe.'fabric:load_conditions'.condition -ne "fabric:all_mods_loaded" -or
    @($recipe.'fabric:load_conditions'.values) -notcontains "recipe_remainders") {
    throw "$recipeRelativePath must load only when Recipe Remainders is present."
}

if ($recipe.type -ne "minecraft:crafting_shapeless") {
    throw "$recipeRelativePath must use minecraft:crafting_shapeless."
}

$ingredients = @($recipe.ingredients)
if ($ingredients.Count -ne 1) {
    throw "$recipeRelativePath must contain exactly one ingredient."
}

$ingredient = $ingredients[0]
if ($ingredient.'fabric:type' -ne "recipe_remainders:with_remainder") {
    throw "$recipeRelativePath must use the Recipe Remainders ingredient wrapper."
}

Assert-JsonProperty -Object $ingredient -Name "base" -Context "$recipeRelativePath ingredient"
Assert-JsonProperty -Object $ingredient -Name "remainder" -Context "$recipeRelativePath ingredient"
if ($ingredient.remainder.id -ne "minecraft:chest") {
    throw "$recipeRelativePath must return a chest as its crafting remainder."
}

$baseIngredient = $ingredient.base
if ($baseIngredient.'fabric:type' -ne "fabric:components" -or
    $baseIngredient.base -ne "#minecraft:shulker_boxes") {
    throw "$recipeRelativePath must match shulker boxes with Fabric's component ingredient."
}

Assert-JsonProperty -Object $baseIngredient -Name "components" -Context "$recipeRelativePath base ingredient"
$componentNames = @($baseIngredient.components.PSObject.Properties.Name)
if ($componentNames -notcontains "minecraft:container" -or
    $componentNames -notcontains "!minecraft:container_loot") {
    throw "$recipeRelativePath must require an empty container and reject container loot."
}

if (@($baseIngredient.components.'minecraft:container').Count -ne 0) {
    throw "$recipeRelativePath must require an empty minecraft:container component."
}

$lootExclusion = $baseIngredient.components.'!minecraft:container_loot'
if ($null -eq $lootExclusion -or @($lootExclusion.PSObject.Properties).Count -ne 0) {
    throw "$recipeRelativePath must reject every minecraft:container_loot component."
}

if ($recipe.result.id -ne "minecraft:shulker_shell" -or [int] $recipe.result.count -ne 2) {
    throw "$recipeRelativePath must craft exactly two shulker shells."
}

$advancement = Read-JsonFile -Path $advancementPath
Assert-JsonProperty -Object $advancement -Name "fabric:load_conditions" -Context $advancementRelativePath
Assert-JsonProperty -Object $advancement -Name "rewards" -Context $advancementRelativePath
if ($advancement.'fabric:load_conditions'.condition -ne "fabric:all_mods_loaded" -or
    @($advancement.'fabric:load_conditions'.values) -notcontains "recipe_remainders") {
    throw "$advancementRelativePath must load only when Recipe Remainders is present."
}

$recipeIdentifier = "shulker_box_uncrafting:empty_shulker_box_to_shells"
if (@($advancement.rewards.recipes) -notcontains $recipeIdentifier) {
    throw "$advancementRelativePath must unlock $recipeIdentifier."
}

$iconBytes = [System.IO.File]::ReadAllBytes($iconPath)
$pngSignature = [byte[]] @(137, 80, 78, 71, 13, 10, 26, 10)
if ($iconBytes.Length -lt 24) {
    throw "pack.png is too small to be a valid PNG file."
}

for ($index = 0; $index -lt $pngSignature.Length; $index++) {
    if ($iconBytes[$index] -ne $pngSignature[$index]) {
        throw "pack.png does not have a valid PNG signature."
    }
}

if ([System.Text.Encoding]::ASCII.GetString($iconBytes, 12, 4) -ne "IHDR") {
    throw "pack.png does not begin with a PNG IHDR chunk."
}

if ((Read-UInt32BigEndian -Bytes $iconBytes -Offset 8) -ne 13) {
    throw "pack.png has an invalid PNG IHDR chunk length."
}

$iconWidth = Read-UInt32BigEndian -Bytes $iconBytes -Offset 16
$iconHeight = Read-UInt32BigEndian -Bytes $iconBytes -Offset 20
if ($iconWidth -ne 128 -or $iconHeight -ne 128) {
    throw "pack.png must be 128x128 pixels; found ${iconWidth}x${iconHeight}."
}

$pngEnd = [byte[]] @(0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130)
for ($index = 0; $index -lt $pngEnd.Length; $index++) {
    $iconOffset = $iconBytes.Length - $pngEnd.Length + $index
    if ($iconBytes[$iconOffset] -ne $pngEnd[$index]) {
        throw "pack.png does not end with a valid PNG IEND chunk."
    }
}

if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
}
else {
    $outputPath = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $OutputDirectory))
}

$null = New-Item -ItemType Directory -Path $outputPath -Force
$archiveFileName = "$archiveBaseName-$version+mc$minecraftVersion.zip"
$archivePath = Join-Path $outputPath $archiveFileName
$checksumPath = Join-Path $outputPath "SHA256SUMS"

$temporaryBasePath = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$temporaryPath = [System.IO.Path]::GetFullPath(
    (Join-Path $temporaryBasePath "$archiveBaseName-build-$([System.Guid]::NewGuid().ToString('N'))")
)
if (-not $temporaryPath.StartsWith($temporaryBasePath, $pathComparison)) {
    throw "Refusing to create a staging directory outside the system temporary directory."
}

try {
    $null = New-Item -ItemType Directory -Path $temporaryPath
    Copy-Item -LiteralPath $packMetadataPath -Destination (Join-Path $temporaryPath "pack.mcmeta")
    Copy-Item -LiteralPath $iconPath -Destination (Join-Path $temporaryPath "pack.png")
    Copy-Item -LiteralPath $licensePath -Destination (Join-Path $temporaryPath "LICENSE.txt")
    Copy-Item -LiteralPath $dataPath -Destination (Join-Path $temporaryPath "data") -Recurse

    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }

    $archiveStream = [System.IO.File]::Open(
        $archivePath,
        [System.IO.FileMode]::CreateNew,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::None
    )
    try {
        $archiveWriter = [System.IO.Compression.ZipArchive]::new(
            $archiveStream,
            [System.IO.Compression.ZipArchiveMode]::Create,
            $false
        )
        try {
            $stagedFiles = @(Get-ChildItem -LiteralPath $temporaryPath -Recurse -File | Sort-Object FullName)
            $entryTimestamp = [System.DateTimeOffset]::new(
                1980,
                1,
                1,
                0,
                0,
                0,
                [System.TimeSpan]::Zero
            )
            foreach ($stagedFile in $stagedFiles) {
                $entryName = Get-NormalizedRelativePath -BasePath $temporaryPath -Path $stagedFile.FullName
                $entry = $archiveWriter.CreateEntry(
                    $entryName,
                    [System.IO.Compression.CompressionLevel]::Optimal
                )
                $entry.LastWriteTime = $entryTimestamp

                $sourceStream = [System.IO.File]::OpenRead($stagedFile.FullName)
                $entryStream = $entry.Open()
                try {
                    $sourceStream.CopyTo($entryStream)
                }
                finally {
                    $entryStream.Dispose()
                    $sourceStream.Dispose()
                }
            }
        }
        finally {
            $archiveWriter.Dispose()
        }
    }
    finally {
        $archiveStream.Dispose()
    }

    $expectedArchiveEntries = @(
        "LICENSE.txt",
        "pack.mcmeta",
        "pack.png"
    ) + @(
        Get-ChildItem -LiteralPath $dataPath -Recurse -File |
            ForEach-Object { Get-NormalizedRelativePath -BasePath $repositoryRoot -Path $_.FullName }
    )
    $expectedArchiveEntries = @($expectedArchiveEntries | Sort-Object -Unique)

    $archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        $backslashEntries = @($archive.Entries | Where-Object { $_.FullName.Contains("\") })
        if ($backslashEntries.Count -gt 0) {
            throw "The generated ZIP contains Windows-style entry paths."
        }

        $archiveEntries = @(
            $archive.Entries |
                ForEach-Object { $_.FullName.Replace("\", "/") } |
                Where-Object { -not $_.EndsWith("/", [System.StringComparison]::Ordinal) } |
                Sort-Object -Unique
        )
    }
    finally {
        $archive.Dispose()
    }

    $entryDifferences = @(Compare-Object -ReferenceObject $expectedArchiveEntries -DifferenceObject $archiveEntries)
    if ($entryDifferences.Count -gt 0) {
        $differenceText = $entryDifferences | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" }
        throw "The generated ZIP has an unexpected layout:`n$($differenceText -join "`n")"
    }

    $archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    [System.IO.File]::WriteAllText(
        $checksumPath,
        "$archiveHash  $archiveFileName`n",
        [System.Text.UTF8Encoding]::new($false)
    )
}
finally {
    if (Test-Path -LiteralPath $temporaryPath -PathType Container) {
        $resolvedTemporaryPath = [System.IO.Path]::GetFullPath($temporaryPath)
        if (-not $resolvedTemporaryPath.StartsWith($temporaryBasePath, $pathComparison)) {
            throw "Refusing to remove a staging directory outside the system temporary directory."
        }

        Remove-Item -LiteralPath $resolvedTemporaryPath -Recurse -Force
    }
}

Write-Host "Validated $($jsonFiles.Count) datapack JSON files and a ${iconWidth}x${iconHeight} pack icon."
Write-Host "Created $archivePath"
Write-Host "Created $checksumPath"

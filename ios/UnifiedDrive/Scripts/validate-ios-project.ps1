param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

$projectFile = Join-Path $ProjectRoot "UnifiedDrive.xcodeproj\project.pbxproj"
$schemeFile = Join-Path $ProjectRoot "UnifiedDrive.xcodeproj\xcshareddata\xcschemes\UnifiedDrive.xcscheme"
$repoRoot = (Resolve-Path (Join-Path $ProjectRoot "..\..")).Path
$appetizeWorkflow = Join-Path $repoRoot ".github\workflows\build-appetize-simulator-zip.yml"
$ipaWorkflow = Join-Path $repoRoot ".github\workflows\build-unifieddrive-ipa.yml"
$sourceRoot = Join-Path $ProjectRoot "UnifiedDrive"
$plistFile = Join-Path $sourceRoot "Info.plist"
$assetsRoot = Join-Path $sourceRoot "Assets.xcassets"

if (-not (Test-Path $projectFile)) {
    throw "project.pbxproj non trovato: $projectFile"
}

if (-not (Test-Path $schemeFile)) {
    throw "Scheme Xcode condiviso non trovato: $schemeFile"
}

if (-not (Test-Path $appetizeWorkflow)) {
    throw "Workflow Appetize non trovato: $appetizeWorkflow"
}

if (-not (Test-Path $ipaWorkflow)) {
    throw "Workflow IPA non trovato: $ipaWorkflow"
}

if (-not (Test-Path $sourceRoot)) {
    throw "Sorgenti non trovati: $sourceRoot"
}

$pbx = Get-Content -Raw $projectFile
$declaredIds = [regex]::Matches($pbx, '(?m)^\s*([0-9A-F]{24})\s*/\*[^\r\n]*\*/\s*=\s*\{isa') |
    ForEach-Object { $_.Groups[1].Value }

$duplicateIds = $declaredIds | Group-Object | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name
if ($duplicateIds) {
    throw "ID PBX duplicati: $($duplicateIds -join ', ')"
}

$swiftFiles = Get-ChildItem -Path $sourceRoot -Recurse -Filter *.swift -File
foreach ($file in $swiftFiles) {
    if ($pbx -notmatch [regex]::Escape($file.Name)) {
        throw "File Swift non referenziato nel target: $($file.FullName)"
    }
}

$pbxSwiftRefs = [regex]::Matches($pbx, 'path = ([^;]+\.swift);') |
    ForEach-Object { $_.Groups[1].Value.Trim('"') }

foreach ($ref in $pbxSwiftRefs) {
    $found = Get-ChildItem -Path $sourceRoot -Recurse -Filter $ref -File
    if (-not $found) {
        throw "Riferimento PBX senza file su disco: $ref"
    }
}

[xml](Get-Content -Raw $plistFile) | Out-Null
[xml](Get-Content -Raw $schemeFile) | Out-Null

Get-ChildItem -Path $assetsRoot -Recurse -Filter Contents.json -File | ForEach-Object {
    Get-Content -Raw $_.FullName | ConvertFrom-Json | Out-Null
}

$forbidden = @(
    "<<<<<<<",
    ">>>>>>>",
    "ContentUnavailableView",
    "topBar",
    "@Observable",
    "extension URL",
    "buttonStyle(.glass)",
    "ASSETCATALOG_COMPILER_APPICON_NAME"
)

$textFiles = Get-ChildItem -Path $ProjectRoot -Recurse -File |
    Where-Object { $_.Extension -in ".swift", ".plist", ".pbxproj", ".md" }

foreach ($file in $textFiles) {
    $text = Get-Content -Raw $file.FullName
    foreach ($needle in $forbidden) {
        if ($text.Contains($needle)) {
            throw "Pattern vietato '$needle' trovato in $($file.FullName)"
        }
    }
}

Write-Host "UnifiedDrive iOS project validation OK"

Clear-Host
Write-Host "RaidCore publish script by Zeffuro"
Write-Host

Add-Type -assembly "System.IO.Compression.FileSystem"

$source = $PSScriptRoot
$dest = "..\$source"

$file = "$source\RaidCore.lua"
$match = (Get-Content $file) | Where-Object {$_ -match "local RAIDCORE_CURRENT_VERSION = `"(\d+.\d+.\d)`""}

Write-Host "Current RaidCore version is:" $matches[0]
$newversion = Read-Host "Please put in what version you want RaidCore to be at."

$addon_date_version = $Date = Get-Date -format "yyMMddHH"


(Get-Content $file) -replace("^local RAIDCORE_CURRENT_VERSION = `".*?`"$", "local RAIDCORE_CURRENT_VERSION = `"$newversion`"") | Set-Content "$source\RaidCore.lua"
(Get-Content $file) -replace("^local ADDON_DATE_VERSION = .*?$", "local ADDON_DATE_VERSION = $addon_date_version") | Set-Content "$source\RaidCore.lua"

[System.IO.Compression.ZipFile]::CreateFromDirectory($source, "..\Builds\RaidCore_$addon_date_version.zip") 

Read-Host 'Press Enter to continue...' | Out-Null
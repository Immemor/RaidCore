Function Upload-FTPFile ($Url, $Credentials, $Filepath) {
    $webclient = New-Object System.Net.WebClient
    $webclient.Credentials = $Credentials
    $file = Get-Item -Path $Filepath
    $uri = New-Object System.Uri($Url + $file.Name)
    Write-Host $uri
    $webclient.UploadFile($uri, $file)
}

Function Test-FTPConnection($url, $credentials){
    Try{
        $request = [Net.WebRequest]::Create($url)
        $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
        if ($credentials) {
            $request.Credentials = $credentials
        }
        $response = $request.GetResponse()
        return $true
    }
    Catch
    {
        return $false
    }
}

Clear-Host
Write-Host "RaidCore publish script by Zeffuro"
Write-Host

Add-Type -assembly "System.IO.Compression.FileSystem"

$source = $PSScriptRoot
$dest = "$source\RaidCore"
$buildpath = "$source\..\Builds\"

$params = @("/E")
$XD = @("RaidCore", ".git")
$XF = @("*.zip", "*.ps1", ".luacheckrc")

$file = "$source\RaidCore.lua"
$match = (Get-Content $file) | Where-Object {$_ -match "local RAIDCORE_CURRENT_VERSION = `"(\d+.\d+.\d)`""}

Write-Host "Current RaidCore version is:" $matches[0]
$newversion = Read-Host "Please put in what version you want RaidCore to be at."

$addon_date_version = $Date = Get-Date -format "yyMMddHH"
$zip_date_version = $Date = Get-Date -format "yyyyMMddHH"

$itemname = "$buildpath\RaidCore-Cupcakes-$zip_date_version.zip"

(Get-Content $file) -replace("^local RAIDCORE_CURRENT_VERSION = `".*?`"$", "local RAIDCORE_CURRENT_VERSION = `"$newversion`"") | Set-Content "$source\RaidCore.lua"
(Get-Content $file) -replace("^local ADDON_DATE_VERSION = .*?$", "local ADDON_DATE_VERSION = $addon_date_version") | Set-Content "$source\RaidCore.lua"

If(!(Test-Path $dest))
{
    New-Item -ItemType Directory -Force -Path $dest
}

robocopy.exe $source $dest @params /XD @XD /XF @XF

[System.IO.Compression.ZipFile]::CreateFromDirectory($dest, $itemname, "Fastest", $true)

Get-ChildItem -Path $dest -Recurse | Remove-Item -force -recurse
Remove-Item $dest -Force

$ftp = "ftp://raidcore.fakegaming.eu/httpdocs/builds/"
$user = "raidcore"
$pass = Read-Host "Please put in the password to upload RaidCore to the website"

$credentials = new-object System.Net.NetworkCredential($user, $pass)

While (-not (Test-FTPConnection -url $ftp -credentials $credentials)){
    $pass = Read-Host "Incorrect password, please try another password"
    $credentials = new-object System.Net.NetworkCredential($user, $pass)
}

Upload-FTPFile -Url $ftp -Credentials $credentials -Filepath $itemname
Write-Host "Upload should be successful, use the following url to distribute RaidCore: https://raidcore.fakegaming.eu/download.php"

Read-Host 'Press Enter to continue...' | Out-Null

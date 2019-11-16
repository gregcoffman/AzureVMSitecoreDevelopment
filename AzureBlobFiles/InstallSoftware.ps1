param(
    [String]$ChocoPackages,
    [String]$VmDownloadFolder,    
    [String]$RemoteDownloadPath,
    [String]$BaseFileUri,
    [String]$SCInstallRoot
)

$VmEventLogSource = "AzVMCustomScriptExtension"
$TdsUrl = "https://www.teamdevelopmentforsitecore.com/-/media/TDS/Files/TDS%20Downloads/TDS%206008.zip"
$TdsFileName = "Tds6008.zip"
$SitecorePSRepository = "https://sitecore.myget.org/F/sc-powershell/api/v2"
$SitecoreFileDlLoc = "Sitecore"
$SitecoreFiles = "createcert.json",`
                 "IdentityServer.json",`
                 "Prerequisites.json",`
                 "Sitecore 9.1.1 rev. 002459 (OnPrem)_single.scwdp.zip",`
                 "Sitecore 9.1.1 rev. 002459 (OnPrem)_xp0xconnect.scwdp.zip",`
                 "sitecore-solr.json",`
                 "sitecore-XP0.json",`
                 "Sitecore.IdentityServer 2.0.1 rev. 00166 (OnPrem)_identityserver.scwdp.zip",`
                 "xconnect-solr.json",`
                 "xconnect-xp0.json",`
                 "XP0-SingleDeveloper.json",`
                 "XP0-AzureVmSingleDeveloper.ps1"


$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"
$InformationPreference = "Continue"

$rootPath = Split-Path $MyInvocation.MyCommand.Path
. "$rootPath\SharedInstallFunctions.ps1"

Set-Log -Name $VmEventLogSource

Install-PackageProvider -Name NuGet -Force
Write-InformationLog -Message "Installed NuGet"

$AzModule = Get-InstalledModule Az -AllVersions -ErrorAction SilentlyContinue
if(!$SkipInstallAzModule -and [string]::IsNullOrEmpty($AzModule)) { 
        Install-Module -Name Az -AllowClobber -Force
    } 
else { Write-InformationLog -Message "Install AzModule Skipped." }

Import-Module Az

Write-InformationLog -Message "Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

$ChocoPackagesArr = Get-ChocoSplit -Packages $ChocoPackages

ForEach ($PackageName in $ChocoPackagesArr) {
    $PackageName = $PackageName.Replace("'","")
    Write-InformationLog -Message "Installing $PackageName"
    choco install $PackageName -y
    Write-InformationLog -Message "Installed $PackageName"
}

if (-not (Test-Path "$RemoteDownloadPath" -PathType Container)) {
	New-Item -Path "$RemoteDownloadPath" -ItemType Directory
	}

if (-not (Test-Path "$SCInstallRoot" -PathType Container)) {
	New-Item -Path "$SCInstallRoot" -ItemType Directory
	}

# Download TDS
Get-Download -FileUrl $TdsUrl -OutputFileName $TdsFileName -DownloadPath $RemoteDownloadPath
Write-InformationLog -Message "Downloaded TDS"

$sifmodule = Get-InstalledModule SitecoreInstallFramework -AllVersions -ErrorAction SilentlyContinue
if([string]::IsNullOrEmpty($SifModule)) {
    Register-PSRepository –Name SitecoreRepo –SourceLocation $SitecorePSRepository -InstallationPolicy Trusted
    Write-InformationLog -Message "Registered Sitecore Repo"

    Install-Module SitecoreInstallFramework -Force
    Write-InformationLog -Message "Installed SitecoreInstallationFramework"
}

Import-Module SitecoreInstallFramework
Write-InformationLog -Message "Imported Sitecore Instllation Framework"

#Download Sitecore Install Files
ForEach($file in $SitecoreFiles) {
    $FileUrl = "$BaseFileUri/$SitecoreFileDlLoc/$file"
    Get-Download -FileUrl "$BaseFileUri/$SitecoreFileDlLoc/$file" `
        -DownloadPath "$SCInstallRoot" `
        -OutputFileName $file
        Write-InformationLog -Message "Downloaded: $file"
}

exit
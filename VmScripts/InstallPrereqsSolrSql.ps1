param(
    [String]$SqlAdminPassword,
    [String]$VmDownloadPath
)

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"
$InformationPreference = "Continue"

$rootPath = Split-Path $MyInvocation.MyCommand.Path
. "$rootPath\SharedInstallFunctions.ps1"

Set-Log -Name "AzVMCustomScriptExtension"

Import-Module Az
Import-Module SitecoreInstallFramework
Write-InformationLog -Message "Imported Sitecore Instllation Framework"

#Install Prerequisites
Write-InformationLog -Message "Installing Prerequisites..."
Install-SitecoreConfiguration 'C:\VmSoftware\Sitecore\prerequisites.json' -Verbose
Write-InformationLog -Message "Installed Prerequisites"

#Install Solr
Write-InformationLog -Message "Installing Solr..."
. "$rootPath\InstallSolr.ps1"
Write-InformationLog -Message "Installed Solr"

#Install SQL
#TO DO: Considering adding a check for an currently undefined private blob storage with install files... 
#Would require providing VM access to a blob, but would likely improve speed significantly.  Download currently taking ~30 minutes.
$SqlInstallParams = @{
    SqlExpressDownload = "https://download.microsoft.com/download/4/1/A/41AD6EDE-9794-44E3-B3D5-A1AF62CD7A6F/sql16_sp2_dlc/en-us/SQLEXPR_x64_ENU.exe"
    SqlAdminPassword = $SqlAdminPassword
    TempLocation = $VmDownloadPath
    Path = "sqlexpress.json"
}
try {
    Write-InformationLog -Message "Installing MSSQL..."
    Install-SitecoreConfiguration @SqlInstallParams
    Write-InformationLog -Message "Installed MSSQL"
} catch [System.Data.SqlClient.SqlException] {
    if( $_.Exception.Number -eq 3021) {
        continue
    }
}
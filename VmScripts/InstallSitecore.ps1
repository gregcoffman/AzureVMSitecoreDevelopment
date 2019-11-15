param(
    [String]$Prefix,
    [String]$SitecoreAdminPassword,
    [String]$SCInstallRoot,
    [String]$XConnectSiteName,
    [String]$SitecoreSiteName,
    [String]$IdentityServerSiteName,
    [String]$LicenseFile,
    [String]$SolrUrl,
    [String]$SolrRoot,
    [String]$SolrService,
    [String]$SqlServer,
    [String]$SqlAdminUser,
    [String]$SqlAdminPassword,
    [String]$XConnectPackage,
    [String]$SitecorePackage,
    [String]$IdentityServerPackage,
    [String]$PasswordRecoveryUrl,
    [String]$SitecoreIdentityAuthority,
    [String]$XConnectCollectionService,
    [String]$ClientSecret,
    [String]$AllowedCorsOrigins,

    [Switch]$EnableCleanup = $true
)

$rootPath = Split-Path $MyInvocation.MyCommand.Path
. "$rootPath\SharedInstallFunctions.ps1"

$DeSCInstallRoot = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($SCInstallRoot))

#Install Sitecore
Write-InformationLog -Message "Installing Sitecore..."
. "$DeSCInstallRoot\XP0-AzureVmSingleDeveloper.ps1"
Write-InformationLog -Message "Installed Sitecore"

#Cleanup
if($EnableCleanup) {
    Write-InformationLog -Message "Disabling PSRemoting..."
    Disable-PSRemoting
    Write-InformationLog -Message "Deleting Firewall WinRM-HTTP Rule..."
    netsh advfirewall firewall delete rule name="WinRM-HTTP"
}

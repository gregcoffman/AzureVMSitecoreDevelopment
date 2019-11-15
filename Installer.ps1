#requires -RunAsAdministrator

$SubscriptionName = ""
$TenantId = "" 
$ResourceGroup = ""
$VmName = ""
$VmUsername = ""
$VmUserPassword = ConvertTo-SecureString "" -AsPlainText -Force
$Location = "eastus"
# Get a list of VM sizes: az vm list-skus --location eastus --output table
$VmSize = "Standard_B4ms" 
$ImageName = "Win2019Datacenter"
#Chcolatey Packages: https://chocolatey.org/packages
$ChocoPackages = "googlechrome,visualstudio2017community,git,notepadplusplus.install,scala"
$VmDownloadFolder = "VmSoftware"
$VmDownloadPath = "C:\$VmDownloadFolder\" 
#URL to Public Azure Blob Storage
$BaseFileUri = "https://<YourBlobName>.blob.core.windows.net/devvmfiles" #BLOB URL

#####################SITECORE VARIABLES #########################
# The Prefix that will be used on SOLR, Website and Database instances.
$Prefix = "sitecore"
# The Password for the Sitecore Admin User. This will be regenerated if left on the default.
$SitecoreAdminPassword = "b"
# The root folder with the license file and WDP files.
$SCInstallRoot = $VmDownloadPath + "Sitecore\"
# The name for the XConnect service.
$XConnectSiteName = "$prefix.xconnect"
# The Sitecore site instance name.
$SitecoreSiteName = "$prefix.sc"
# Identity Server site name
$IdentityServerSiteName = "$prefix.identityserver"
# The Path to the license file
$LicenseFile = $SCInstallRoot + "license.xml"
# The URL of the Solr Server
$SolrUrl = "https://localhost:8750/solr"
# The Folder that Solr has been installed to.
$SolrRoot = "C:\solr721"
# The Name of the Solr Service.
$SolrService = "solr-7.2.1"
# The DNS name or IP of the SQL Instance.
$SqlServer = "localhost"
# A SQL user with sysadmin privileges.
$SqlAdminUser = "sa"
# The password for $SQLAdminUser.
$SqlAdminPassword = ""
# The path to the XConnect Package to Deploy.
$XConnectPackage = $SCInstallRoot + "Sitecore 9.1.1 rev. 002459 (OnPrem)_xp0xconnect.scwdp.zip"
# The path to the Sitecore Package to Deploy.
$SitecorePackage = $SCInstallRoot + "Sitecore 9.1.1 rev. 002459 (OnPrem)_single.scwdp.zip"
# The path to the Identity Server Package to Deploy.
$IdentityServerPackage = $SCInstallRoot + "Sitecore.IdentityServer 2.0.1 rev. 00166 (OnPrem)_identityserver.scwdp.zip"
# The Identity Server password recovery URL, this should be the URL of the CM Instance
$PasswordRecoveryUrl = "http://$SitecoreSiteName"
# The URL of the Identity Server
$SitecoreIdentityAuthority = "https://$IdentityServerSiteName"
# The URL of the XconnectService
$XConnectCollectionService = "https://$XConnectSiteName"
# The random string key used for establishing connection with IdentityService. This will be regenerated if left on the default.
$ClientSecret = "SIF-Default"
# Pipe-separated list of instances (URIs) that are allowed to login via Sitecore Identity.
$AllowedCorsOrigins = "http://$SitecoreSiteName"

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"
$InformationPreference = "Continue"

$InstallParams = @{
    SubscriptionName = $SubscriptionName
    TenantId = $TenantId
    ResourceGroup = $ResourceGroup
    VmName = $VmName
    VmUsername = $VmUsername
    VmUserPassword = $VmUserPassword
    Location = $Location
    VmSize = $VmSize
    ImageName = $ImageName
    ChocoPackages = $ChocoPackages
    VmDownloadFolder = $VmDownloadFolder
    VmDownloadPath = $VmDownloadPath
    BaseFileUri = $BaseFileUri
    Prefix = $Prefix
    SitecoreAdminPassword = $SitecoreAdminPassword
    SCInstallRoot = $SCInstallRoot
    XConnectSiteName= $XConnectSiteName
    SitecoreSiteName = $SitecoreSiteName
    IdentityServerSiteName = $IdentityServerSiteName
    LicenseFile = $LicenseFile
    SolrUrl = $SolrUrl
    SolrRoot = $SolrRoot
    SolrService = $SolrService
    SqlServer = $SqlServer
    SqlAdminUser = $SqlAdminUser
    SqlAdminPassword = $SqlAdminPassword
    XConnectPackage = $XConnectPackage
    SitecorePackage = $SitecorePackage
    IdentityServerPackage = $IdentityServerPackage
    PasswordRecoveryUrl = $PasswordRecoveryUrl
    SitecoreIdentityAuthority = $SitecoreIdentityAuthority
    XConnectCollectionService = $XConnectCollectionService
    ClientSecret = $ClientSecret
    AllowedCorsOrigins = $AllowedCorsOrigins

}

$UninstallParams = @{
    SubscriptionName = $SubscriptionName
    TenantId = $TenantId
    ResourceGroup = $ResourceGroup
    VmName = $VmName
}

#Installer
.\Installation.ps1 @InstallParams -EnableCleanup -Verbose
#.\Installation.ps1 @InstallParams -Verbose -SkipCreateVM -SkipInstallAzModule -SkipPSRemoting -SkipInstallSoftware

#Uninstaller | This will remove the VM
#.\RemoveAzureVm.ps1 @UninstallParams -Verbose
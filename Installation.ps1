#requires -RunAsAdministrator

param(
    [String]$SubscriptionName,
    [String]$TenantId,
    [String]$ResourceGroup,
    [String]$VmName,
    [String]$VmUsername,
    [SecureString]$VmUserPassword,
    [String]$Location,
    [String]$VmSize,
    [String]$ImageName,
    
    [String[]]$ChocoPackages,
    [String]$VmDownloadFolder,
    [String]$VmDownloadPath,
    [String]$BaseFileUri,

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

    [Switch]$SkipInstallAzModule,
    [Switch]$SkipCreateVM,
    [Switch]$SkipInstallSoftware,
    [Switch]$SkipPSRemoting,
    [Switch]$EnableCleanup
)

$ExtensionName = "VmInstall"
$CurrentLoc = Get-Location

#Check for license file
$licensePath = "$CurrentLoc/license.xml"
if (-not (Test-Path -Path $licensePath)) {
    Write-Error -Message "The license.xml file needs to be placed in $CurrentLoc"
} else { Write-information -Message "License file exists at $licensePath"}

$rootPath = Split-Path $MyInvocation.MyCommand.Path
. "$rootPath\Azure.ps1"
. "$rootPath\AzureBlobFiles\SharedInstallFunctions.ps1"

#Install AzModule
if(!$SkipInstallAzModule) { Install-Module -Name Az -AllowClobber -WarningAction stop } 
else { Write-Information -Message "Install AzModule Skipped." }

Write-Information -Message "Importing AzModule..."
Import-AzModule


#Conect to Azure
Connect-Azure -SubscriptionName $SubscriptionName -TenantId $TenantId

if(!$SkipCreateVM) { 
#Create Azure VM
    $NewVmParams = @{     
        ResourceGroup = $ResourceGroup
        VmName = $VmName
        Location = $Location
        ImageName = $ImageName
        VmSize = $VmSize
        VmUsername = $VmUsername
        VmUserPassword = $VmUserPassword
    }
    New-CustomVM @NewVmParams
}
else { Write-Information -Message "Create VM Skipped." }

$Vm = Get-AzVM -Name $VmName -ResourceGroupName $ResourceGroup

if(!$SkipCreateVM) { 
#Open ports to Azure VM
    Write-Information -Message "Updating VM Security Rules.."
    $NSG = Get-AzNetworkSecurityGroup -Name $Vm.Name

    $RuleRdp = New-AzNetworkSecurityRuleConfig -Name AllowRdp -Description "Allow RDP" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389

    $NSG.SecurityRules.Add($RuleRdp)

    $RuleHttp = New-AzNetworkSecurityRuleConfig -Name AllowHttp -Description "Allow HTTP" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80

    $NSG.SecurityRules.Add($RuleHttp)

    $RuleHttps = New-AzNetworkSecurityRuleConfig -Name AllowHttps -Description "Allow HTTPS" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 102 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443

    $NSG.SecurityRules.Add($RuleHttps)

    $RuleWinRm = New-AzNetworkSecurityRuleConfig -Name AllowWinRm -Description "Allow WinRM" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 103 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 5985

    $NSG.SecurityRules.Add($RuleWinRm)

    Write-Information -Message "Network Security Rules Applied"
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSG

}

if(!$SkipPSRemoting) {
#Enable PS Remoting and Install IIS
    Write-Information -Message "Installing IIS and Enabling PS Remoting..."
    Set-AzVMCustomScriptExtension  `
        -ResourceGroupName $Vm.ResourceGroupName `
        -VmName $Vm.Name `
        -Location $Vm.Location `
        -FileUri "$BaseFileUri/InstallIisPsRemoting.ps1" `
        -Run "InstallIisPsRemoting.ps1" `
        -Name $ExtensionName
        Write-Information -Message "IIS Installed and PSRemoting enabled"
    }

Write-Information -Message "Getting VM IP Address..."
$VmPublicIpAddress = Get-AzPublicIpAddress -Name $Vm.Name

Write-Information -Message "Updating Trustedhosts..."
Set-Item WSMan:localhost\client\trustedhosts -value $VmPublicIpAddress.IpAddress -Force

Write-Information -Message "Updating Local firewall for WinRM..."
netsh advfirewall firewall show rule name="WinRM-HTTP" | netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow

#https://www.codeisahighway.com/set-azurevmcustomscriptextension-multiple-extensions-per-handler-not-supported/
$InstallSoftwareParams = @{
    ResourceGroupName = $Vm.ResourceGroupName
    VmName = $Vm.Name
    Location = $Vm.Location
    FileUri = "$BaseFileUri/InstallSoftware.ps1", "$BaseFileUri/SharedInstallFunctions.ps1"
    Run = "InstallSoftware.ps1"
    Name = $ExtensionName
    Argument = "-ChocoPackages $ChocoPackages " +
        "-VmDownloadFolder $VmDownloadFolder " +
        "-RemoteDownloadPath $VmDownloadPath " +
        "-BaseFileUri $BaseFileUri " +
        "-SCInstallRoot $SCInstallRoot "
}               
if(!$SkipInstallSoftware) {
    Write-Information -Message "Software installing remotely, this will take some time..."
    Set-AzVMCustomScriptExtension @InstallSoftwareParams
    Write-Information -Message "Software installed. Restarting VM..."
    Restart-AzVM -Name $Vm.Name -ResourceGroupName $Vm.ResourceGroupName #Restart Required!
}

if(!$SkipPsRemoting) {
    #Enable PSRemoting on VM
    Write-Information -Message "Enabling PSRemoting..."
    Enable-PSRemoting -SkipNetworkProfileCheck -Force
}

$Cred = New-Object System.Management.Automation.PSCredential ($VmUsername, $VmUserPassword)
Write-Information -Message "Creating PSSession..."
$Session = New-PSSession -ComputerName $VmPublicIpAddress.IpAddress -Port 5985 -Credential $Cred

Copy-Item -Path "license.xml" -Destination $SCInstallRoot -ToSession $Session
Write-Information -Message "Copied License to Server"

#Install Prerequisites, Solr, and SQL
$InstallPrereqsSolrSqlParams = @{
    ResourceGroupName = $ResourceGroup
    VmName = $Vm.Name
    Location = $Vm.Location
    FileUri = "$BaseFileUri/InstallPrereqsSolrSql.ps1", "$BaseFileUri/SharedInstallFunctions.ps1", "$BaseFileUri/InstallSolr.ps1", "$BaseFileUri/sqlexpress.json"
    Run = "InstallPrereqsSolrSql.ps1"
    Name = $ExtensionName
     Argument = "-SqlAdminPassword $SqlAdminPassword " +
     "-VmDownloadPath $VmDownloadPath "
}  
if(!$SkipInstallSoftware) {
    Write-Information -Message "Sitecore Prerequisites, Solr, and MSSQL Installing remotely. Software downloads and will take some time..."
    Set-AzVMCustomScriptExtension @InstallPrereqsSolrSqlParams
    Write-Information -Message "Sitecore Prerequisites, Solr, and MSSQL installed. Restarting VM..."
    Restart-AzVM -Name $Vm.Name -ResourceGroupName $Vm.ResourceGroupName #Restart Required!
}

#Install Sitecore
#Encoding strings due to issues with AzCustomScriptExtension handling quotes in PowerShell execution string.
$EnPrefix = Get-Encoded -Str $Prefix
$EnSitecoreAdminPassword = Get-Encoded -Str $SitecoreAdminPassword
$EnSCInstallRoot = Get-Encoded -Str $SCInstallRoot
$EnXConnectSiteName = Get-Encoded -Str $XConnectSiteName
$EnSitecoreSiteName = Get-Encoded -Str $SitecoreSiteName
$EnIdentityServerSiteName = Get-Encoded -Str $IdentityServerSiteName
$EnLicenseFile = Get-Encoded -Str $LicenseFile
$EnSolrUrl = Get-Encoded -Str $SolrUrl
$EnSolrRoot = Get-Encoded -Str $SolrRoot
$EnSolrService = Get-Encoded -Str $SolrService
$EnSqlServer = Get-Encoded -Str $SqlServer
$EnSqlAdminUser = Get-Encoded -Str $SqlAdminUser
$EnSqlAdminPassword = Get-Encoded -Str $SqlAdminPassword
$EnXConnectPackage = Get-Encoded -Str $XConnectPackage
$EnSitecorePackage = Get-Encoded -Str $SitecorePackage
$EnIdentityServerPackage = Get-Encoded -Str $IdentityServerPackage
$EnPasswordRecoveryUrl = Get-Encoded -Str $PasswordRecoveryUrl
$EnSitecoreIdentityAuthority = Get-Encoded -Str $SitecoreIdentityAuthority
$EnXConnectCollectionService = Get-Encoded -Str $XConnectCollectionService
$EnClientSecret = Get-Encoded -Str $ClientSecret
$EnAllowedCorsOrigins = Get-Encoded -Str $AllowedCorsOrigins

$InstallSitecoreParams = @{
    ResourceGroupName = $ResourceGroup
    VmName = $Vm.Name
    Location = $Vm.Location
    FileUri = "$BaseFileUri/InstallSitecore.ps1", "$BaseFileUri/SharedInstallFunctions.ps1"
    Run = "InstallSitecore.ps1"
    Name = $ExtensionName
    Argument = "-Prefix $EnPrefix " +
        "-SitecoreAdminPassword $EnSitecoreAdminPassword " +
        "-SCInstallRoot $EnSCInstallRoot " +
        "-XConnectSiteName $EnXConnectSiteName " +
        "-SitecoreSiteName $EnSitecoreSiteName " +
        "-IdentityServerSiteName $EnIdentityServerSiteName " +
        "-LicenseFile $EnLicenseFile " +
        "-SolrUrl $EnSolrUrl " +
        "-SolrRoot $EnSolrRoot " +
        "-SolrService $EnSolrService " +
        "-SqlServer $EnSqlServer " +
        "-SqlAdminUser $EnSqlAdminUser " +
        "-SqlAdminPassword $EnSqlAdminPassword " +
        "-XConnectPackage $EnXConnectPackage " +
        "-SitecorePackage $EnSitecorePackage " +
        "-IdentityServerPackage $EnIdentityServerPackage " +
        "-PasswordRecoveryUrl $EnPasswordRecoveryUrl " +
        "-SitecoreIdentityAuthority $EnSitecoreIdentityAuthority " +
        "-XConnectCollectionService $EnXConnectCollectionService " +
        "-ClientSecret $EnClientSecret " +
        "-AllowedCorsOrigins $EnAllowedCorsOrigins"
}               

if(!$SkipInstallSoftware) {
    Write-Information -Message "Installing Sitecore..."
    Set-AzVMCustomScriptExtension @InstallSitecoreParams
    Write-Information -Message "Sitecore Installed"
}


if($EnableCleanup) {
    Write-Information -Message "Removing WinRM from VM Security Rules..."
    $NSG = Get-AzNetworkSecurityGroup -Name $Vm.Name
    $NSG.SecurityRules.Remove($RuleWinRm)
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSG
    Write-Information -Message "Removed WinRM from VM Security Rules"

    Write-Information -Message "Removing AzVMCustomScriptExtension..."
    Remove-AzVMCustomScriptExtension -ResourceGroupName $Vm.ResourceGroupName -VMName $Vm.Name -Name $ExtensionName -Force
}
Write-Information -Message "Remote VM Installation complete!"
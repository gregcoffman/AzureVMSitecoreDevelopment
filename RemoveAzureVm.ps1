#Removes Azure VM and associated Resources
#Run from Installer.ps1

param (
    [String]$SubscriptionName,
    [String]$TenantId,
    [String]$ResourceGroup,
    [String]$VmName
    )


$rootPath = Split-Path $MyInvocation.MyCommand.Path
. "$rootPath\Azure.ps1"

Connect-Azure -SubscriptionName $SubscriptionName -TenantId $Tenantid

Remove-VmAndResources -ResourceGroup $ResourceGroup -VmName $VmName
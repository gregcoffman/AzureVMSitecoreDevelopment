$rootPath = Split-Path $MyInvocation.MyCommand.Path
. "$rootPath\SharedInstallFunctions.ps1"

Enable-PSRemoting -Force
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow

#Install IIS
if ((Get-WindowsFeature Web-Server).InstallState -ne "Installed") {
    Install-WindowsFeature -Name "Web-Server" -IncludeAllSubFeature -IncludeManagementTools
    Write-InformationLog -Message "IIS Installed."
}
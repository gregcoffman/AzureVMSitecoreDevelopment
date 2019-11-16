# Virtual Machine for Sitecore Development

A PowerShell script that creates a Virtual Machine in Azure installing necessary software and development tools for Sitecore.

This is not a Sitecore supported script.

## Description
The script performs the following high level tasks:
- Creates a VM in Azure along with necessary security group rules
- Installs the following OOTB:
    - Development Software via Chocolatey 
        - Visual Studio Community 2017
        - git
        - Google Chrome
        - Notepad++
        - SCALA
    - IIS
    - Sitecore Prerequisites
    - MSSQL 2016 SP2
    - Solr 7.2.1
    - Sitecore 9.1.1

## Prerequisites
[PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-6) is required.

## Installation
1. Copy your Sitecore *license.xml* file to the local script location.
2. If necessary, create a new resource group in Azure where this VM will be deployed.
3. Place the following files are the root of your blog storage container:
```
InstallIisPsRemoting.ps1
InstallPrereqsSolrSql.ps1
InstallSitecore.ps1
InstallSoftware.ps1
InstallSolr.ps1
SharedInstallFunctions.ps1
sqlexpress.json
```

**IMPORTANT: Do not copy files with passwords or other sensitive information tot he Azure public storage!** 

4. [Download Sitecore](https://dev.sitecore.net/Downloads/Sitecore_Experience_Platform.aspx) and place the On Premise Packages for XP Single into the **<YourBlobContainer>/Sitecore** (Default Value) folder in your Azure blob storage. The files should include the following:
```
createcert.json
IdentityServer.json
Prerequisites.json
Sitecore 9.1.1 rev. 002459 (OnPrem)_single.scwdp.zip
Sitecore 9.1.1 rev. 002459 (OnPrem)_xp0xconnect.scwdp.zip
Sitecore.IdentityServer 2.0.1 rev. 00166 (OnPrem)_identityserver.scwdp.zip
sitecore-solr.json
sitecore-XP0.json
xconnect-solr.json
xconnect-xp0.json
XP0-AzureVmSingleDeveloper.ps1 (From this Repo, not in Sitecore download)
XP0-SingleDeveloper.json
```
5. Update all necessary variables in the **Installer.ps1**
6. Run the Installer.ps1



## Troubleshooting

### Remote Logs
While the Remote exectution of PowerShell scripts using the AzVMCustomScriptExtension is occuring, there will be no status information in the local execution window. Logs can be found in a few locations on the Virtual Machine:
- Event Viewer - You can filter by the event source: *VmCustomScriptExtension*
- AzVMCustomScriptExtension status file on the VM located in: 
```
C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\<version Number>\Status
```

### Azure Connectivity
Please refer to the connectivity troubleshooting tools available in the Azure portal.

## Acknowledgments 
- **Jeremy Davis** for his [Low Effort Solr Install](https://gist.github.com/jermdavis/8d8a79f680505f1074153f02f70b9105)
- **Brad Christie** for his [SQL SIF Installer](https://github.com/Brad-Christie-CI/sitecore-sif-snippets/blob/master/src/sqlexpress/2016SP1/sqlexpress.json)
- **SitecoreJunkie** for emotional support

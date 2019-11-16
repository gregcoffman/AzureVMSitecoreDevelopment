function Get-Download {
    [CmdletBinding()]
    param(
        [String]$FileUrl,
        [String]$DownloadPath,
        [String]$OutputFileName
    )
    
    $output = "$DownloadPath$OutputFileName"
    (New-Object System.Net.WebClient).DownloadFile($FileUrl, $output)
}

function Get-ChocoSplit {
    [CmdletBinding()]
    param(
        [String]$Packages
    )
    $PackageArr = $Packages.Split(",") 
    return $PackageArr
}

function Set-Log {
    [CmdletBinding()]
    param(
        [String]$Name
    )
    if(![System.Diagnostics.EventLog]::SourceExists($Name)) {
        New-EventLog -LogName Application -Source AzVMCustomScriptExtension
    }
}

function Write-InformationLog {
    [CmdletBinding()]
    param(
        [String]$Message,
        [Int32]$EventId
    )

    Write-EventLog `
        -LogName Application `
        -Source "AzVMCustomScriptExtension" `
        -Message $Message `
        -EventId $EventId `
        -EntryType Information

    Write-Information -Message $Message
}

function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [String]$Message,
        [Int32]$EventId
    )
        

    Write-EventLog `
        -LogName Application `
        -Source "AzVMCustomScriptExtension" `
        -Message $Message `
        -EventId $EventId `
        -EntryType Error

    Write-Error -Message $Message
}

function Get-Encoded {
    [CmdletBinding()]
    param(
        [String]$Str
    )
    return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Str))
}
function Install-AzModule {
    [CmdletBinding()]
    param()
    if (!(Get-InstalledModule Az)) {
        Write-Information "Az Module not installed.  Installing..."
        Install-Module -Name Az -RequiredVersion "3.0.0" -AllowClobber
    } else {
        Write-Host "Az Module already installed. Continuing..."
    }
}

function Import-AzModule {
    Try {
        Write-Information -Message "Importing the Az module..."
        Import-Module Az
        Write-Information -Message "The Az module was imported."
    }
    catch {
        Write-Error -Message "The Az module could not be imported."
    }
}

function Connect-Azure {
    [CmdletBinding()]
    param(
        [String]$SubscriptionName,
        [String]$TenantId
    )

    Write-Information "Connecting to Azure Account..."

    $LoginReq = $true

    Try {
        $content = Get-AzContext
        if ($content) { $LoginReq = ([string]::IsNullOrEmpty($content.Account)) } 
    } 
    Catch {
        Write-Information -Mesasge "Unable to validate if logged in."
    }

    if ($LoginReq) { Connect-AzAccount } else { Write-Information -Message "Already logged in, continuing..." }
    
    Write-Information -Message "Validating Subscription..."
    if (!(Get-AzSubscription -SubscriptionName $SubscriptionName)) {
        Write-Error -Message "Subscription $SubscrptionName does not exist."
    }

    Write-Information -Message "Validating Tenant..."
    if([string]::IsNullOrEmpty($TenantId)) {
        $context = Get-AzSubscription -SubscriptionName $SubscriptionName
        Set-AzContext $context
    } else {
        $context = Get-AzSubscription -SubscriptionName $SubscriptionName -TenantId $TenantId
        Set-AzContext $context
    }
}

function Confirm-VmName {
    [CmdletBinding()]
    param(
        [String]$VmName
    )

    if (Get-AzResource -Name $VmName -ResourceType "Microsoft.Compute/virtualMachines") {
        return $false
    } else {
        return $true
    }
}

function New-CustomVM {
    [CmdletBinding()]
    param(
        [String]$ResourceGroup,
        [String]$VmName,
        [String]$Location, 
        [String]$ImageName,
        [String]$VmSize,
        [Int32[]]$VmOpenPorts,
        [String]$VmUsername,
        [SecureString]$VmUserPassword
    )

    try {

        $credential = New-Object System.Management.Automation.PSCredential ($VmUsername, $VmUserPassword)
        Write-Information -Message "Created VM credential."

        $NewAzureVmParams = @{
            ResourceGroupName = $ResourceGroup 
            Name = $VmName 
            Location = $Location 
            ImageName = $ImageName
            Size = $VmSize
            Credential = $credential
            OpenPorts = $VmOpenPorts
        }

        if (Confirm-VmName -VmName $VmName) {
            Write-Information -Message "Creating Virtual Machine..."
            New-AzVM @NewAzureVmParams
        } else {
            Write-Information -Message "A VM with that name already exists."
            break
        }
    }
    catch {
        Write-Error -Message "Error Creating VM. " $_.Exception.Message
    }
}

function Remove-VmAndResources {
    [CmdletBinding()]
    param(
    [String]$ResourceGroup,
    [String]$VmName
    )
    Write-Information -Message "Removing Virtual Machine..."
    Remove-AzVM -ResourceGroupName $ResourceGroup -Name $VmName -Force
    
    Write-Information -Message "Removing Network Interface..."
    Remove-AzNetworkInterface -ResourceGroupName $ResourceGroup -Name $VmName -Force

    Write-Information -Message "Removing Public IP Address..."
    Remove-AzPublicIpAddress -ResourceGroupName $ResourceGroup -Name $VmName -Force

    Write-Information -Message "Removing Virutal Network..."
    Remove-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $VmName -Force
    
    Write-Information -Message "Removing Security Group..."
    Remove-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $VmName -Force

    #Remove-Disk
    Get-AzDisk -ResourceGroupName $ResourceGroup | ForEach-Object -Process {
        $diskName = $_.Name
        if($diskName.StartsWith($VmName + "_OsDisk")) {
            Write-Information -Message "Removing Disk $diskName" 
            Remove-AzDisk -ResourceGroupName $ResourceGroup -DiskName $_.Name -Force
        }
    }
}
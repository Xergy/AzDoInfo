Function Test-AzDoInfoVMNoHUB {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase
    )
    process {
        
        $TestBase = $AzDoInfoBase.Results.VMDetails 
        $TestResults = $TestBase | Where-Object {$_.OsType -like "Windows" } | Where-Object {$_.LicenseType -notlike "Windows_Server" }
        
        $Props = @{
            Title = "Windows VMs with No Hybrid Use License Configured"
            Description = "Windows VMs have are a sharp deduction in cost if Hybrid Use Benefit Licensing ""HUB"" is Configured"
            ShortName = "VMNoHUB"
            Results = $TestResults
            Total = $TestBase.Count
            Flagged = $TestResults.count 
            Severity = "3"
            Weight = "3500"    
        }

        Return (New-Object psobject -Property $Props)

    }
}

Function Test-AzDoInfoExtensionLinuxDiagnosticRequiresUpgrade {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.VMExtensionStatus
        $TestResults = $TestBase | Where-Object {$_.Name -like "LinuxDiagnostic" -and $_.TypeHandlerVersion -like "2.3" }
        
        $Props = @{
            Title = "VMs With LinuxDiagnostic Extensions That Require Upgrade"
            Description = "Old Linux Diagnostic have known OMI dependencies that cause system crashes"
            ShortName = "ExtensionLinuxDiagnosticRequiresUpgrade"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "1"
            Weight = "1000"    
        }

        Return (New-Object psobject -Property $Props)

    }
}

Function Test-AzDoInfoExtensionProvisioningStateUnsuccessful {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.VMExtensionStatus
        $TestResults = $TestBase | Where-Object {$_.ProvisioningState -notlike "Succeeded" }
        
        $Props = @{
            Title = "VM Extensions with ProvisioningState not Successful"
            Description = "VM Extensions with ProvisioningState not equal status of Succeeded"
            ShortName = "ExtensionProvisioningStateUnsuccessful"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "2"
            Weight = "2500"    
        }

        Return (New-Object psobject -Property $Props)

    }
}


# Function Test-AzDoInfoVMMissingTagFUNCTION {
#     [CmdletBinding()]
#     param (
#         [parameter(mandatory = $true)]
#         $AzDoInfoBase       
#     )
#     process {

#         $TestBase = $AzDoInfoBase.Results.VMDetails
#         $TestResults = $TestBase | Where-Object {$_.IAM_FUNCTION -like ""}
        
#         $Props = @{
#             Title = "VMs Missing Tag FUNCTION"
#             Description = "The VM’s function TAG is vital to identifying AVSet issues and can help with troubleshooting"
#             ShortName = "VMMissingTagFUNCTION"
#             Results = $TestResults
#             Total = $TestBase.count
#             Flagged = $TestResults.count
#             Severity = "3"
#             Weight = "3700"    
#         }

#         Return (New-Object psobject -Property $Props)

#     }
# }

# Function Test-AzDoInfoMissingVitalTag {
#     [CmdletBinding()]
#     param (
#         [parameter(mandatory = $true)]
#         $AzDoInfoBase       
#     )
#     process {

#         $TestBase = $AzDoInfoBase.Results.VMDetails
#         $TestResults = $TestBase | Where-Object {$_.IAM_FUNCTION -like "" -or $_.IAM_ENVIRONMENT -like "" -or $_.IAM_PLATFORM -like "" -or $_.IAM_SUBCOMPONENT -like "" -or $_.IAM_FUNCTION -like ""}

#         $Props = @{
#             Title = "VMs Missing Vital Tags "
#             Description = "VMs missing any of the following Tags: ENVIRONMENT, PLATFORM, SUBCOMPONENT, FUNCTION"
#             ShortName = "VMMissingVitalTag"
#             Results = $TestResults
#             Total = $TestBase.count
#             Flagged = $TestResults.count
#             Severity = "3"
#             Weight = "3701"    
#         }

#         Return (New-Object psobject -Property $Props)

#     }
# }

Function Test-AzDoInfoNicsWithPipsAllowRemoting {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.NetworkInterfaces
        
        $NSG = $AzDoInfoBase.Results.NSGs
        $NSGRules = $AzDoInfoBase.Results.NSGRules
        $Nics = $AzDoInfoBase.Results.NetworkInterfaces | where-object { $_.Owner -notlike ""}
        $Pips = $AzDoInfoBase.Results.Pips
        # $Nics.Count
        # $Pips.count   
        # $Pips[0]
        # $AzDoInfoBase.Results.PIPs[0]
        # $AzDoInfoBase.Results.NetworkInterfaces[0]
        
        $ProblemNSGRules = $NSGRules | where-object {
            ($_.DPortRange.split(" ") -contains "22" -or 
            $_.DPortRange.split(" ") -contains "3389") -and 
            $_.Access -eq "Allow" -and 
            $_.SAddressPrefix -eq "*" -and
            $_.Direction -eq "Inbound"
        }
        # $ProblemNSGRules[0]
        # $ProblemNSGRules.count
        # $ProblemNSGRules | Out-GridView
        
        $NicsWithPIPs = $Nics | Where-Object { $PIPs.NetworkInterface -contains $_.Name } 
        # $NicsWithPIPs.Count
        $NicsWithPIPsAndProblemNSGs =  $NicsWithPIPs | Where-Object { $ProblemNSGRules.NSG -contains $_.NSG }
        # $NicsWithPIPsAndProblemNSGs.Count
        # $NicsWithPIPsAndProblemNSGs[10]
        # $NicsWithPIPsAndProblemNSGs | out-gridview

        $TestResults = $NicsWithPIPsAndProblemNSGs

        $Props = @{
            Title = "Nics with PIPs Allowing Remoting from Internet"
            Description = "Nics with PIPs and NSGs allowing remoting inbound to TCP Port 3389 or 22 from Internet"
            ShortName = "NicsWithPIPsAllowRemoting"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "2"
            Weight = "2000"    
        }

        Return (New-Object psobject -Property $Props)

    }
}

Function Test-AzDoInfoBackupUnwell {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.BackupItemSummary
        $TestResults = $TestBase | Where-Object {$_.ProtectionStatus -notlike "Healthy" -or $_.ProtectionState -notlike "Protected" -or $_.LastBackupStatus -notlike "Completed" }

        $Props = @{
            Title = "Backup is in Unwell Status"
            Description = "Backup with Unhealthy status for ProtectionStatus, ProtectionState, and LastBackupStatus"
            ShortName = "BackupUnwell"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "2"
            Weight = "3100"    
        }

        Return (New-Object psobject -Property $Props)

    }
}


Function Test-AzDoInfoBackupOld {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.BackupItemSummary
        $AzDoInfoRuntime = [datetime]::parseexact($AzDoInfoBase.RunTime, 'yyyy-MM-ddTHH.mm', $null)
        $TestResults = $TestBase | Where-Object {$_.LastBackupTime -lt $AzDoInfoRuntime.AddDays(-30) }

        $Props = @{
            Title = "Last Backup is Old"
            Description = "Backups older than 30 day before AzDoInfo datagrab datetime ""$($AzDoInfoBase.RunTime)"" "
            ShortName = "BackupOld"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "2"
            Weight = "3101"    
        }     

        

        Return (New-Object psobject -Property $Props)

    }
}

Function Test-AzDoInfoNicsOrphan {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.NetworkInterfaces
        $TestResults = $TestBase | Where-Object {$_.Owner -like ""}

        $Props = @{
            Title = "Orphan Nics"
            Description = "Nics with no parent VM"
            ShortName = "NicsOrphan"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "4"
            Weight = "4500"    
        }

        

        

        Return (New-Object psobject -Property $Props)

    }
}

Function Test-AzDoInfoDiskOrphan {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.Disks
        $TestResults = $TestBase | Where-Object {$_.ManagedByName -like ""} 

        $Props = @{
            Title = "Orphan Disks"
            Description = "Disks with no parent VM"
            ShortName = "DiskOrphan"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "4"
            Weight = "4500"    
        }

        Return (New-Object psobject -Property $Props)

    }
}
Function Test-AzDoInfoPIPOrphan {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.PIPs
        $TestResults = $TestBase | Where-Object {$_.NetworkInterface -like ""} 

        $Props = @{
            Title = "Orphan Public IPs"
            Description = "Public IPs (PIPs) with no Network Interface"
            ShortName = "PIPOrphan"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "4"
            Weight = "4500"    
        }

        Return (New-Object psobject -Property $Props)

    }
}

Function Test-AzDoInfoSnapshotOld {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.Snapshots
        $AzDoInfoRuntime = [datetime]::parseexact($AzDoInfoBase.RunTime, 'yyyy-MM-ddTHH.mm', $null)
        $TestResults = $TestBase | Where-Object {$_.TimeCreated -lt $AzDoInfoRuntime.AddDays(-90)  } 

        $Props = @{
            Title = "Snapshots over 90 days old"
            Description = "Snapshot older than 60 days from AzDoInfo Datagrab DateTime $($AzDoInfoRuntime)"
            ShortName = "SnapshotOld"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "4"
            Weight = "4500"    
        }

        Return (New-Object psobject -Property $Props)

    }
}

Function Test-AzDoInfoDiskSmallSSD {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.Disks
        $TestResults = $TestBase | Where-Object {$_.DiskSizeGB -lt 64 -and $_.SkuTier -like "Premium" } 

        $Props = @{
            Title = "Premium SSDs of Small Size"
            Description = "With SSDs, size dictates performance - Small sized SSDs should be reviewed maybe as low as 25MB/s"
            ShortName = "DiskSmallSSD"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "3"
            Weight = "3500"    
        }

        Return (New-Object psobject -Property $Props)

    }
}


Function Test-AzDoInfoNSGOrphan {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.NSGs 
        $TestResults = $TestBase | Where-Object {$_.NetworkInterfaceName -eq $Null -and $_.SubnetName -eq $Null }

        $Props = @{
            Title = "Orphan NSGs"
            Description = "NSGs with no Nic or Subnet attached"
            ShortName = "NSGOrphan"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "4"
            Weight = "4500"    
        }

        Return (New-Object psobject -Property $Props)

    }
}

Function Test-AzDoInfoNicWithPIPAndNoNSG {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.NetworkInterfaces | Where-Object {$_.Owner -notlike ""} 
        $PIPs = $AzDoInfoBase.Results.PIPs 
        $Subnets = $AzDoInfoBase.Results.Subnets        
       
        $NicsWithPIPs = $TestBase | Where-Object { $PIPs.NetworkInterface -contains $_.Name } 
        $NicsWithPIPsAndNoNSGs =  $NicsWithPIPs | Where-Object { $_.NSG -like "" -and
                $_.NSG -like ""        
            }

        $TestResults = $NicsWithPIPsAndNoNSGs

        $Props = @{
            Title = "Nics with PIP and No NSG"
            Description = "Nics with Public IPs (PIPs) and No Nic Level NSG attached"
            ShortName = "NicWithPIPAndNoNSG"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "2"
            Weight = "2600"    
        }

        Return (New-Object psobject -Property $Props)

    }
}




Function Test-AzDoInfoVMNotRunning {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.VMDetails
        $TestResults = $TestBase | Where-Object {$_.PowerState -notlike "running" }

        $Props = @{
            Title = "VMs not in a Running PowerState "
            Description = "VMs that are not running that may need to be started or possibly retired"
            ShortName = "VMNotRunning"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "3"
            Weight = "3000"    
        }

        Return (New-Object psobject -Property $Props)

    }
}

Function Test-AzDoInfoVMNonStandardName {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $AzDoInfoBase       
    )
    process {

        $TestBase = $AzDoInfoBase.Results.VMDetails
        $TestResults = $TestBase | Where-Object { ($_.Name | Measure-Object -Character | Select-Object -ExpandProperty Characters) -ne 14  }

        $Props = @{
            Title = "VMs with NonStandard Names"
            Description = "VMs with names not equal to 14 characters"
            ShortName = "VMNonStandardName"
            Results = $TestResults
            Total = $TestBase.count
            Flagged = $TestResults.count
            Severity = "4"
            Weight = "4000"    
        }

        Return (New-Object psobject -Property $Props)

    }
}

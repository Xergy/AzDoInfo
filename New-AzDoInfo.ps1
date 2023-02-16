<#
    .SYNOPSIS
        Script starts AzDoInfo which gathers Azure DevOps Configration Details

    .NOTES
        AzDoInfo typically writes temp data to a folder of your choice i.e. C:\temp. It also zips up the final results.
#>

param (
    $ConfigLabel = "DefaultAzDOInfoConfig"
)

Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Starting..."

$VerbosePreference = "Continue"
Import-Module .\Modules\AzDoInfo -Force
$VerbosePreference = "SilentlyContinue"
Import-Module VSTeam
#$VerbosePreference = "Continue"
$VerbosePreference = "SilentlyContinue"

# Find TempPath for local files
$TempPath = If ($AzureAutomation) {$env:Temp}
Else {"C:\Temp"}
Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) TempPath: $($TempPath )"

Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) ConfigLabel: $($ConfigLabel)"
Switch ($ConfigLabel) {
    DefaultAzDOInfoConfig {
        Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Gathering All Collection..."
            $Collections = "rSandbox","ASHCollab"            
        Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Gathering Collections - Done! Total Subs:$($Subs.Count) RGs:$($RGs.Count)"

        $ScriptControl = @{
            GetAzDoInfo = @{
                Execute = $true
                Params = @{
                    Collections = $Collections
                    ConfigLabel = $ConfigLabel
                }
            }
            ExportAzDoInfo = @{
                Execute = $true
                Params = @{                    
                    LocalPath = $TempPath   
                    }    
            }
            ExportAzDoInfoToBlobStorage = @{
                Execute = $false
            }
        } # End ScriptControl
    } # Env ConfigLabel 
} # End Switch ConfigLabel

If ($ScriptControl.GetAzDoInfo.Execute) {

    Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Running Get-AzDoInfo..."

    $Params = $ScriptControl.GetAzDoInfo.Params

    $AzDoInfoResults = Get-AzDoInfo @Params -Verbose

} Else {Write-Output "Skipping GetAzDoInfo..."}


If ($ScriptControl.ExportAzDoInfo.Execute) {
    
    Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Running Export-AzDoInfo..."

    $Params = $ScriptControl.ExportAzDoInfo.Params
    $Params.AzDoInfoResults = $AzDoInfoResults

    Export-AzDoInfo @Params

} Else {Write-Output "Skipping ExportAzDoInfo..."}

If ($ScriptControl.ExportAzDoInfoToBlobStorage.Execute) {

    Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Running Export-AzDoInfoToBlobStorage..."

    $Params = $ScriptControl.ExportAzDoInfoToBlobStorage.Params
    $Params.AzDoInfoResults = $AzDoInfoResults

    Export-AzDoInfoToBlobStorage @Params

} Else {Write-Output "Skipping ExportAzDoInfoToBlobStorage..."}

# Post Processing...
# if any...

Write-Output "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Done!"
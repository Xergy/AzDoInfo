# Simple script to gather Org and Project 

# Variables

$CollectionUri = 'https://dev.azure.com/rSandbox'

# Get All process, Select a Process

Clear-Host

$Params = @{
    Headers = @{}
    Uri = "$CollectionUri/_apis/process/processes?api-version=6.0"
    Method = "Get"
    UseDefaultCredentials = $True
}
Write-Host "Gathering Process Template Ids..." -ForegroundColor Cyan
$Processes = Invoke-RestMethod @Params | ForEach-Object {$_.value}
Write-Host "Found $($Processes | Measure-Object | Select-Object -ExpandProperty Count )!" -ForegroundColor Cyan


Write-Host "All Default and Custom Process Template Ids:" -ForegroundColor Cyan
$Processes | Select-Object Name,Id

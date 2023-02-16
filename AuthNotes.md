
Sample to auth to each collection:

```
function Connect-AzDoCollection {
    param (
        $Collection
    )

    If  ($Collection -eq "rSandbox") {
        Write-Host "Logging on to $Collection Collection"
        Set-VSTeamAccount -Account rSandbox -PersonalAccessToken <YourPat>

    } elseif ($Collection -eq "ashcollab") {
        Write-Host "Logging on to $Collection Collection"
        Set-VSTeamAccount -Account ashcollab -PersonalAccessToken <YourPat>

    }
    
}
```
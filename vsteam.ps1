Add-VSTeam

get-module VSTeam

Get-Command -noun vsteam*

Get-VSTeam

Set-VSTeamAccount

Set-VSTeamAccount -Account http://localtfs:8080/tfs/DefaultCollection -UseWindowsAuthentication

https://dev.azure.com/rSandbox/

Set-VSTeamAccount -Account rSandbox -UseWindowsAuthentication

Get-VSTeam -ProjectName AzDevOpsInfo | fl *

$Projects = Get-VSTeamProject 

$Projects | fl *

$Projects.InternalObject 

$Teams = $Projects | get-vsteam  

$Teams | fl *

$Teams | ft -AutoSize

$Repos = Get-VSTeamGitRepository

$Repos.InternalObject.size



Get-VSTeamGitRepository | FL *

Get-VSTeamGitRepository.InternalObject

Get-VSTeamGitStat -RepositoryId 27722315-e918-4c41-be38-8bb3d6788733 | fl *

Get-VSTeamGitRepository | Get-VSTeamGitRef

Get-VSTeamSecurityNamespace | Select-Object -First 1 | Get-VSTeamAccessControlList

Get-VSTeamPool | Get-VSTeamAgent

Get-VSTeamProject | Get-VSTeamArea

Get-VSTeamProject | fl *
(Get-VSTeamProject).InternalObject | fl *

Get-VSTeamInfo

$Projects | Get-VSTeamIteration

Get-VSTeamFeed

Get-VSTeamProcess | fl *

$Projects | Get-VSTeamQuery | fl *

Get-VSTeamProfile 

Get-VSTeamProfile -Name rSandbox

Get-VSTeamMember

Get-VSTeamUser | fl *

Get-VSTeamProject
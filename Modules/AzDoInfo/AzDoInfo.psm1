  
Function Get-AzDoInfo {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $Collections,
        [parameter(mandatory = $true)]
        $ConfigLabel
        )
    
    process {
        Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Starting AzDoInfo... "
    
        # Start Timer
        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
    
        # Create NowStr for use in downstream functions
        $NowStr = Get-Date -Format yyyy-MM-ddTHH.mm
    
        #Initialize a few items
        Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Gathering Collection and Project Info..."
        $Collections = $Collections #TODO

        $Projects = Get-VSTeamProject

        # Suppress Azure PowerShell Change Warnings
        Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    
        #region Gather Info
    
        $Projs = Get-VSTeamProject
        $ProjectBasics = @()
        $Repos = @()
       
        # Main Loop
    foreach ($Collection in $Collections)
    {   
        Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Gathering Info for $Collection"
        Connect-AzDoCollection -Collection $Collection

        $Projs = Get-VSTeamProject
        
        foreach ( $Proj in $Projs )
        {            
            Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Gathering Info for $($Proj.ProjectName)"
            $ProjectBasics += Get-VSTeamProject -Name $Proj.ProjectName |
                Select-Object *,
                    @{N='Collection';E={
                            $Collection
                            } 
                    },
                    @{N='LastUpdateTime';E={
                        $_.InternalObject.lastUpdateTime
                        } 
                    } |
                Select-Object -Property Name,Collection,id,Description,State,LastUpdateTime | Sort-Object -Property Collection,Name            
            Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Gathering Info for $($Proj.ProjectName) Repos"
            $Repos += Get-VSTeamGitRepository -ProjectName $Proj |
                Select-Object *,
                    @{N='Collection';E={
                            $Collection
                            } 
                    } |
                Select-Object -Property Name,Collection,Project,Size  | Sort-Object -Property Collection,Project,Name 

        }
    }
        #endregion    
    
        #region Build HTML Report, Export to C:\
        Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Building HTML Report" 
        $Report = @()
        $HTMLmessage = ""
        $HTMLMiddle = ""
    
        Function Addh1($h1Text){
            # Create HTML Report for the current System being looped through
            $CurrentHTML = @"
<hr noshade size=3 width="100%">

<p><h1>$h1Text</p></h1>
"@
        return $CurrentHTML
        }
    
        Function Addh2($h2Text){
            # Create HTML Report for the current System being looped through
            $CurrentHTML = @"
<hr noshade size=3 width="75%">

<p><h2>$h2Text</p></h2>
"@
        return $CurrentHTML
        }
    
        function GenericTable ($TableInfo,$TableHeader,$TableComment ) {
        $MyTableInfo = $TableInfo | ConvertTo-HTML -fragment
    
            # Create HTML Report for the current System being looped through
            $CurrentHTML += @"
<h3>$TableHeader</h3>
<p>$TableComment</p>
<table class="normal">$MyTableInfo</table>	
"@
    
        return $CurrentHTML
        }
    
        $HTMLMiddle += AddH1 "Azure DevOps Resource Information Summary Report"
        $HTMLMiddle += GenericTable $ProjectBasics "ProjectBasics" "Project Info"    
        $HTMLMiddle += GenericTable $Repos "Repos" "Detailed Repos Info"

        # Assemble the HTML Header and CSS for our Report
        $HTMLHeader = @"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html><head><title>Azure Info Report</title>
<style type="text/css">
<!--
body {
font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
}

    #report { width: 835px; }

    table{
    border-collapse: collapse;
    border: none;
    font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;
    color: black;
    margin-bottom: 10px;
}

    table td{
    font-size: 12px;
    padding-left: 0px;
    padding-right: 20px;
    text-align: left;
}

    table th {
    font-size: 12px;
    font-weight: bold;
    padding-left: 0px;
    padding-right: 20px;
    text-align: left;
}

h2{ clear: both; font-size: 130%; }

h3{
    clear: both;
    font-size: 115%;
    margin-left: 20px;
    margin-top: 30px;
}

p{ margin-left: 20px; font-size: 12px; }

table.list{ float: left; }

    table.list td:nth-child(1){
    font-weight: bold;
    border-right: 1px grey solid;
    text-align: right;
}

table.list td:nth-child(2){ padding-left: 7px; }
table tr:nth-child(even) td:nth-child(even){ background: #CCCCCC; }
table tr:nth-child(odd) td:nth-child(odd){ background: #F2F2F2; }
table tr:nth-child(even) td:nth-child(odd){ background: #DDDDDD; }
table tr:nth-child(odd) td:nth-child(even){ background: #E5E5E5; }
div.column { width: 320px; float: left; }
div.first{ padding-right: 20px; border-right: 1px  grey solid; }
div.second{ margin-left: 30px; }
table{ margin-left: 20px; }
-->
</style>
</head>
<body>

"@
    
        # Assemble the closing HTML for our report.
        $HTMLEnd = @"
</div>
</body>
</html>
"@
    
        # Assemble the final HTML report from all our HTML sections
        $HTMLmessage = $HTMLHeader + $HTMLMiddle + $HTMLEnd
    
        #endregion
    
        #region Capture Time
        Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Done! Total Elapsed Time: $($elapsed.Elapsed.ToString())" 
        $elapsed.Stop()
        #endregion
    
        $Props = @{
            Results = @{
                Repos = $Repos
                HTMLReport = $HTMLmessage
            }
            RunTime = $NowStr
            ConfigLabel = $ConfigLabel
    
        }    
    
        Return (New-Object psobject -Property $Props)
    
        } #End Process
    } #End Get-AzDoInfo
    
    
    Function Export-AzDoInfo {
        [CmdletBinding()]
        param (
            [parameter(mandatory = $true)]
            $AzDoInfoResults,
            [parameter(mandatory = $true)]
            $LocalPath
        )
        
        Process {
    
            $RootFolderStr = $AzDoInfoResults.RunTime.substring(0,7)
            Write-Verbose "RootFolderStr = $RootFolderStr"
            $RunTime = $AzDoInfoResults.RunTime
            Write-Verbose "RunTime = $RunTime"
            $ReportFolderStr = "$($RunTime)_AzDoInfo"
            Write-Verbose "ReportFolderStr = $ReportFolderStr"
    
            $ReportLocalFolderFullPath = "$($LocalPath)\$($AzDoInfoResults.ConfigLabel)\$($RootFolderStr)\$($ReportFolderStr)"
            Write-Verbose "ReportLocalFolderFullPath = $ReportLocalFolderFullPath"
    
            Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Saving Data to $ReportLocalFolderFullPath"
    
            md $ReportLocalFolderFullPath | Out-Null
            
            $AzDoInfoResults.Results.Repos | Export-Csv -Path "$($ReportLocalFolderFullPath)\Repos.csv" -NoTypeInformation 
    
            # Save the report out to a file in the current path
            $AzDoInfoResults.Results.HTMLReport | Out-File -Force ("$($ReportLocalFolderFullPath)\AzDoInfo.html")
            # Email our report out
            # send-mailmessage -from $fromemail -to $users -subject "Systems Report" -Attachments $ListOfAttachments -BodyAsHTML -body $HTMLmessage -priority Normal -smtpServer $server
    
            #endregion
    
            #region Zip Results
            Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Creating Archive ""$($ReportLocalFolderFullPath).zip"""
            Add-Type -assembly "system.io.compression.filesystem"
    
            [io.compression.zipfile]::CreateFromDirectory($ReportLocalFolderFullPath, "$($ReportLocalFolderFullPath)_$($AzDoInfoResults.ConfigLabel).zip") | Out-Null
            Move-Item "$($ReportLocalFolderFullPath)_$($AzDoInfoResults.ConfigLabel).zip" "$($ReportLocalFolderFullPath)"
    
        }
    }
    
    Function Export-AzDoInfoToBlobStorage {
        [CmdletBinding()]
        param (
            [parameter(mandatory = $true)]
            $AzDoInfoResults,
            [parameter(mandatory = $true)]
            $LocalPath,
            [parameter(mandatory = $true)]
            $StorageAccountSubID,
            [parameter(mandatory = $true)]
            $StorageAccountRG,
            [parameter(mandatory = $true)]
            $StorageAccountName,
            [parameter(mandatory = $true)]
            $StorageAccountContainer  
            )
        
        Process {
    
            Set-AzContext -SubscriptionId $StorageAccountSubID | Out-Null
    
            $RootFolderStr = $AzDoInfoResults.RunTime.substring(0,7)
            Write-Verbose "RootFolderStr = $RootFolderStr"
            $RunTime = $AzDoInfoResults.RunTime
            Write-Verbose "RunTime = $RunTime"
            $ReportFolderStr = "$($RunTime)_AzDoInfo"
            Write-Verbose "ReportFolderStr = $ReportFolderStr"
    
            $ReportLocalFolderFullPath = "$($LocalPath)\$($AzDoInfoResults.ConfigLabel)\$($RootFolderStr)\$($ReportFolderStr)"
            Write-Verbose "ReportLocalFolderFullPath = $ReportLocalFolderFullPath"
        
            Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Blob copy to $StorageAccount $StorageAccountName $StorageAccountContainer $($RootFolderStr)\$($ReportFolderStr) "
            $StorageAccount = (Get-AzStorageAccount -ResourceGroupName $StorageAccountRG  -Name $StorageAccountName)
            $StorageAccountCtx = ($StorageAccount).Context
            $BlobParams = @{
                Context = $StorageAccountCtx
                Container = $StorageAccountContainer
                File = $null
                Blob = $null
            }
            
            #$VerbosePreference = "Continue"
            Get-ChildItem $ReportLocalFolderFullPath | foreach-object {
                $BlobParams.File = $_.FullName
                $BlobParams.Blob = "$($AzDoInfoResults.ConfigLabel)\$($RootFolderStr)\$($ReportFolderStr)\$($_.Name)"
                Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Writing file: $($Blobparams.File) to Blob $($BlobParams.Blob)"
                Set-AzStorageBlobContent @BlobParams -Force -Verbose:$false | Out-Null
            }
            #$VerbosePreference = "SilentlyContinue"
        }
    }
    
    Function Copy-FilesToBlobStorage {
        [CmdletBinding()]
        param (
            [parameter(mandatory = $true)]
            $Files,
            [parameter(mandatory = $true)]
            $TargetBlobFolderPath,
            [parameter(mandatory = $true)]
            $StorageAccountSubID,
            [parameter(mandatory = $true)]
            $StorageAccountRG,
            [parameter(mandatory = $true)]
            $StorageAccountName,
            [parameter(mandatory = $true)]
            $StorageAccountContainer  
        )
        
        Process {
    
            Set-AzContext -SubscriptionId $StorageAccountSubID | Out-Null
    
            Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.ss) Blob files copy to $StorageAccountName $StorageAccountContainer $($TargetBlobFolderPath)\"
            $StorageAccount = (Get-AzStorageAccount -ResourceGroupName $StorageAccountRG  -Name $StorageAccountName)
            $StorageAccountCtx = ($StorageAccount).Context
            
            $VerbosePreference = "SilentlyContinue"
            $Files | foreach-object {
                Set-AzStorageBlobContent -Context $StorageAccountCtx -Container "$StorageAccountContainer" -File $_.FullName -Blob "$($TargetBlobFolderPath)\$($_.Name)" -Force |
                Out-Null
            }
            $VerbosePreference = "SilentlyContinue"
        }
    }
    
    function AddItemProperties($item, $properties, $output)
    {
        if($item -ne $null)
        {
            foreach($property in $properties)
            {
                $propertyHash =$property -as [hashtable]
                if($propertyHash -ne $null)
                {
                    $hashName=$propertyHash["name"] -as [string]
                    if($hashName -eq $null)
                    {
                        throw "there should be a string Name"  
                    }
             
                    $expression=$propertyHash["expression"] -as [scriptblock]
                    if($expression -eq $null)
                    {
                        throw "there should be a ScriptBlock Expression"  
                    }
             
                    $_=$item
                    $expressionValue=& $expression
             
                    $output | add-member -MemberType "NoteProperty" -Name $hashName -Value $expressionValue
                }
                else
                {
                    # .psobject.Properties allows you to list the properties of any object, also known as "reflection"
                    foreach($itemProperty in $item.psobject.Properties)
                    {
                        if ($itemProperty.Name -like $property)
                        {
                            $output | add-member -MemberType "NoteProperty" -Name $itemProperty.Name -Value $itemProperty.Value
                        }
                    }
                }
            }
        }
    }
        
    function WriteJoinObjectOutput($leftItem, $rightItem, $leftProperties, $rightProperties, $Type)
    {
        $output = new-object psobject
        if($Type -eq "AllInRight")
        {
            # This mix of rightItem with LeftProperties and vice versa is due to
            # the switch of Left and Right arguments for AllInRight
            AddItemProperties $rightItem $leftProperties $output
            AddItemProperties $leftItem $rightProperties $output
        }
        else
        {
            AddItemProperties $leftItem $leftProperties $output
            AddItemProperties $rightItem $rightProperties $output
        }
        $output
    }
    <#
    .Synopsis
       Joins two lists of objects
    .DESCRIPTION
       Joins two lists of objects
    .EXAMPLE
       Join-Object $a $b "Id" ("Name","Salary")
    #>
    function Join-Object
    {
        [CmdletBinding()]
        [OutputType([int])]
        Param
        (
            # List to join with $Right
            [Parameter(Mandatory=$true,
                       Position=0)]
            [object[]]
            $Left,
            # List to join with $Left
            [Parameter(Mandatory=$true,
                       Position=1)]
            [object[]]
            $Right,
            # Condition in which an item in the left matches an item in the right
            # typically something like: {$args[0].Id -eq $args[1].Id}
            [Parameter(Mandatory=$true,
                       Position=2)]
            [scriptblock]
            $Where,
            # Properties from $Left we want in the output.
            # Each property can:
            # â€“ Be a plain property name like "Name"
            # â€“ Contain wildcards like "*"
            # â€“ Be a hashtable like @{Name="Product Name";Expression={$_.Name}}. Name is the output property name
            #   and Expression is the property value. The same syntax is available in select-object and it is 
            #   important for join-object because joined lists could have a property with the same name
            [Parameter(Mandatory=$true,
                       Position=3)]
            [object[]]
            $LeftProperties,
            # Properties from $Right we want in the output.
            # Like LeftProperties, each can be a plain name, wildcard or hashtable. See the LeftProperties comments.
            [Parameter(Mandatory=$true,
                       Position=4)]
            [object[]]
            $RightProperties,
            # Type of join. 
            #   AllInLeft will have all elements from Left at least once in the output, and might appear more than once
            # if the where clause is true for more than one element in right, Left elements with matches in Right are 
            # preceded by elements with no matches. This is equivalent to an outer left join (or simply left join) 
            # SQL statement.
            #  AllInRight is similar to AllInLeft.
            #  OnlyIfInBoth will cause all elements from Left to be placed in the output, only if there is at least one
            # match in Right. This is equivalent to a SQL inner join (or simply join) statement.
            #  AllInBoth will have all entries in right and left in the output. Specifically, it will have all entries
            # in right with at least one match in left, followed by all entries in Right with no matches in left, 
            # followed by all entries in Left with no matches in Right.This is equivallent to a SQL full join.
            [Parameter(Mandatory=$false,
                       Position=5)]
            [ValidateSet("AllInLeft","OnlyIfInBoth","AllInBoth", "AllInRight")]
            [string]
            $Type="OnlyIfInBoth"
        )
        Begin
        {
            # a list of the matches in right for each object in left
            $leftMatchesInRight = new-object System.Collections.ArrayList
            # the count for all matches  
            $rightMatchesCount = New-Object "object[]" $Right.Count
            for($i=0;$i -lt $Right.Count;$i++)
            {
                $rightMatchesCount[$i]=0
            }
        }
        Process
        {
            if($Type -eq "AllInRight")
            {
                # for AllInRight we just switch Left and Right
                $aux = $Left
                $Left = $Right
                $Right = $aux
            }
            # go over items in $Left and produce the list of matches
            foreach($leftItem in $Left)
            {
                $leftItemMatchesInRight = new-object System.Collections.ArrayList
                $null = $leftMatchesInRight.Add($leftItemMatchesInRight)
                for($i=0; $i -lt $right.Count;$i++)
                {
                    $rightItem=$right[$i]
                    if($Type -eq "AllInRight")
                    {
                        # For AllInRight, we want $args[0] to refer to the left and $args[1] to refer to right,
                        # but since we switched left and right, we have to switch the where arguments
                        $whereLeft = $rightItem
                        $whereRight = $leftItem
                    }
                    else
                    {
                        $whereLeft = $leftItem
                        $whereRight = $rightItem
                    }
                    if(Invoke-Command -ScriptBlock $where -ArgumentList $whereLeft,$whereRight)
                    {
                        $null = $leftItemMatchesInRight.Add($rightItem)
                        $rightMatchesCount[$i]++
                    }
                
                }
            }
            # go over the list of matches and produce output
            for($i=0; $i -lt $left.Count;$i++)
            {
                $leftItemMatchesInRight=$leftMatchesInRight[$i]
                $leftItem=$left[$i]
                                   
                if($leftItemMatchesInRight.Count -eq 0)
                {
                    if($Type -ne "OnlyIfInBoth")
                    {
                        WriteJoinObjectOutput $leftItem  $null  $LeftProperties  $RightProperties $Type
                    }
                    continue
                }
                foreach($leftItemMatchInRight in $leftItemMatchesInRight)
                {
                    WriteJoinObjectOutput $leftItem $leftItemMatchInRight  $LeftProperties  $RightProperties $Type
                }
            }
        }
        End
        {
            #produce final output for members of right with no matches for the AllInBoth option
            if($Type -eq "AllInBoth")
            {
                for($i=0; $i -lt $right.Count;$i++)
                {
                    $rightMatchCount=$rightMatchesCount[$i]
                    if($rightMatchCount -eq 0)
                    {
                        $rightItem=$Right[$i]
                        WriteJoinObjectOutput $null $rightItem $LeftProperties $RightProperties $Type
                    }
                }
            }
        }
    }
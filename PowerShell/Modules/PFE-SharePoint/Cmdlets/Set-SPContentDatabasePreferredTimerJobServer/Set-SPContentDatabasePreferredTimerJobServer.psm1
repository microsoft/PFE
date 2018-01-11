[CmdletBinding]
function Set-SPContentDatabasePreferredTimerJobServer
{
    param( 
        [Parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Server
    )

    $preferredInstance = (Get-SPFarm).TimerService.Instances | Where-Object{$_.Server.Address -eq ($Server.Trim())}

    if($null -eq $preferredInstance)
    {
        throw "A timer job service instance could not be found on server $Server"
    }

    $db = Get-SPContentDatabase ($Database.Trim()) -ErrorAction SilentlyContinue

    if($null -eq $db)
    {
        throw "A Content Database with name $Database could not be found in the SharePoint Farm"
    }
    $db.PreferredTimerServiceInstance = $preferredInstance
    $db.Update()
}
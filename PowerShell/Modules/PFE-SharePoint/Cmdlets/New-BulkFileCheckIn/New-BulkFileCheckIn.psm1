
<#
Author: Roger Cormier
Company: Microsoft
Description: This cmdlet performs a bulk check-in of all checked out files in a site
#>
function New-BulkFileCheckIn
{
[CmdletBinding()]
param(
[Parameter(HelpMessage="Represents the SPSite binding", Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
[Alias ('URL')]
[String[]]$Site,
[Parameter(HelpMessage="Represents the comment that will be used during check-in", Mandatory=$False)]
[String]$AdminMessage
)

Begin
{

    if([string]::IsNullOrEmpty($AdminMessage))
    {
        $AdminMessage = "Checked in by administrator"
    }
}

Process
{
    $ActiveSite = Get-SPSite "$($Site)"
    foreach($Web in $ActiveSite.AllWebs)
    {
        Write-Verbose "Processing web with URL: $($Web.url)"
        $Lists = $web.lists | Where-Object {$_ -is [Microsoft.SharePoint.SPDocumentLibrary]}
        foreach($list in $Lists)
        {
            Write-Verbose "Calling Get-CheckedOutFilesInList Cmdlet for list with title:  $($List.title)"
            $CheckedOutFiles = Get-CheckedOutFilesInList -List $list
            foreach($key in $CheckedOutFiles.keys)
            {
                try
                {
                    $list.GetItemById(
                    $CheckedOutFiles[$key].id).file.CheckIn($AdminMessage)
                    Write-Verbose "checked in file with URL $($CheckedOutFiles[$key].url)"
                }
                catch
                {
                    Write-Verbose "Error occurred processing item with ID $($Checkedoutfiles[$key].id)"
                }
            }
        }
        $web.dispose()
    }
    $Site.dispose()

}

End
{

}

}


<#PSScriptInfo

.VERSION 1.0

.GUID 020f2610-2b96-4ff6-a457-89444e4df628

.AUTHOR Roger Cormier

.COMPANYNAME Microsoft

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

<#

.DESCRIPTION
 This cmdlet forces a check-in of all checked out files within a given site collection

#>

function New-BulkFileCheckIn
{
[CmdletBinding()]
param(
[Parameter (Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
[Alias ('URL')]
[String[]]$Site,
[Parameter (Mandatory=$False)]
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

}

End
{

}

}

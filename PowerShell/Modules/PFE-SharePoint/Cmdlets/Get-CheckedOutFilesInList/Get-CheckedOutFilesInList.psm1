
<#PSScriptInfo

.VERSION 1.0

.GUID 02d5fedf-746e-4c9b-b0aa-3a6d935577aa

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
 This cmdlet returns all checked out files in a list

#>

function Get-CheckedOutFilesInList
{
    [CmdletBinding()]
    param(
    #SPList Pipebind
    [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName, ParameterSetName="ListFromPipeline", position=0)]
    [Alias ('Title')]
    [Microsoft.SharePoint.SPList]$List
    )

    Begin
    {

    }

    Process
    {
        $CheckedOutFiles = @{}
        Write-Verbose "Getting checked out files"

        foreach( $File in ($List.Items | Where-Object { $_.file.checkoutstatus -ne "None"}))
        {
            $CheckedOutFiles.Add($File.url, $File)
        }

    }

    End
    {
        Return $CheckedOutFiles
    }

}



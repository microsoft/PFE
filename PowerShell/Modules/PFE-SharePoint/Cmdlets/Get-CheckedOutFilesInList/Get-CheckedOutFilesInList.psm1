
<#
Author: Roger Cormier
Company: Microsoft
Description: This cmdlet returns all checked out files in a list
#>
function Get-CheckedOutFilesInList
{
    [CmdletBinding()]
    param(
    [Parameter(HelpMessage="Represents the SPList binding", Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName, ParameterSetName="ListFromPipeline", position=0)]
    [Alias ('Title')]
    [Microsoft.SharePoint.SPList]$List
    )

    Begin
    {
        if($List -isnot [Microsoft.SharePoint.SPDocumentLibrary])
        {
            Write-Verbose "Referenced list `'$($List.title)`' is not a document library"
            exit
        }
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



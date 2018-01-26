function Get-SPAllUserInfo
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $Url
    )

    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

    $site = (Get-SPWeb $Url).Site
    $usersList = $site.RootWeb.Lists["User Information List"]

    $userInfo = @()

    foreach($userItem in $usersList.Items)
    {
        $xml = $userItem.Xml

        $createdDate = $null        
        $start = $xml.IndexOf("ows_Created", 0) + 13
        if($start -ge 13)
        {
            $end = $xml.IndexOf("'", $start)
            $createdDate = $xml.Substring($start, $end-$start)
        }

        $createdBy = $null
        $start = $xml.IndexOf("ows_Author", 0) + 12
        if($start -ge 12)
        {
            $end = $xml.IndexOf("'", $start)
            $createdBy = $xml.Substring($start, $end-$start)
        }

        $userInfo += @{
                        UserName = $useritem.Title
                        Created = [System.DateTime]$createdDate
                        CreatedBy = $createdBy
                     }
    }
    return $userInfo
}
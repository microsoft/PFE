# Description

This cmdlet takes in the name of a content database and the name of one of
the SharePoint servers in the farm, and sets that server to be the preferred
instance where to execute timer jobs against the Content Database from.

# Examples
The following example shows you how to set the same preferred timer job server
for all SharePoint Content Databases in your farm:

$spContentDatabases = Get-SPContentDatabase

foreach($db in $spContentDatabases)
{
    Set-SPContentDatabasePreferredTimerJobServer -Database $db.Name -Server "MyServer"
}

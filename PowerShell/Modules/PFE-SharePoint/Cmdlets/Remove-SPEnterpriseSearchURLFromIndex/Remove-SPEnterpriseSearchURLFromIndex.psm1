[CmdletBinding]
function Remove-SPEnterpriseSearchURLFromIndex
{
    param( 
        [System.String]
        $Url = "Default"
    )

    $ssas = Get-SPEnterpriseSearchServiceApplication

    foreach($ssa in $ssas)
    {
        $cl = New-Object Microsoft.Office.Server.Search.Administration.CrawlLog $ssa
        $logEntries = $cl.GetCrawledUrls($false,100,$Url,$true,-1,-1,-1,[System.DateTime]::MinValue, [System.DateTime]::MaxValue)

        foreach($logEntry in $logEntries.Rows)
        {
            Write-Host "You are about to remove " -NoNewline
            Write-Host $logEntry.FullUrl -ForegroundColor Green

            do{
                $deletionAnswer = Read-Host "Do you confirm the deletion (y/n)"
            }while($deletionAnswer.ToLower() -ne 'n' -and $deletionAnswer.ToLower() -ne 'y')

            switch($deletionAnswer)
            {
                'y'
                {
                    $catch = $cl.RemoveDocumentFromSearchResults($logEntry.FullUrl)
                    if($catch)
                    {
                        Write-Host "Deleted" -ForegroundColor Yellow
                    }
                    else
                    {
                        Write-Host "Could not delete the item" -ForegroundColor Red
                    }
                }
                'n'
                {
                    break
                }
            }
        }
    }
}
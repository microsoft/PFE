[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointStubsModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:TestHelper = New-UnitTestHelper -SharePointStubModule $SharePointStubsModule `
                                              -Cmdlet "Remove-SPEnterpriseSearchURLFromIndex"

Describe -Name $Global:TestHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:TestHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:TestHelper.InitializeScript -NoNewScope

        try { [Microsoft.Office.Server.Search.Administration] }
        catch 
        {
            try {
                Add-Type -TypeDefinition @"
                namespace Microsoft.Office.Server.Search.Administration
                {
                    public class CrawlLog
                    {
                        public CrawlLog(System.Object a)
                        {

                        }
                        public System.Collections.Generic.List<FakeJournal> GetCrawledUrls(System.Object a, System.Object b, System.Object c, System.Object d, System.Object e, System.Object f, System.Object g, System.Object h, System.Object i)
                        {
                            System.Collections.Generic.List<FakeJournal> CrawledUrls = new System.Collections.Generic.List<FakeJournal>();
                            CrawledUrls.Add(new FakeJournal());
                            return CrawledUrls;
                        }

                        public System.Boolean RemoveDocumentFromSearchResults(System.Object a)
                        {
                            return true;
                        }
                    }

                    public class FakeJournal
                    {
                        public System.Collections.Generic.List<FakeEntry> Rows = new System.Collections.Generic.List<FakeEntry>();
                        public FakeJournal()
                        {
                            Rows.Add(new FakeEntry());
                        }
                    }

                    public class FakeEntry
                    {
                        public string FullUrl;
                        public FakeEntry()
                        {
                            FullUrl = "http://sharepoint.contoso.com";
                        }
                    }
                }

"@ -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "The type Microsoft.Office.Server.Search.Administration.CrawlLog was already added."
            }
        }

        Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
            return @(
                @{
                    Name = "Search Service Application"
                }
            )
        }

        Context -Name "When the item is found and properly removed" -Fixture {
            
            $testParams = @{
                Url = "http://sharepoint.contoso.com"
            }

            It "Should not throw errors" {
                Remove-SPEnterpriseSearchURLFromIndex @testParams 
            }
        }        
    }
}

Invoke-Command -ScriptBlock $Global:TestHelper.CleanupScript -NoNewScope

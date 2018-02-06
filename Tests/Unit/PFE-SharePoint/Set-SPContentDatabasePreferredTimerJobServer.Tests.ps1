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
                                              -Cmdlet "Get-SPAllUserInfo"

Describe -Name $Global:TestHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:TestHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:TestHelper.InitializeScript -NoNewScope

        Mock -CommandName Get-SPSite -MockWith {
            return @{
                RootWeb = @{
                    Lists = @{
                        "User Information List" = @{
                            Items = @(
                                @{
                                    Title = "contoso\john.smith"
                                    Xml = "<xml ows_Created='2017-01-01' ows_author='contoso\john.smith'></xml>"
                                }
                            )   
                        }
                    }
                }
            }| Add-Member ScriptMethod Update {
            } -PassThru
        }

        Context -Name "When the User Info List is Found" -Fixture {
            
            $testParams = @{
                Url = "http://sharepoint.contoso.com"
            }

            It "Should return contoso\john.smith" {
                (Get-SPAllUserInfo @testParams).UserName | Should Be "contoso\john.smith"
            }
        }        
    }
}

Invoke-Command -ScriptBlock $Global:TestHelper.CleanupScript -NoNewScope

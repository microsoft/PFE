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
                                              -Cmdlet "Set-SPContentDatabasePreferredTimerJobServer"

Describe -Name $Global:TestHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:TestHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:TestHelper.InitializeScript -NoNewScope


        Context -Name "When the content database is found" -Fixture {
            Mock -CommandName Get-SPFarm -MockWith {
                return @{
                    TimerService = @{
                        Instances = @(
                            @{
                                Server = @{
                                    Address = "localhost"
                                }
                            }
                        )
                    }
                }
            }

            Mock -CommandName Get-SPContentDatabase -MockWith{
                return @{
                    PreferredTimerServiceInstance = "localhost";
                }| 
                Add-Member -MemberType ScriptMethod `
                -Name Update `
                -Value {
                } -PassThru
            }

            $testParams = @{
                Database = "WSS_Content"
                Server = "localhost"
            }

            It "Should properly assign the prefered server" {
                Set-SPContentDatabasePreferredTimerJobServer @testParams
            }
        }

        Context -Name "When the instance is not found" -Fixture {
            Mock -CommandName Get-SPFarm -MockWith {
                return @{
                    TimerService = @{
                        Instances = @()
                    }
                }
            }
            $testParams = @{
                Database = "WSS_Content"
                Server = "localhost"
            }

            It "Should properly assign the prefered server" {
                { Set-SPContentDatabasePreferredTimerJobServer @testParams } | Should Throw "A timer job service instance could not be found on server localhost"
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:TestHelper.CleanupScript -NoNewScope

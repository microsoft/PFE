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
                                              -Cmdlet "Get-RegistryCredential"

Describe -Name $Global:TestHelper.DescribeHeader -Fixture {

    $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
    $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                     -ArgumentList @("DOMAIN\username", $mockPassword)

    InModuleScope -ModuleName $Global:TestHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:TestHelper.InitializeScript -NoNewScope

        Mock -CommandName CheckForExistingRegistryCredential -MockWith {
            return $true
        }

        Mock -CommandName Get-ItemProperty -MockWith {
            return @{
                UserName = "contoso\john.smith"
                Password = "myuserpassword"
            }
        }

        Context -Name "When the User Info List is Found" -Fixture {
            
            $testParams = @{
                ApplicationName = "MyTestApplication"
                OrgName = "Contoso"
                AccountDescription = "JohnSmith"
            }

            It "Should return contoso\john.smith" {
                (Get-RegistryCredential @testParams).UserName | Should Be "contoso\john.smith"
            }
        }        
    }
}

Invoke-Command -ScriptBlock $Global:TestHelper.CleanupScript -NoNewScope

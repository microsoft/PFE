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
                Password = "01000000d08c9ddf0115d1118c7a00c04fc297eb01000000f`
                            74bf2f14b6cdf4586266f16f1dfac13000000000200000000`
                            0010660000000100002000000074cd73f55cadf2725bcb6443`
                            1d9edef3035d12505cdbf5d93501a128e1c06385000000000e`
                            8000000002000020000000c91bd5204db65776114afa3441a6`
                            d91b8bb10e109357a36a08ceb4c2ae7d795310000000c68944`
                            4aecd318866642e4d767f3b37f4000000024d0de35fd828a0b`
                            9e0a8ce4d4717a6bc58103287ea0b19b668cb04de85ba3a7e4`
                            12fa038452bea13b994db890a7511befbf4b7b738f91822dab`
                            8aa3869a4bed"
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

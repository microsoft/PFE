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
                                              -Cmdlet "New-RegistryCredential"

Describe -Name $Global:TestHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:TestHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:TestHelper.InitializeScript -NoNewScope

        Mock -CommandName New-Item -MockWith {}

        Mock -CommandName Get-ItemProperty -MockWith {
            return @{
                UserName = "contoso\john.smith"
                Password = "01000000d08c9ddf0115d1118c7a00c04fc297eb01000000f74bf2f14b6cdf4586266f16f1dfac130000000002000000000010660000000100002000000074cd73f55cadf2725bcb64431d9edef3035d12505cdbf5d93501a128e1c06385000000000e8000000002000020000000c91bd5204db65776114afa3441a6d91b8bb10e109357a36a08ceb4c2ae7d795310000000c689444aecd318866642e4d767f3b37f4000000024d0de35fd828a0b9e0a8ce4d4717a6bc58103287ea0b19b668cb04de85ba3a7e412fa038452bea13b994db890a7511befbf4b7b738f91822dab8aa3869a4bed"
            }
        }        

        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
        $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                     -ArgumentList @("contoso\john.smith", $mockPassword)

        Mock -CommandName ConvertTo-SecureString -MockWith {
            return $mockPassword
        }

        Context -Name "The credential already exists" -Fixture {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName CheckForExistingRegistryCredential -MockWith {
                return $true
            }

            $testParams = @{
                ApplicationName = "SharePoint"
                OrgName = "Microsoft"
                AccountDescription = "System Account"
            }

            It "Should throw an error about the credentials already existing" {
                { New-RegistryCredential @testParams } | Should Throw "Credential for account 'System Account' already exists in org 'Microsoft' for application 'SharePoint'"
            }
        }

        Context -Name "The credential were successfully created" -Fixture {

            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName CheckForExistingRegistryCredential -MockWith {
                return $false
            }

            Mock -CommandName Get-Credential -MockWith {
                return $mockCredential
            }

            $testParams = @{
                ApplicationName = "SharePoint"
                OrgName = "Microsoft"
                AccountDescription = "System Account"
            }

            It "Should return contoso\john.smith as a newly created credential set" {
                (New-RegistryCredential @testParams).UserName | Should Be "contoso\john.smith"
            }
        }

        Context -Name "The credentials don't exist, but the registry path does" -Fixture {

            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName CheckForExistingRegistryCredential -MockWith {
                return $false
            }

            Mock -CommandName Get-Credential -MockWith {
                return $mockCredential
            }

            $testParams = @{
                ApplicationName = "SharePoint"
                OrgName = "Microsoft"
                AccountDescription = "System Account"
            }

            It "Should throw an error saying it couldn't create the registry path" {
                { New-RegistryCredential @testParams } | Should Throw "Unable to create path 'KHCU:\Software\SharePoint\Microsoft\Credentials\System Account'."
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:TestHelper.CleanupScript -NoNewScope

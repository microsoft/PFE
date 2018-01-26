function CheckForExistingRegistryCredential
{
    [CmdletBinding()]
    param(
    [Parameter (Mandatory=$True, Position=0)]
    [String]$ApplicationName,

    [Parameter (Mandatory=$True, Position=1)]
    [String]$OrgName,
    
    [Parameter (Mandatory=$True, Position=2)]
    [String]$AccountDescription
    )

    Write-Verbose "Checking to see if a credential that matches the specified parameters already exists"
    $RegistryCredential = Test-Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)"
    return $RegistryCredential
}

function Get-RegistryCredential
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

    $CredentialExists = CheckForExistingRegistryCredential

    if($CredentialExists)
    {
        Write-Verbose "Credential object matching the parameters specified has been found`r`nRetrieving credential object from the registry"
        $CredentialUserName = (Get-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name "UserName" -ErrorAction SilentlyContinue).UserName
        $CredentialPassword = ConvertTo-SecureString (Get-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name "Password" -ErrorAction SilentlyContinue).Password
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($CredentialUserName, $CredentialPassword)
        if($Credential)
        {
            Write-Verbose "Credential `'$($AccountDescription)`' has been retrieved"
        }
        else
        {
            Write-Verbose "Could not create credential object using information stored in the registry at `'HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountName)`'"
            Write-Host "Credential `'$($AccountDescription)`' could not be retrieved" -ForegroundColor Yellow
        }
        Return $Credential
    }
    else
    {
        Write-Verbose "Could not locate credential object at `'HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)`'"
        Write-Host "No credentials could be found at the specified location"
    }
}
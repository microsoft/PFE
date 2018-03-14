Function New-RegistryCredential
{
    [CmdletBinding()]
    param(
        [Parameter (Mandatory=$True, Position=0)]
        [String]
        $ApplicationName,
        
        [Parameter (Mandatory=$True, Position=1)]
        [String]
        $OrgName,

        [Parameter (Mandatory=$True, Position=2)]
        [String]
        $AccountDescription,

        [Parameter (Mandatory=$False, Position=3)]
        [System.Management.Automation.PSCredential]
        $SecureCredential
    )


    $CredentialExists = CheckForExistingRegistryCredential -ApplicationName $ApplicationName `
                                                           -OrgName $OrgName `
                                                           -AccountDescription $AccountDescription

    if(!($CredentialExists))
    {
        Write-Verbose "Credential matching specified parameters does not exist`r`nOK to proceed"
        if($null -eq $SecureCredential)
        {
            $SecureCredential = Get-Credential -Message "Enter the service account credential in `'DOMAIN\Username`' or`' Username@Domain.com`' format"
            $SecurePasswordString = $SecureCredential.Password | ConvertFrom-SecureString
        }
        Write-Verbose "Captured credential for user `'$($SecureCredential.UserName)`'"
        
        Write-Verbose "Attempting to create path to store credential object"
        New-Item -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials" -Name "$($AccountDescription)" -Force
        if(Test-Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)")
        {
            Write-Verbose "Successfully created path `'HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescrioption)`' to store credential object"
        }
        else {
            throw "Unable to create path `'`KHCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)`'."
        }
        try
        {
            Write-Verbose "Attempting to store username and encrypted password to the registry"
            Set-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name Username -Value $SecureCredential.Username -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name Password -Value $($SecurePasswordString) -ErrorAction SilentlyContinue
            if(((Get-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name "UserName" -ErrorAction SilentlyContinue).UserName) -and ((Get-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name "Password" -ErrorAction SilentlyContinue).Password))
            {
                Write-Verbose "Successfully stored username and password to `'HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)`'"
            }
        }
        catch
        {
            throw "Could not commit values to registry`r`nCredential not saved"
        }
        Write-Verbose "Credential `'$($AccountDescription) has been created.`r`nUser `'$($SecureCredential.UserName)`' has been assigned"

    }
    else
    {
        throw "Credential for account '$AccountDescription' already exists in org '$OrgName' for application '$ApplicationName'"
    }
    
    return $SecureCredential
}
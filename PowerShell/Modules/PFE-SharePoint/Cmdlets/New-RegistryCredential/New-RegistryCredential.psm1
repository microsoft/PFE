Function New-RegistryCredential
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

    if(!($CredentialExists))
    {
        Write-Verbose "Credential matching specified parameters does not exist`r`nOK to proceed"
        $SecureCredential = Get-Credential -Message "Enter the service account credential in `'DOMAIN\Username`' or`' Username@Domain.com`' format"
        $SecurePasswordString = $SecureCredential.Password | ConvertFrom-SecureString
        Write-Verbose "Captured credential for user `'$($SecureCredential.UserName)`'"
        Try
        {
            Write-Verbose "Attempting to create path to store credential object"
            New-Item -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials" -Name "$($AccountDescription)" -Force
            if(Test-Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)")
            {
                Write-Verbose "Successfully created path `'HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescrioption)`' to store credential object"
            }
        }
        Catch
        {
            Write-Verbose "Unable to create the requested registry object"
            [System.Exception]
            Write-Host "Unable to create path `'`KHCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)`'." -Foreground Red
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
            Write-Verbose "Exception was encountered while storing username and encrypted password to the registry"
            [System.Exception]
            Write-Host "Could not commit values to registry`r`nCredential not saved" -ForegroundColor Red
        }
        Write-Verbose "Credential `'$($AccountDescription) has been created.`r`nUser `'$($SecureCredential.UserName)`' has been assigned"

    }
    else
    {
        Write-Verbose "Credential matching specified parameters already exists"
        Write-Host "Credential for account `'$($AccountDescription)`' already exists in org `'$($OrgName)`' for application `'$($ApplicationName)`'`r`nPlease review your parameters" -ForegroundColor Red
    }

    $Creds = Get-RegistryCredential -ApplicationName $ApplicationName -OrgName $OrgName -AccountDescription $AccountDescription
    Return $Creds
}

<#PSScriptInfo

.VERSION 1.0

.GUID 179d9e1a-4215-4cf2-975c-c3ab5071814b

.AUTHOR RCormier@Microsoft.com

.COMPANYNAME PFE

.COPYRIGHT None

.TAGS Registry Credential Security

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Initial Release: Contains only functionality to Store/Retrieve/Update/Delete Credentials stored in the registry

#>

<#

.DESCRIPTION
 This Script can be used to store and retrieve credential objects in the registry

#>
[CmdletBinding()]
param(
[Parameter (Mandatory=$True, Position=0)]
[String]$ApplicationName,
[Parameter (Mandatory=$True, Position=1)]
[String]$OrgName,
[Parameter (Mandatory=$True, Position=2)]
[String]$AccountDescription,
[Parameter (Mandatory=$True, Position=3)]
[ValidateSet("Create", "Read", "Update", "Delete")]
[String]$Operation = "Read"
)

function RetrieveCredentialObject
{
    Write-Host "Retrieving Credential Object from the registry" -ForegroundColor Cyan
    $CredentialUserName = (Get-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name "UserName" -ErrorAction SilentlyContinue).UserName
    $CredentialPassword = ConvertTo-SecureString (Get-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name "Password" -ErrorAction SilentlyContinue).Password
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($CredentialUserName, $CredentialPassword)
    if($Credential)
    {
        Write-Host "Credential `'$($AccountDescription)`' has been retrieved" -ForegroundColor Green
    }
    else
    {
        Write-Host "Credential `'$($AccountDescription)`' could not be retrieved" -ForegroundColor Yellow
    }
    Return $Credential
}

clear-Host

Write-Host "Secure Registry Credentail Tool`r`n_______________________________" -ForegroundColor Magenta

if($Operation -eq "Create")
{
    Write-Host "Creating new credential" -ForegroundColor Cyan
    $SecureCredential = Get-Credential -Message "Enter the service account credential in `'DOMAIN\Username`' or`' Username@Domain.com`' format"
    $SecurePasswordString = $SecureCredential.Password | ConvertFrom-SecureString
    Write-Host "Checking to see if credential `'$($AccountDescription)`' already exists" -ForegroundColor Cyan
    if(Test-Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)")
    {
        Write-Host "Credential $($AccountDescription) already exists in `'HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials`'`r`nCannot proceed with credential creation" -ForegroundColor Red
    }
    else
    {
        Write-Host "Creating credential `'$($AccountDescription)`'" -ForegroundColor Cyan
        Try
        {
            New-Item -Path "HKCU:\Software\$($ApplicationName)\$OrgName\Credentials" -Name "$($AccountDescription)" -Force
        }
        Catch
        {
            [System.Exception]
            Write-Host "Unable to create path `'`KHCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)`'." -Foreground Red
        }
        try
        {
            Set-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name Username -Value $SecureCredential.Username -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name Password -Value $($SecurePasswordString)
        }
        catch
        {
            [System.Exception]
            Write-Host "Could not commit values to registry`r`nCredential not saved" -ForegroundColor Red
        }
        Write-Host "Credential `'$($AccountDescription) has been created.`r`n User `'$($SecureCredential.UserName)`' has been assigned" -Foreground Green

    }
    $Creds = $SecureCredential
}
elseif($Operation -eq "Update")
{
    Write-Host "Updating existing credential" -ForegroundColor Cyan
    $SecureCredential = Get-Credential -Message "Enter the service account credential in `'DOMAIN\Username`' or`' Username@Domain.com`' format"
    $SecurePasswordString = $SecureCredential.Password | ConvertFrom-SecureString
    Write-Host "Checking to see if credential `'$($AccountDescription) already exists" -ForegroundColor Cyan
    if(Test-Path -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)")
    {
        Write-Host "Credential Found!" -ForegroundColor Green
        Set-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name UserName -Value $($SecureCredential.UserName)
        Set-ItemProperty -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -Name Password -Value $SecurePasswordString
        Write-Host "Successfully updated credential `'$($AccountDescription)`' to user `'$($SecureCredential.UserName)`'" -ForegroundColor Green
    }
    else
    {
        Write-Host "Account `'$($AccountDescription)`' does not exist in path `'HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials`'" -ForegroundColor Red
    }
    $Creds = $SecureCredential
}
elseif($Operation -eq "Delete")
{
    Write-Host "Requested deletion of existing credential`r`nChecking to see if credential $($AccountDescription) already exists" -ForegroundColor Cyan
    if(Test-Path -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)")
    {
        Try
        {
            Write-Host "Deleting existing credential `'$($AccountDescription)`'" -ForegroundColor Cyan
            Remove-Item -Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)"
            if(Test-Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)")
            {
                Write-Host "Deletion of credential `'$($AccountDescription)`' was unsuccessful" -ForegroundColor Red
            }
            else
            {
                Write-Host "Deletion of credential `'$($AccountDescription)`' was successful" -ForegroundColor Green
            }

        }
        Catch
        {
            [System.Exception]
            Write-Host "Could not remove registry key `'HKCU:\Software\$($ApplicationName)\$($OrgName)\Credentials\$($AccountDescription)" -ForegroundColor Red
        }
    }
    $Creds = $null
}
else
{
   if(Test-Path "HKCU:\Software\$($ApplicationName)\$($OrgName)\Credential\$($AccountDescription)")
   {
    $Creds = RetrieveCredentialObject
   }
   else
   {
        Write-Host "Credential `'$($AccountDescription)`' does not exist in path `'HKCU:\Software\$($ApplicationName)\$($OrgName)\Credential\`'" -ForegroundColor Yellow
   }


}

Return $Creds




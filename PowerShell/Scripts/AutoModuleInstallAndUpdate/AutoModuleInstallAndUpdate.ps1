
<#PSScriptInfo
.VERSION 0.7.0.0
.GUID 7f59e8ee-e3bd-4d72-88fe-24caf387e6f6
.AUTHOR Brian Lalancette (@brianlala)
.DESCRIPTION Automatically installs or updates PowerShell modules from the PowerShell Gallery
.COMPANYNAME Microsoft
.COPYRIGHT 2019 Brian Lalancette
.TAGS NuGet PowerShellGet
.LICENSEURI
.PROJECTURI https://github.com/Microsoft/PFE/tree/master/PowerShell/Scripts/AutoModuleInstallAndUpdate
.ICONURI
.EXTERNALMODULEDEPENDENCIES PowerShellGet
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.PRIVATEDATA
#>

<#
.SYNOPSIS
    Automatically installs or updates PowerShell modules from the PowerShell Gallery
.EXAMPLE
    AutoModuleInstallAndUpdate.ps1 -Confirm:$false -UpdateExistingInstalledModules
.EXAMPLE
    AutoModuleInstallAndUpdate.ps1 -ModulesToCheck Az,SharePointDSC -AllowPrerelease
.PARAMETER Confirm
    Prompts prior to updating an existing module or cleaning up files left over from old versions of modules.
.PARAMETER ModulesToCheck
    A comma-delimited list of modules to install or update.
.PARAMETER UpdateExistingInstalledModules
    Switch that indicates whether we should look for updates to any modules that are already installed on the current system. Disabled by default.
.PARAMETER AllowPrerelease
    Switch that indicates whether to allow installing or updating to prerelease module versions
.LINK
    https://github.com/Microsoft/PFE
.NOTES
    Created & maintained by Brian Lalancette (@brianlala), 2017-2019.
#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)][bool]$Confirm = $true,
    [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][array]$ModulesToCheck,
    [Parameter(Mandatory = $false)][switch]$UpdateExistingInstalledModules,
    [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][switch]$AllowPrerelease
)

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"

#requires -RunAsAdministrator
#requires -Version 5

# Install Chocolatey
# Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression

# If you get "Cannot process argument transformation on parameter 'InstalledModuleInfo'"
# Check https://powershell.org/forums/topic/unable-to-install-module-azurerm/ for a possible fix

# Clean up old variables
Remove-Variable -Name modulesInstalled -Scope Global -Force -ErrorAction SilentlyContinue
Remove-Variable -Name modulesUpdated -Scope Global -Force -ErrorAction SilentlyContinue
Remove-Variable -Name modulesUnchanged -Scope Global -Force -ErrorAction SilentlyContinue

if ($null -eq $ModulesToCheck)
{
    [array]$ModulesToCheck = @()
}
if ($UpdateExistingInstalledModules)
{
    foreach ($existingInstalledModule in (Get-InstalledModule))
    {
        Write-Verbose -Message " - Adding existing installed module '$($existingInstalledModule.Name)' to list of modules to update."
        $ModulesToCheck += $existingInstalledModule.Name
    }
}

try
{
    #region Pre-Checks
    if ($null -eq (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue))
    {
        # Install NuGet
        Write-Output " - Installing NuGet..."
        Install-PackageProvider -Name NuGet -Force -ForceBootstrap | Out-Null
    }
    if ($VerbosePreference -eq "Continue")
    {
        $verboseParameter = @{Verbose = $true}
        Write-Verbose -Message "`"Verbose`" parameter specified."
        $noNewLineSwitch = @{}
    }
    else
    {
        $verboseParameter = @{}
        $noNewLineSwitch = @{NoNewLine = $true}
    }
    if ($Confirm)
    {
        $confirmParameter = @{Confirm = $true}
        Write-Host -ForegroundColor Yellow "`"Confirm:`$true`" parameter specified or implied. Use -Confirm:`$false to skip confirmation prompts."
    }
    else
    {
        $confirmParameter = @{Confirm = $false}
    }
    if ($AllowPrerelease)
    {
        $AllowPrereleaseParameter = @{AllowPrerelease = $true}
    }
    else
    {
        $AllowPrereleaseParameter = @{}
    }
    Write-Output " - Checking for requested PowerShell modules..."
    # Because SkipPublisherCheck and AllowClobber parameters don't seem to be supported on Win2012R2 let's set whether the parameters are specified here
    if (Get-Command -Name Install-Module -ParameterName AllowClobber -ErrorAction SilentlyContinue)
    {
        $allowClobberParameter = @{AllowClobber = $true}
    }
    else
    {
        $allowClobberParameter = @{}
    }
    if (Get-Command -Name Install-Module -ParameterName SkipPublisherCheck -ErrorAction SilentlyContinue)
    {
        $skipPublisherCheckParameter = @{SkipPublisherCheck = $true}
    }
    else
    {
        $skipPublisherCheckParameter = @{}
    }
    #endregion
    foreach ($moduleToCheck in $ModulesToCheck)
    {
        Write-Host -ForegroundColor Cyan "  - Module: '$moduleToCheck'..."
        [array]$installedModules = Get-Module -ListAvailable -FullyQualifiedName $moduleToCheck
        if ($null -eq $installedModules)
        {
            # Install requested module since it wasn't detected
            $onlineModule = Find-Module -Name $moduleToCheck -ErrorAction SilentlyContinue
            if ($onlineModule)
            {
                Write-Host -ForegroundColor DarkYellow  "   - Module '$moduleToCheck' not present. Installing version $($onlineModule.Version)..." @noNewLineSwitch
                Install-Module -Name $moduleToCheck -ErrorAction Inquire -Force @allowClobberParameter @skipPublisherCheckParameter @verboseParameter
                if ($?)
                {
                    Write-Host -ForegroundColor Green "  Done."
                    [array]$global:modulesInstalled += $moduleToCheck
                }
            }
            else
            {
                Write-Host -ForegroundColor Yellow "   - Module '$moduleToCheck' not present, and was not found in the PowerShell Gallery for installation/update."
                [array]$global:modulesUnchanged += $moduleToCheck
            }
        }
        else
        {
            $installedModule = Get-InstalledModule -Name $moduleToCheck -ErrorAction SilentlyContinue
            if ($installedModule)
            {
                # If we were successful in querying the module this way it was probably originally installed from the Gallery
                $installedModuleWasFromGallery = $true
            }
            else # Was probably pre-installed or installed manually
            {
                # Grab the newest version in case there are multiple
                $installedModule = ($installedModules | Sort-Object Version -Descending)[0]
                $installedModuleWasFromGallery = $false
            }
            # Look for online updates to already-installed requested module
            Write-Host "   - Module '$moduleToCheck' version $($installedModule.Version) is already installed. Looking for updates..." @noNewLineSwitch
            $onlineModule = Find-Module -Name $moduleToCheck @AllowPrereleaseParameter -ErrorAction SilentlyContinue
            if ($null -eq $onlineModule)
            {
                Write-Host -ForegroundColor Yellow "Not found in the PowerShell Gallery!"
                [array]$global:modulesUnchanged += $moduleToCheck
            }
            else
            {
                # Get the last module
                if ($installedModule.Version -eq $onlineModule.version)
                {
                    # Online and local versions match; no action required
                    Write-Host -ForegroundColor Gray "Already up-to-date ($($installedModule.Version))."
                    [array]$global:modulesUnchanged += $moduleToCheck
                }
                else
                {
                    Write-Host -ForegroundColor Magenta "Newer version $($onlineModule.Version) found!"
                    if ($installedModule -and $installedModuleWasFromGallery)
                    {
                        # Update to newest online version using PowerShellGet
                        Write-Host "   - Updating module '$moduleToCheck'..." @noNewLineSwitch
                        Update-Module -Name $moduleToCheck -Force @confirmParameter @verboseParameter @AllowPrereleaseParameter -ErrorAction Continue
                        if ($?)
                        {
                            Write-Host -ForegroundColor Green "  Done."
                            [array]$global:modulesUpdated += $moduleToCheck
                        }
                    }
                    else
                    {
                        # Update won't work as it appears the module wasn't installed using the PS Gallery initially, so let's try a straight install
                        Write-Host "   - Installing '$moduleToCheck'..." @noNewLineSwitch
                        Install-Module -Name $moduleToCheck -Force @allowClobberParameter @skipPublisherCheckParameter @confirmParameter @verboseParameter @AllowPrereleaseParameter
                        if ($?)
                        {
                            Write-Host -ForegroundColor Green "  Done."
                            [array]$global:modulesUpdated += $moduleToCheck
                        }
                    }
                }
                # Now check if we have more than one version installed
                [array]$installedModules = Get-Module -ListAvailable -FullyQualifiedName $moduleToCheck
                if ($installedModules.Count -gt 1)
                {
                    # Remove all non-current module versions including ones that weren't put there via the PowerShell Gallery
                    [array]$oldModules = $installedModules | Where-Object {$_.Version -ne $onlineModule.Version}
                    foreach ($oldModule in $oldModules)
                    {
                        Write-Host "   - Uninstalling old version $($oldModule.Version) of '$($oldModule.Name)'..." @noNewLineSwitch
                        Uninstall-Module -Name $oldModule.Name -RequiredVersion $oldModule.Version -Force -ErrorAction SilentlyContinue @verboseParameter
                        if ($?) {Write-Host -ForegroundColor Green "  Done."}
                        # Unload the old module in case it was automatically loaded in this console
                        if (Get-Module -Name $oldModule.Name -ErrorAction SilentlyContinue)
                        {
                            Write-Host "   - Unloading prior loaded version $($oldModule.Version) of '$($oldModule.Name)'..." @noNewLineSwitch
                            Remove-Module -Name $oldModule.Name -Force -ErrorAction Inquire @verboseParameter
                            if ($?) {Write-Host -ForegroundColor Green "  Done."}
                        }
                        # Comment this out if it actually removes the module we've just installed/updated...
                        Write-Host "   - Removing old module files from $($oldModule.ModuleBase)..." @noNewLineSwitch
                        Remove-Item -Path $oldModule.ModuleBase -Recurse -ErrorAction SilentlyContinue @confirmParameter @verboseParameter
                        if ($?) {Write-Host -ForegroundColor Green "Done."}
                        else
                        {
                            Write-Host "."
                        }
                    }
                }
            }
        }
        $installedModule = Get-InstalledModule -Name $moduleToCheck -ErrorAction SilentlyContinue
        if ($null -eq $installedModule)
        {
            # Module was not installed from the Gallery, so we look for it an alternate way
            $installedModule = Get-Module -Name $moduleToCheck -ListAvailable | Sort-Object Version | Select-Object -Last 1
        }
        Write-Host -ForegroundColor Cyan "  - Done checking/installing module '$moduleToCheck'."
        Write-Output "  --"
        # Clean up the variables
        Remove-Variable -Name installedModules -ErrorAction SilentlyContinue
        Remove-Variable -Name installedModule -ErrorAction SilentlyContinue
        Remove-Variable -Name oldModules -ErrorAction SilentlyContinue
        Remove-Variable -Name oldModule -ErrorAction SilentlyContinue
        Remove-Variable -Name onlineModule -ErrorAction SilentlyContinue
    }
    Write-Host -ForegroundColor DarkCyan " - Done checking/installing requested modules."
    Write-Output "  --"
}
catch
{
    Write-Host -ForegroundColor Red $_.Exception
    Write-Error "Unable to download/install '$moduleToCheck' - check Internet access etc."
}
finally
{
    if ($global:modulesInstalled.Count -ge 1)
    {
        Write-Host -ForegroundColor Cyan " - Modules Installed:"
        foreach ($moduleInstalled in $global:modulesInstalled)
        {
            Write-Host -ForegroundColor Green "  - $moduleInstalled"
        }
    }
    if ($global:modulesUpdated.Count -ge 1)
    {
        Write-Host -ForegroundColor Cyan " - Modules Updated:"
        foreach ($moduleUpdated in $global:modulesUpdated)
        {
            Write-Host -ForegroundColor Magenta "  - $moduleUpdated"
        }
    }
    if ($global:modulesUnchanged.Count -ge 1)
    {
        Write-Host -ForegroundColor Cyan " - Unchanged Modules:"
        foreach ($moduleUnchanged in $global:modulesUnchanged)
        {
            Write-Host -ForegroundColor Gray "  - $moduleUnchanged"
        }
    }
    if (!$global:modulesInstalled -and !$global:modulesUpdated)
    {
        Write-Host -ForegroundColor Gray " - No modules were installed or updated."
    }
}
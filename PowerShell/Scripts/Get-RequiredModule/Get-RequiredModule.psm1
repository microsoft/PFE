<#
.SYNOPSIS
    <TODO>
.DESCRIPTION
    <TODO>
.EXAMPLE
    <TODO>
.EXAMPLE
    <TODO>
.PARAMETER Confirm
    <TODO>
.PARAMETER ModuleName
    <TODO>
.LINK
    https://github.com/Microsoft/PFE
.NOTES
    Created & maintained by Brian Lalancette (@brianlala), 2017-2017.
#>

function Get-RequiredModule
{
    [CmdletBinding()]
    param
    (
        [bool]$Confirm = $true,
        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$ModuleName
    )

    #requires -RunAsAdministrator
    #requires -Version 5

    # Install Chocolatey
    # Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression

    # If you get "Cannot process argument transformation on parameter 'InstalledModuleInfo'"
    # Check https://powershell.org/forums/topic/unable-to-install-module-azurerm/ for a possible fix

    # Clean up old variables
    Remove-Variable -Name modulesInstalled -Scope Global -Force -ErrorAction SilentlyContinue
    Remove-Variable -Name modulesUpdated -Scope Global -Force -ErrorAction SilentlyContinue

    try
    {
        if ($null -eq (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue))
        {
            # Install NuGet
            Write-Output " - Installing NuGet..."
            Install-PackageProvider -Name NuGet -Force -ForceBootstrap | Out-Null
        }
        # If we specified a single module name on the command-line, just get/update that one
        if (!([string]::IsNullOrEmpty($ModuleName)))
        {
            [array]$requiredModules = $ModuleName
        }
        # Otherwise use this list of modules to get/update
        else
        {
            [array]$requiredModules =   "PowerShellGet",
                                        "PackageManagement",
                                        "xCredSSP",
                                        "xStorage",
                                        "SharePointDSC",
                                        "Azure",
                                        "AzureRM",
                                        "AzureAD",
                                        "AzurePSDrive",
                                        "MSOnline",
                                        "ConnectO365",
                                        "CredentialManager",
                                        "AADRM",
                                        "xActiveDirectory",
                                        "xNetworking",
                                        "xWebAdministration",
                                        "PSDesiredStateConfiguration",
                                        "SharePointPnPPowerShellOnline",
                                        "SharePointPnPPowerShell2013",
                                        "SharePointPnPPowerShell2016",
                                        "DscStudio",
                                        "ReverseDSC",
                                        "SharePointDSC.Reverse",
                                        "SharePointOnboardingAccelerator",
                                        "SharePointPatches",
                                        "SqlServer",
                                        "MicrosoftTeams"
        }
        if ($VerbosePreference -eq "Continue")
        {
            $verboseParameter = @{Verbose = $true}
            Write-Verbose -Message "`"Verbose`" parameter specified."
        }
        else
        {
             $verboseParameter = @{}
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
        Write-Output " - Checking for required PowerShell modules..."
        # Because SkipPublisherCheck and AllowClobber parameters don't seem to be supported on Win2012R2 let's set whether the parameters are specified here
        if (Get-Command -Name Install-Module -ParameterName AllowClobber -ErrorAction SilentlyContinue)
        {
            $allowClobberParameter = @{AllowClobber = $true}
        }
        else {$allowClobberParameter = @{}}
        if (Get-Command -Name Install-Module -ParameterName SkipPublisherCheck -ErrorAction SilentlyContinue)
        {
            $skipPublisherCheckParameter = @{SkipPublisherCheck = $true}
        }
        else {$skipPublisherCheckParameter = @{}}
        foreach ($requiredModule in $requiredModules)
        {
            Write-Host -ForegroundColor Cyan "  - Module: `"$requiredModule`"..."
            [array]$installedModules = Get-Module -ListAvailable -FullyQualifiedName $requiredModule
            if ($null -eq $installedModules)
            {
                # Install required module since it wasn't detected
                $onlineModule = Find-Module -Name $requiredModule -ErrorAction SilentlyContinue
                if ($onlineModule)
                {
                    Write-Host -ForegroundColor DarkYellow  "   - Module $requiredModule not present. Installing version $($onlineModule.Version)..." #-NoNewline
                    Install-Module -Name $requiredModule -ErrorAction Inquire -Force @allowClobberParameter @skipPublisherCheckParameter @verboseParameter
                    if ($?)
                    {
                        Write-Host -ForegroundColor Green "   - Done."
                        [array]$global:modulesInstalled += $requiredModule
                    }
                }
                else
                {
                    Write-Host -ForegroundColor Yellow "   - Module $requiredModule not present, and was not found in the PowerShell Gallery for installation/update."
                }
            }
            else
            {
                $installedModule = Get-InstalledModule -Name $requiredModule -ErrorAction SilentlyContinue
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
                # Look for online updates to already-installed required module
                Write-Host "   - Module $requiredModule version $($installedModule.Version) is already installed. Looking for updates..." -NoNewline
                $onlineModule = Find-Module -Name $requiredModule -ErrorAction SilentlyContinue
                if ($null -eq $onlineModule)
                {
                    Write-Host -ForegroundColor Yellow "Not found in the PowerShell Gallery!"
                }
                else
                {
                    # Get the last module
                    if ($installedModule.Version -eq $onlineModule.version)
                    {
                        # Online and local versions match; no action required
                        Write-Host -ForegroundColor Gray "Already up-to-date ($($installedModule.Version))."
                    }
                    else
                    {
                        Write-Host -ForegroundColor Magenta "Newer version $($onlineModule.Version) found!"
                        if ($installedModule -and $installedModuleWasFromGallery)
                        {
                            # Update to newest online version using PowerShellGet
                            Write-Host "   - Updating module $requiredModule..." #-NoNewline
                            Update-Module -Name $requiredModule -Force -ErrorAction Continue @confirmParameter @verboseParameter
                            if ($?)
                            {
                                Write-Host -ForegroundColor Green "   - Done."
                                [array]$global:modulesUpdated += $requiredModule
                            }
                        }
                        else
                        {
                            # Update won't work as it appears the module wasn't installed using the PS Gallery initially, so let's try a straight install
                            Write-Host "   - Installing $requiredModule..." #-NoNewline
                            Install-Module -Name $requiredModule -Force @allowClobberParameter @skipPublisherCheckParameter @confirmParameter @verboseParameter
                            if ($?)
                            {
                                Write-Host -ForegroundColor Green "   - Done."
                                [array]$global:modulesUpdated += $requiredModule
                            }
                        }
                    }
                    # Now check if we have more than one version installed
                    [array]$installedModules = Get-Module -ListAvailable -FullyQualifiedName $requiredModule
                    if ($installedModules.Count -gt 1)
                    {
                        # Remove all non-current module versions including ones that weren't put there via the PowerShell Gallery
                        [array]$oldModules = $installedModules | Where-Object {$_.Version -ne $onlineModule.Version}
                        foreach ($oldModule in $oldModules)
                        {
                            Write-Host "   - Uninstalling old version $($oldModule.Version) of $($oldModule.Name)..." #-NoNewline
                            Uninstall-Module -Name $oldModule.Name -RequiredVersion $oldModule.Version -Force -ErrorAction SilentlyContinue @verboseParameter
                            if ($?) {Write-Host -ForegroundColor Green "   - Done."}
                            # Unload the old module in case it was automatically loaded in this console
                            if (Get-Module -Name $oldModule.Name -ErrorAction SilentlyContinue)
                            {
                                Write-Host "   - Unloading prior loaded version $($oldModule.Version) of $($oldModule.Name)..." -NoNewline
                                Remove-Module -Name $oldModule.Name -Force -ErrorAction Inquire @verboseParameter
                                if ($?) {Write-Host -ForegroundColor Green "   - Done."}
                            }
                            Write-Host "   - Removing old module files from $($oldModule.ModuleBase)..." -NoNewline
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
            $installedModule = Get-InstalledModule -Name $requiredModule -ErrorAction SilentlyContinue
            if ($null -eq $installedModule)
            {
                # Module was not installed from the Gallery, so we look for it an alternate way
                $installedModule = Get-Module -Name $requiredModule -ListAvailable | Sort-Object Version | Select-Object -Last 1
            }
            Write-Host -ForegroundColor Cyan "  - Done checking/installing module $requiredModule."
            Write-Output "  --"
            # Clean up the variables
            Remove-Variable -Name installedModules -ErrorAction SilentlyContinue
            Remove-Variable -Name installedModule -ErrorAction SilentlyContinue
            Remove-Variable -Name oldModules -ErrorAction SilentlyContinue
            Remove-Variable -Name oldModule -ErrorAction SilentlyContinue
            Remove-Variable -Name onlineModule -ErrorAction SilentlyContinue
        }
        Write-Host -ForegroundColor DarkCyan " - Done checking/installing required modules."
    }
    catch
    {
        Write-Host -ForegroundColor Red $_.Exception
        Write-Error "Unable to download/install $requiredModule - check Internet access etc."
    }
    finally
    {
        if ($global:modulesInstalled.Count -ge 1)
        {
            Write-Host -ForegroundColor Green " - Modules Installed:"
            foreach ($moduleInstalled in $global:modulesInstalled)
            {
                Write-Host -ForegroundColor DarkGreen "  - $moduleInstalled"
            }
        }
        if ($global:modulesUpdated.Count -ge 1)
        {
            Write-Host -ForegroundColor Magenta " - Modules Updated:"
            foreach ($moduleUpdated in $global:modulesUpdated)
            {
                Write-Host -ForegroundColor Magenta "  - $moduleUpdated"
            }
        }
        if (!$global:modulesInstalled -and !$global:modulesUpdated)
        {
            Write-Host -ForegroundColor Gray " - No modules were installed or updated."
        }
    }
}
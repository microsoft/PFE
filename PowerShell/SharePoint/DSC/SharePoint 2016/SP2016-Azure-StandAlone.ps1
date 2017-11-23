Configuration SP2016AzureStandalone
{
    param(
        [String]$ParamDomain,
        [String]$ParamInternalDomainControllerIP,
        [String]$ParamMachineName,
        [String]$ParamSQLServerShare,
        [String]$ParamSPInstallShare,
        [String]$ParamSPLPInstallShare,
        [String]$ParamSPCUInstallFile,
        [String]$ParamVSInstallShare,
        [String]$ParamSPProductKey
 	)

    Import-DscResource –ModuleName "PSDesiredStateConfiguration"
    Import-DSCResource -ModuleName "xDSCDomainJoin" -ModuleVersion "1.1"
    Import-DSCResource -ModuleName "xNetworking" -ModuleVersion "5.3.0.0" 
    Import-DSCResource -ModuleName "xSQLServer" -ModuleVersion "9.0.0.0"
    Import-DSCResource -ModuleName "SharePointDSC" -ModuleVersion "1.9.0.0"    
    Import-DscResource -ModuleName "VisualStudioDSC" -ModuleVersion "1.0.0.10"

    $ParamCredsJoindomain = Get-AutomationPSCredential -Name "DomainAdmin"
    $ParamCredsSPFarmAccount = Get-AutomationPSCredential -Name "SPAdmin"
    $ParamCredsSPPassPhrase = Get-AutomationPSCredential -Name "SPPassPhrase"
        
    Node $ParamMachineName
    {

<# --------------------------------------------------- #>
<#      Add Windows Features 
<# --------------------------------------------------- #>

        WindowsFeature NetFramework35Core
        {
            Name = "NET-Framework-Core"
            Ensure = "Present"
        }
 
        WindowsFeature NetFramework45Core
        {
            Name = "NET-Framework-45-Core"
            Ensure = "Present"
        }

<# --------------------------------------------------- #>
<#      Configure Networking 
<# --------------------------------------------------- #>

        xFirewall SQLFirewallRule
        {
            Name = "AllowSQLConnectionDSC"
            DisplayName = 'Allow SQL Connection' 
            Group = 'DSC Configuration Rules' 
            Ensure = 'Present' 
            Enabled = 'True' 
            Profile = ('Domain') 
            Direction = 'InBound' 
            LocalPort = ('1433') 
            Protocol = 'TCP' 
            Description = 'Firewall Rule to allow SQL communication' 
        }

        xDNSServerAddress DNS
	{
	    Address = $ParamInternalDomainControllerIP
	    AddressFamily = "IPv4"
	    InterfaceAlias = "Ethernet"
            DependsOn = "[WindowsFeature]NetFramework35Core"
	}

<# --------------------------------------------------- #>
<#      Join Domain 
<# --------------------------------------------------- #>

	xDSCDomainJoin Join
	{
	    Domain = $ParamDomain
	    Credential = $ParamCredsJoindomain
	    DependsOn = "[xDNSServerAddress]DNS"
	}

        Group AddToAdmin
        {
            GroupName = "Administrators"
            Ensure = "Present"
            MembersToInclude = $ParamCredsSPFarmAccount.UserName
            Credential = $ParamCredsJoindomain
            PsDSCRunAsCredential = $ParamCredsJoindomain
	    DependsOn = "[xDSCDomainJoin]Join"
        }

<# --------------------------------------------------- #>
<#      Install and Configure SQL Server 
<# --------------------------------------------------- #>

        xSQLServerSetup SQL2016Setup
        {
            InstanceName = 'MSSQLServer'
            SourcePath = $ParamSQLServerShare
            Features = 'SQLENGINE,FULLTEXT'
            InstallSharedDir = 'C:\Program Files\Microsoft SQL Server'
            SQLSysAdminAccounts = @($ParamCredsJoindomain.UserName, $ParamCredsSPFarmAccount.UserName)
            DependsOn = '[xDSCDomainJoin]Join'
        }

<# --------------------------------------------------- #>
<#      Install SharePoint Server 2016 
<# --------------------------------------------------- #>

        SPInstallPrereqs SP2016PreReqs
        {
            InstallerPath = "$ParamSPInstallShare\prerequisiteinstaller.exe"
            OnlineMode = $true
            DependsOn = "[xSQLServerSetup]SQL2016Setup"
        }

        SPInstall InstallSharePoint 
        { 
             Ensure = "Present" 
             BinaryDir = "$ParamSPInstallShare\" 
             ProductKey = $ParamSPProductKey
             DependsOn = @("[SPInstallPrereqs]SP2016PreReqs", "[xFirewall]SQLFirewallRule")
        }

<# --------------------------------------------------- #>
<#      Install SharePoint 2013 Language Packs 
<# --------------------------------------------------- #>
 
        SPInstallLanguagePack InstallSharePointFrenchLP 
        { 
             BinaryDir = "$ParamSPLPInstallShare\French\" 
             Ensure = "Present" 
             PsDSCRunAsCredential = $ParamCredsSPFarmAccount
             DependsOn = "[SPInstall]InstallSharePoint"
        }
        
<# --------------------------------------------------- #>
<#      Create SharePoint Farm 
<# --------------------------------------------------- #>

        SPFarm CreateSPFarm 
        { 
            Ensure = "Present"
            DatabaseServer = $ParamMachineName
            FarmConfigDatabaseName = "SP_Config"
            Passphrase = $ParamCredsSPPassPhrase
            FarmAccount = $ParamCredsSPFarmAccount
            AdminContentDatabaseName = "DW_Content_Admin" 
            PsDSCRunAsCredential = $ParamCredsSPFarmAccount
            RunCentralAdmin = $true
            CentralAdministrationPort = 2016
            CentralAdministrationAuth = "NTLM"
            DependsOn = @("[SPInstall]InstallSharePoint", "[Group]AddToAdmin", "[SPInstallLanguagePack]InstallSharePointFrenchLP") 
        }
<# --------------------------------------------------- #>
<#      Install SharePoint Updates 
<# --------------------------------------------------- #>

        SPProductUpdate InstallSharePointCU 
        { 
             SetupFile = $ParamSPCUInstallFile
             ShutdownServices = $false 
             Ensure = "Present" 
             PsDSCRunAsCredential = $ParamCredsSPFarmAccount
             DependsOn = "[SPFarm]CreateSPFarm"
        }

<# --------------------------------------------------- #>
<#      Run PSConfig to Commit Updates 
<# --------------------------------------------------- #>

        SPConfigWizard CommitSharePointCU 
        {
             Ensure = "Present" 
             PsDSCRunAsCredential = $ParamCredsSPFarmAccount
             DependsOn = "[SPProductUpdate]InstallSharePointCU"
        }

<# --------------------------------------------------- #>
<#      Create Managed Accounts 
<# --------------------------------------------------- #>

        SPManagedAccount FarmAccount
        {
            AccountName = $ParamCredsSPFarmAccount.UserName
            Account = $ParamCredsSPFarmAccount
            PsDSCRunAsCredential = $ParamCredsSPFarmAccount
            Ensure = "Present"
            EmailNotification = 5;
            Schedule = "";
            PreExpireDays = 2;
            DependsOn = "[SPConfigWizard]CommitSharePointCU"
        }

<# --------------------------------------------------- #>
<#      Create Application Pools 
<# --------------------------------------------------- #>

        SPServiceAppPool SecurityTokenServiceApplicationPool
        {
            Name = "SecurityTokenServiceApplicationPool";
            PsDscRunAsCredential = $ParamCredsSPFarmAccount;
            ServiceAccount = $ParamCredsSPFarmAccount.UserName;
            DependsOn = "[SPManagedAccount]FarmAccount"
            Ensure = "Present";
        }
        
        SPServiceAppPool SharePointHostedServices
        {
            Name = "SharePoint Hosted Services";
            PsDscRunAsCredential = $ParamCredsSPFarmAccount;
            ServiceAccount = $ParamCredsSPFarmAccount.UserName;
            DependsOn = "[SPManagedAccount]FarmAccount"
            Ensure = "Present";
        }
        
        SPServiceAppPool SharePointSearchApplicationPool
        {
            Name = "SharePoint Search Application Pool";
            PsDscRunAsCredential = $ParamCredsSPFarmAccount;
            ServiceAccount = $ParamCredsSPFarmAccount.UserName;
            DependsOn = "[SPManagedAccount]FarmAccount"
            Ensure = "Present";
        }
        
        SPServiceAppPool SharePointWebServicesSystem
        {
            Name = "SharePoint Web Services System";
            PsDscRunAsCredential = $ParamCredsSPFarmAccount;
            ServiceAccount = $ParamCredsSPFarmAccount.UserName;
            DependsOn = "[SPManagedAccount]FarmAccount"
            Ensure = "Present";
        }

<# --------------------------------------------------- #>
<#      Configure SharePoint Farm
<# --------------------------------------------------- #>

        SPDiagnosticLoggingSettings ApplyDiagnosticLogSettings
        {
            ErrorReportingAutomaticUploadEnabled = $False;
            ScriptErrorReportingRequireAuth = $True;
            DownloadErrorReportingUpdatesEnabled = $False;
            LogSpaceInGB = 1000;
            DaysToKeepLogs = 14;
            ScriptErrorReportingEnabled = $False;
            EventLogFloodProtectionTriggerPeriod = 2;
            AppAnalyticsAutomaticUploadEnabled = $False;
            EventLogFloodProtectionThreshold = 5;
            EventLogFloodProtectionNotifyInterval = 5;
            CustomerExperienceImprovementProgramEnabled = $False;
            LogPath = "C:\Logs\SharePoint";
            LogCutInterval = 30;
            ErrorReportingEnabled = $False;
            ScriptErrorReportingDelay = 60;
            EventLogFloodProtectionQuietPeriod = 2;
            EventLogFloodProtectionEnabled = $True;
            LogMaxDiskSpaceUsageEnabled = $False;
            PsDscRunAsCredential = $ParamCredsSPFarmAccount;
            DependsOn = "[SPManagedAccount]FarmAccount"
        }

        SPAntivirusSettings AntivirusSettings
        {
            ScanOnUpload = $False;
            NumberOfThreads = 5;
            AllowDownloadInfected = $True;
            AttemptToClean = $False;
            ScanOnDownload = $False;
            TimeoutDuration = 300;
            PsDscRunAsCredential = $ParamCredsSPFarmAccount;
            DependsOn = "[SPManagedAccount]FarmAccount"
        }

        SPFarmAdministrators SharePointAdministrators
        {
            Members = @("BUILTIN\administrators",$ParamCredsSPFarmAccount.UserName);
            MembersToInclude = @("");
            Name = "SPFarmAdministrators";
            MembersToExclude = @("");
            PsDscRunAsCredential = $ParamCredsSPFarmAccount;
            DependsOn = "[SPManagedAccount]FarmAccount"
        }

<# --------------------------------------------------- #>
<#      Install Visual Studio 2017 
<# --------------------------------------------------- #>

        VSInstall VS2017
        {
            ExecutablePath = "$ParamVSInstallShare\mu_visual_studio_enterprise_2017.exe"
            InstallAccount = $ParamCredsJoindomain
            Workloads = @("Microsoft.VisualStudio.Component.CoreEditor", "Microsoft.VisualStudio.Workload.NetWeb", "Microsoft.VisualStudio.Workload.Office")
            PsDscRunAsCredential = $ParamCredsJoindomain
            Ensure = "Present"
        }

    }
}


function CheckForExistingRegistryCredential { 
  [CmdletBinding(DefaultParameterSetName='Default')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${ApplicationName},

    [Parameter(Mandatory=$true)]
    [string]
    ${OrgName},

    [Parameter(Mandatory=$true)]
    [string]
    ${AccountDescription})

 
 } 


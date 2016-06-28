<# 

           Reset O365 MSP Tenant Admin Passwords
    Date created:                      11/25/15
    Date modified:                     
    Author:                            Eric Martinez

    Goal:

    Easy change the password for all O365 Tenant Admin accounts
    used with the Connect-O365 script.

    Variables:
    $msp_admin = Company Administrator account in tenants. 
                 This is the name of your Company 
                 Administrator account that you use to  
                 manage your tenants accounts. This
                 account is specific to each tenant.

    $msp_name  = The name of your organization.

    Usage:

    1) Set variables in the SET THESE VARIABLES section. This should be a global admin of your O365 tenants
    2) Execute script.
    3) Specify password the accounts to be changed to.

#> 

###SET THESE VARIABLES
$msp_adminr = "mspadmin"
$msp_namer = "MSP_NAME"
###SET THESE VARIABLES

#Checks to see if you're running as an Administrator
function Check-Administrator
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

function Reset-TenantPasswords
    {
    try
        {
        #Connect to Microsoft Online
        Connect-MsolService -Credential $credential -ErrorAction Stop
        }
    catch [Microsoft.Online.Administration.Automation.MicrosoftOnlineException]
        {
        Write-Host "Your credentials are bogus, dude. No bueno." -ForegroundColor Red
        Start-Sleep 4
        }

    #Select All Tenants
    $o365tenantsr = Get-MsolPartnerContract | Select *

    #Specify New MSP Admin Account Password
    $tenantPasswordr = Read-Host "I'm about to reset all Tenant $msp_namer Office 365 Administrator account passwords. What password should I use? (8-16 Complex Characters)"

    #Reset Passwords
foreach ($i in $o365tenantsr)
        {
        $OrgNamer = Get-MsolCompanyInformation -TenantId $i.TenantId | select -exp DisplayName
        $defaultDomainr = $i.DefaultDomainName
        try
            {
            Set-MsolUserPassword -userPrincipalName $msp_adminr@$defaultDomainr -NewPassword $tenantPasswordr -ForceChangePassword $false -TenantId $i.tenantId -ErrorAction Stop
            Write-Host "$msp_namer Office 365 Administrator password changed for $OrgNamer." -ForegroundColor Cyan
            }
        catch [Microsoft.Online.Administration.Automation.MicrosoftOnlineException]
            {
            Write-Host "$msp_namer Office 365 Administrator does not exist for $OrgNamer." -ForegroundColor Red
            }
        }
    }

#Gather Credentials for Office 365 Partner
Import-Module MsOnline
$credential = Get-Credential


#Make it rain $$$
Reset-TenantPasswords
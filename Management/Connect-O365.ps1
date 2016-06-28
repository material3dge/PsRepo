<# 

                O365 Tenant Management
    Date created:                      11/23/15
    Date modified:                     11/25/15
    Author:                            Eric Martinez

    Goal:

    Designed for Managed Services Providers to easily move
    between tenant accounts within the Office 365 service
    offering. Provides access to all O365 modules including
    Exhange Online, SharePoint Online, Admin Center, 
    Compliance Center, and Skype for Business Online.

    Variables:
    $msp_admin = Company Administrator accounts to be created
                 in tenants. This will be the name of your 
                 Company Administrator account that you'll 
                 use to manage your tenants accounts. This
                 account is specific to each tenant.
    $msp_name  = The name of your organization.

    Usage:

    1) Set variables in the SET THESE VARIABLES section
    2) Execute script
    3) Once connected to a tenant, use the command Cheese-It
       to drop back to the tenant selection menu. This also
       disconnects your sessions to the previous tenant.

#> 

###SET THESE VARIABLES
$msp_admin = "mspadmin"
$msp_name = "MSP_NAME"
###SET THESE VARIABLES

#Drop to Tenant List
function Cheese-It
{  
    Get-PSSession | Remove-PSSession
    $host.ui.RawUI.WindowTitle = "No Active Connections. Viewing the Tenant list now."
    Connect-O365
}

#Checks to see if you're running as an Administrator
function Check-Administrator
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

#Builds Menu from Tenant Accounts
function Select-ItemFromList 
{ 
[CmdletBinding()] 
PARAM  
( 
    [Parameter(Mandatory=$true)] 
    $options, 
    [string]$displayProperty, 
    [string]$title = "Select Office 365 Tenant to manage:", 
    [ValidateSet("Menu","ListBox","CheckedListBox")] 
    [string]$mode = "Menu", 
    [System.Windows.Forms.SelectionMode]$selectionMode = [System.Windows.Forms.SelectionMode]::One 
) 
    $script:selectedItem = $null 
    $selectMultiple = ($selectionMode -eq [System.Windows.Forms.SelectionMode]::MultiSimple -or $selectionMode -eq [System.Windows.Forms.SelectionMode]::MultiExtended) 
    [Windows.Forms.form]$form = new-object Windows.Forms.form 
 
    function BuildMenu 
    { 
    PARAM  
    ( 
        [Parameter(Mandatory=$true)] 
        $options, 
        [string]$displayProperty, 
        [string]$title = "Select Item" 
    ) 
        [int]$optionPrefix = 1 
        $selectMultiple = ($selectionMode -eq [System.Windows.Forms.SelectionMode]::MultiSimple -or $selectionMode -eq [System.Windows.Forms.SelectionMode]::MultiExtended) 
        [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder 
        $sb.Append([Environment]::NewLine + $title + [Environment]::NewLine + [Environment]::NewLine) | Out-Null 
         
        foreach ($option in $options) 
        { 
            if ([String]::IsNullOrEmpty($displayProperty)) 
            { 
                $sb.Append(("{0,3}: {1}" -f $optionPrefix,$option) + [Environment]::NewLine) | Out-Null 
            } 
            else 
            { 
                $sb.Append(("{0,3}: {1}" -f $optionPrefix,$option.$displayProperty) + [Environment]::NewLine) | Out-Null 
            } 
            $optionPrefix++ 
        } 
        $sb.Append([Environment]::NewLine) | Out-Null 
        return $sb.ToString() 
    } 
         
    switch($mode.ToLower())  
    { 
        "menu" 
            { 
                [string]$menuText = BuildMenu -options $options -DisplayProperty $displayProperty -title $title 
                Write-Host $menuText 
                [string]$responseString = Read-Host "Enter Selection" 
                if (-not [String]::IsNullOrEmpty($responseString)) 
                { 
                    $script:selectedItem = $null 
                    [int]$index = 0 
                    if ($selectMultiple) 
                    { 
                        $responses = $responseString.Split(',') 
                        foreach ($response in $responses) 
                        { 
                            $index = [int]$response 
                            if ($response -gt 0 -and $response -le $options.Count) 
                            { 
                                if ($script:selectedItem -eq $null) 
                                { 
                                    $script:selectedItem = @($options[$response-1]) 
                                } 
                                else 
                                { 
                                    $script:selectedItem += $options[$response-1] 
                                } 
                            } 
                        } 
                    } 
                    else 
                    { 
                        $index = [int]$responseString 
                        $script:selectedItem = @($options[$index-1]) 
                    } 
                     
                } 
            } 
    } 
    Write-Output $script:selectedItem 
} 

function Connect-O365
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
        Connect-O365
        }

    #Select Tenant
    $o365tenants = Get-MsolPartnerContract | Select *
    $OrgName = Get-MsolCompanyInformation | select -exp DisplayName
    $host.ui.RawUI.WindowTitle = "No Active Connections. Viewing the Tenant list now."
    $selectedTenant = Select-ItemFromList -Options $o365tenants -displayProperty Name 
    $defaultDomain = $selectedTenant.DefaultDomainName

    #Gather Tenant Credentials
    $roleIdEntry = Get-MsolRole -RoleName "Company Administrator" -TenantId $selectedTenant.tenantID
    $o365admin = Get-MsolRoleMember -RoleObjectId $roleIdEntry.ObjectId -TenantId $selectedTenant.tenantID | where {$_.EmailAddress -like ("intrustadmin*" + $defaultDomain)}

    #Check for o365admin account. If it does not exist, create it
    if ($o365admin -eq $null)
        {
        $tenantPassword = Read-Host "$msp_name Office 365 Administrator account not found! I'll generate one for you. What password should I use? (8-16 Complex Characters)"
        New-MsolUser -UserPrincipalName $msp_admin@$defaultDomain -DisplayName “$msp_name Office 365 Administrator” -TenantId $selectedTenant.tenantId
        Start-Sleep 2
        Add-MsolRoleMember -RoleName “Company Administrator” –RoleMemberEmailAddress  $msp_admin@$defaultDomain -TenantId $selectedTenant.tenantId
        Start-Sleep 2
        Set-MsolUserPassword -userPrincipalName $msp_admin@$defaultDomain -NewPassword $tenantPassword -ForceChangePassword $false -TenantId $selectedTenant.tenantId
        Start-Sleep 2
        $o365admin = Get-MsolRoleMember -RoleObjectId $roleIdEntry.ObjectId -TenantId $selectedTenant.tenantID | where {$_.EmailAddress -like "$msp_admin*"}
        Start-Sleep 2
        $tenantUsername = $o365admin.EmailAddress
        $tenantSPassword = ConvertTo-SecureString "$tenantPassword" -AsPlainText -Force
        Start-Sleep 2
        $tenantCredentials = New-Object -typename System.Management.Automation.PSCredential -argumentlist ($tenantUsername, $tenantSPassword)
        }

    #Gather existing account's password
    else
        {
        $tenantUsername = $o365admin.EmailAddress
        $tenantSPassword = Read-Host "Enter the password for $tenantUsername" | ConvertTo-SecureString -AsPlainText -Force
        $tenantCredentials = New-Object -typename System.Management.Automation.PSCredential -argumentlist ($tenantUsername, $tenantSPassword)
        }

    #Connect to Office 365 > Exchange Online > Skype Online > Compliance Center
    Connect-MsolService -Credential $tenantCredentials
    try
        {
        $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $tenantCredentials -Authentication "Basic" -AllowRedirection -ErrorAction Stop
        }
    catch [System.Management.Automation.Remoting.PSRemotingTransportException]
        {
        Write-Host "Received a 403: Unauthorized Access. I may be working too quickly. Waiting 60 seconds before trying that again.." -ForegroundColor Yellow
        Start-Sleep 61
        $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $tenantCredentials -Authentication "Basic" -AllowRedirection -ErrorAction Stop
        }
    if ($exchangeSession)
        {
        Import-PSSession $exchangeSession -DisableNameChecking
        }

    try
        {
        $skypesession = New-CsOnlineSession -Credential $tenantCredentials -Verbose -OverrideAdminDomain $selectedTenant.DefaultDomainName
        }
    catch [Microsoft.Rtc.Admin.Authentication.CommonAuthException]
        {
        Write-Host "Microsoft has not completed the provisioning of this account within Skype for Business Online. This typically takes a few hours. I am not connecting you to Skype Online." -ForegroundColor Yellow
        }
    if ($skypesession)
        {
        Import-PSSession $skypesession -AllowClobber 
        }

    #Confirmation of connection
    $OrgName = Get-MsolCompanyInformation | select -exp DisplayName
    $host.ui.RawUI.WindowTitle = "You are connected to: " + $OrgName
    Write-Host "You are connected to:" $OrgName -ForegroundColor Green
    }

#Variables for PowerShell Modules
$officeMod = Get-Module -ListAvailable | Where-Object {$_.Name -eq "MSOnline"}
$sharepointMod = Get-Module -ListAvailable | Where-Object {$_.Name -eq "Microsoft.Online.SharePoint.Powershell"}
$skypeMod = Get-Module -ListAvailable | Where-Object {$_.Name -eq "LyncOnlineConnector"}

#Check Shell Dependecies
$adminCheck = Check-Administrator
if (-not ($adminCheck))
    {
    Write-Host "Run As Administrator, dork." -ForegroundColor Red
    Start-Sleep 2
    break
    }
elseif ($officeMod -eq $null)
    {
    Read-Host "Office 365 Module is missing. Press Enter to be forwarded to the needed downloads. There are two downloads required: Microsoft Online Server Sign-in Assistant and the Azure Active Directory Module"
    Start-Sleep -s 3
    Start-Process "https://www.microsoft.com/en-us/download/details.aspx?id=41950"
    STart-Sleep -s 3
    Start-Process "http://go.microsoft.com/fwlink/p/?linkid=236297"
    break
    }
elseif ($sharepointMod -eq $null)
    {
    Read-Host "Sharepoint Online Module is missing. Press Enter to be forwarded to the Microsoft Download Center."
    Start-Sleep -s 3
    Start-Process "https://www.microsoft.com/en-us/download/details.aspx?id=35588"
    break
    }
elseif ($skypeMod -eq $null)
    {
    Read-Host "Skype Online Module is missing. Press Enter to be forwarded to the Microsoft Download Center."
    Start-Sleep -s 3
    Start-Process "https://www.microsoft.com/en-us/download/details.aspx?id=39366"
    break
    }

#Gather Credentials for Office 365 Partner
Import-Module MsOnline
$credential = Get-Credential

#Make it rain $$$
Connect-O365
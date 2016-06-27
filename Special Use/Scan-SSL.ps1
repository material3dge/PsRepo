<# 

                SSL Vulnerability Scan
    Date created:                      12/3/15
    Date modified:                     12/8/15
    Author:                            Eric Martinez

    Goal:

    To automate the scanning of externally reachable SSL
    enabled web servers for vulnerabilities against 
    Qualy's SSL Labs.

    Usage:

    1) Execute script
    2) Specify location of addresses to be scanned. This
       does not need to be in a special format. A simple
       txt list is sufficient.
    3) Results will be output in console window when
       complete.

#> 

function Scan-SSL
    {
    #Specify location of file that contains the list of to-be-scanned addresses
    $sslClientsList = Read-Host "What is the path to the file that contains a list of addresses you'd like to scan?"
    $sslClients = Get-Content $sslClientsList

    #Location of Qualy's SSL tool
    $sslScan = 'C:\intrust\ssllabs-scan.exe'

    #Create an array to store the results
    $finalArray = @()
    $resultsArray = @()

    #Check to see if the Qualy's SSL Labs tool exists
    $sslCheck = Test-Path C:\intrust\ssllabs-scan.exe

    #Cautions the user that output while processing will not be pretty
    Write-Host "While the process runs, there will be no output on the screen. This is not an indication of a problem. It takes approx 90 seconds per address. Please wait until the script has completed." -ForegroundColor Yellow
    Start-Sleep 5

    #If the SSL tool does not exist, redirect to Qualy's GitHub for download
    if (-not ($sslCheck))
        {
        Write-Host " "
        Write-Host "You're missing the Qualy's SSL Labs utility required to perform these scans. Please download the tool from the Qualy's Github. I'll open it for you now." -ForegroundColor Red
        Write-Host "Please place the tool in C:\intrust\" -ForegroundColor Red
        Start-Sleep 2
        Start-Process "https://github.com/ssllabs/ssllabs-scan/releases"
        break
        }

    #Performs scan, converts output into usable object format, then places the results into an array
    foreach ($i in $sslClients)
        {
        $results = & $sslScan $i 2> Out-Null
        $data = $results | Convertfrom-JSON
        $resultsArray += $data
        }

    #Creates table to output results into an easily-readable human format
    foreach ($n in $resultsArray)
        {
        $sslHost = $n.host
        $ipAddress = $n.endpoints.ipAddress
        $sslGrade = $n.endpoints.grade
        $poodle = $n.endpoints.details.poodle
        $supportRC4 = $n.endpoints.details.supportsRc4
        $dhVul = $n.endpoints.details.dhYsReuse
        $digits = New-Object System.Object
        $digits | Add-Member -MemberType NoteProperty -Name "Host" -Value "$sslHost"
        $digits | Add-Member -MemberType NoteProperty -Name "IP Address" -Value "$ipAddress"
        $digits | Add-Member -MemberType NoteProperty -Name "Poodle Vul." -Value "$poodle"
        $digits | Add-Member -MemberType NoteProperty -Name "RC4 Vul." -Value "$supportRC4"
        $digits | Add-Member -MemberType NoteProperty -Name "DH Vul." -Value "$dhVul"
        $digits | Add-Member -MemberType NoteProperty -Name "SSL Grade" -Value "$sslGrade"
        $finalArray += $digits
        }
    #Display table with results
    $finalArray | Format-Table
    }

#Show me the goods
Scan-SSL 
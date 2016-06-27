# GPOBackup.ps1 
# Author: Eric Martinez
# Date: 02/28/14
# Function: This script Backup all GPOs and save it to C:\Diagnostics\GPObackups.
#           Delete's Backups older than 30 days

$limit = (Get-Date).AddDays(-30)
$path = "C:\Diagnostics\GPOBackups"

Import-Module GroupPolicy
New-Item -Path $path -ItemType Directory
Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force
Get-ChildItem -Path $path -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse
Backup-Gpo -All -Path $path -Comment "GPO Weekly Backup"
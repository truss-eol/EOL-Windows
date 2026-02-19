# Will add the 4 required POSIX attributes (uidNumber, gidNumber, unixHomeDirectory, and loginShell) to AD user accounts, taken from a linux passwd file
# Requires Active Directory Module
# Usage: .\Update-ADFromPasswd.ps1 -FilePath "C:\path\to\passwd"

param (
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

if (-not (Test-Path $FilePath)) {
    Write-Error "Passwd file not found at $FilePath"
    return
}

$passwdLines = Get-Content $FilePath

foreach ($line in $passwdLines) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) { continue }

    $parts = $line.Split(':')
    if ($parts.Count -lt 7) { continue }

    $samAccountName = $parts[0]
    $uid = $parts[2]
    $gid = $parts[3]
    $homeDir = $parts[5]
    $shell = $parts[6]

    try {
        $adUser = Get-ADUser -Identity $samAccountName -ErrorAction Stop
        
        $attributes = @{
            uidNumber         = $uid
            gidNumber         = $gid
            unixHomeDirectory = $homeDir
            loginShell        = $shell
        }

        Set-ADUser -Identity $samAccountName -Replace $attributes       
        Write-Host "Successfully updated = ${samAccountName}" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to update ${samAccountName}: $($_.Exception.Message)"
    }
}



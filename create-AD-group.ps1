# Script will add groups from a linux group file to AD, TargetOU points to new AD config, All Users > Groups
# Parameters - Update these values
$GroupFilePath = "C:\DropBox\cgdtest.txt"
$TargetOU = "OU=Groups,OU=All Users,DC=CIT,DC=UCAR,DC=EDU"

# Import Active Directory module
if (!(Get-Module -ListAvailable ActiveDirectory)) {
    Write-Error "Active Directory module is required."
    return
}

# Process the Linux groups file
Get-Content $GroupFilePath | ForEach-Object {
    # Skip empty lines or comments
    if ([string]::IsNullOrWhiteSpace($_) -or $_.StartsWith("#")) { return }

    # Parse Linux group format (name:password:GID:members)
    $parts = $_.Split(':')
    if ($parts.Count -lt 3) { return }

    $groupName = $parts[0]
    $gid = $parts[2]

    try {
        # Check if group already exists
        if (-not (Get-ADGroup -Filter "Name -eq '$groupName'")) {
            New-ADGroup -Name $groupName `                        -GroupCategory Security `
                        -GroupScope Global `
                        -Path $TargetOU `
                        -Description "Linux GID: $gid" `
                        -OtherAttributes @{gidNumber=$gid} # Requires RFC2307 schema attributes
            
            Write-Host "Successfully created group: $groupName (GID: $gid)" -ForegroundColor Green
        } else {
            Write-Warning "Group '$groupName' already exists. Skipping..."
        }
    }
    catch {
        Write-Error "Failed to create group '$groupName'. Error: $($_.Exception.Message)"
    }

}


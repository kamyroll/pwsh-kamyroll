# Kamyroll API PWSH Script
# Author: Adolar0042
$apiUrl = "https://api.kamyroll.tech"
# $deviceID is a random uuid that gets generated and stored in a file once, then it is used for all subsequent requests
if(Test-Path -Path "$($MyInvocation.PSScriptRoot)\kamyrollDeviceID.json") {
    $deviceID = Get-Content -Path "$($MyInvocation.PSScriptRoot)\kamyrollDeviceID.json" | ConvertFrom-Json
}
else {
    $deviceID = [System.Guid]::NewGuid().ToString() | ConvertTo-Json | Out-File -FilePath "$($MyInvocation.PSScriptRoot)\kamyrollDeviceID.json" -Force
}
$deviceType = "powershellapi" # This can give more token valid time
$accessToken = "HMbQeThWmZq4t7w"

Function Get-ApiToken {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Path
    )

    #   Token
    # access_token
    # token_type
    # expires_in
    Function New-Token {
        try {
            $newToken = Invoke-RestMethod -Method Post -Uri "$apiUrl/auth/v1/token" -Body @{
                "device_id"    = $deviceID
                "device_type"  = $deviceType
                "access_token" = $accessToken
            }
        }
        catch {
            throw "An error occurred while calling the API: $_"
        }
        $newToken | ConvertTo-Json | Out-File -FilePath "$Path\token.json" -Force
        return $newToken
    }

    # Validate input parameters
    if (!(Test-Path -Path $Path -PathType Container)) {
        throw "The `Path` parameter is not a valid directory."
    }

    # Check if the token has expired
    $date = Get-Date
    $unixTimeStamp = ([DateTimeOffset]$date).ToUnixTimeSeconds()
    if (Test-Path -Path "$Path\token.json") {
        $token = Get-Content -Path "$Path\token.json" | ConvertFrom-Json
        if ($unixTimeStamp -ge $token.expires_in) {
            $token = New-Token
        }
    }
    else {
        $token = New-Token
    }
    return $token
}

Function Search {
    Param(
        [Parameter(Mandatory = $True)]
        [String]$query,
        [String]$locale = $Null,
        [ValidateRange(1, [Int32]::MaxValue)]
        [Int]$limit = 10,
        [String]$channel = "crunchyroll",
        [Parameter(Mandatory = $True)]
        [String]$Path
    )

    # Get the API token
    $token = Get-ApiToken -Path $Path

    # Call the API
    try {
        $res = Invoke-RestMethod -Method Get -Uri "$apiUrl/content/v1/search" -Headers @{
            "authorization" = "$($token.token_type) $($token.access_token)"
        } -Body @{
            "channel_id" = $channel
            "query"      = $query
            "limit"      = $limit
            "locale"     = $locale
        }
    }
    catch {
        throw "An error occurred while calling the API: $_"
    }

    return $res
}

Function Seasons {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$seriesID,
        [String]$channel = "crunchyroll",
        [String]$filter,
        [String]$locale,
        [Parameter(Mandatory = $true)]
        [String]$Path
    )

    # Get the API token
    $token = Get-ApiToken -Path $Path

    # Call the API
    try {
        $res = Invoke-RestMethod -Method Get -Uri "$apiUrl/content/v1/seasons" -Headers @{
            "authorization" = "$($token.token_type) $($token.access_token)"
        } -Body @{
            "channel_id" = $channel
            "id"         = $seriesID
            "filter"     = $filter
            "locale"     = $locale
        }
    }
    catch {
        throw "An error occurred while calling the API: $_"
    }

    return $res
}

Function Movies {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$moviesID,
        [String]$channel = "crunchyroll",
        [String]$locale,
        [Parameter(Mandatory = $true)]
        [String]$Path
    )

    # Get the API token
    $token = Get-ApiToken -Path $Path

    # Make the API request
    try {
        $res = Invoke-RestMethod -Method Get -Uri "$apiUrl/content/v1/movies" -Headers @{
            "authorization" = "$($token.token_type) $($token.access_token)"
        } -Body @{
            "channel_id" = $channel
            "id"         = $moviesID
            "locale"     = $locale
        }
    }
    catch {
        throw "An error occurred while calling the API: $_"
    }

    return $res
}


Function Media {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$mediaID,
        [String]$channel = "crunchyroll",
        [String]$locale,
        [Parameter(Mandatory = $true)]
        [String]$Path
    )

    # Get the API token
    $token = Get-ApiToken -Path $Path

    # Make the API request
    try {
        $res = Invoke-RestMethod -Method Get -Uri "$apiUrl/content/v1/media" -Headers @{
            "authorization" = "$($token.token_type) $($token.access_token)"
        } -Body @{
            "channel_id" = $channel
            "id"         = $mediaID
            "locale"     = $locale
        }
    }
    catch {
        throw "An error occurred while calling the API: $_"
    }

    return $res
}

Function Platforms {
    return Invoke-RestMethod -Method Get -Uri "$apiUrl/auth/v1/platforms"
}

Function Streams {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$mediaID,
        [String]$channel = "crunchyroll",
        [String]$format,
        [String]$type,
        [Parameter(Mandatory = $true)]
        [String]$Path
    )

    # Get the API token
    $token = Get-ApiToken -Path $Path

    # Make the API request
    try {
        $res = Invoke-RestMethod -Method Get -Uri "$apiUrl/videos/v1/streams" -Headers @{
            "authorization" = "$($token.token_type) $($token.access_token)"
        } -Body @{
            "id"         = $mediaID
            "channel_id" = $channel
            "format"     = $format
            "type"       = $type
        }
    }
    catch {
        throw "An error occurred while calling the API: $_"
    }

    return $res
}
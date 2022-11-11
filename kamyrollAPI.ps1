# Kamyroll API PWSH Script
# Author: Adolar0042
$apiUrl = "https://api.kamyroll.tech"
$deviceID = "com.service.data"
$deviceType = "powershellapi"
$accessToken = "HMbQeThWmZq4t7w"

Function Get-ApiToken ($Path) {
    #   Token
    # access_token
    # token_type
    # expires_in
    Function New-Token {
        $newToken = Invoke-RestMethod -Method Post -Uri "$apiUrl/auth/v1/token" -Body @{
            "device_id"    = $deviceID
            "device_type"  = $deviceType
            "access_token" = $accessToken
        }
        New-Item -Path "$Path\token" -Name "access_token" -Value $newToken.access_token -Force
        New-Item -Path "$Path\token" -Name "token_type" -Value $newToken.token_type -Force
        New-Item -Path "$Path\token" -Name "expires_in" -Value $newToken.expires_in -Force
        New-Item -Path "$Path\token" -Name "created_at" -Value $unixTimeStamp -Force
        return $newToken
    }
    $date = Get-Date
    $unixTimeStamp = ([DateTimeOffset]$date).ToUnixTimeSeconds()
    if (Test-Path -Path "$Path\token") {
        $expiresIn = Get-Content -Path "$Path\token\expires_in"
        if ($unixTimeStamp -ge $expiresIn) {
            $token = (New-Token).access_token
        }
        else {
            $token = Get-Content -Path "$Path\token\access_token"
        }
    }
    else {
        $token = (New-Token).access_token
    }
    return $token
}

Function Search([STRING]$query, [STRING]$locale = $Null, [INT]$limit = 10, [STRING]$channel = "crunchyroll", $Path) {
    $token = Get-ApiToken -Path $Path
    $tokenType = Get-Content -Path "$Path\token\token_type"
    if ($Null -eq $query) { $query = Read-Host "Search" }
    $res = Invoke-RestMethod -Method Get -Uri "$apiUrl/content/v1/search" -Headers @{
        "authorization" = "$tokenType $token"
    } -Body @{
        "channel_id" = $channel
        "query"      = $query
        "limit"      = $limit
        "locale"     = $locale
    }
    return $res
}

Function Seasons([STRING]$seriesID, [STRING]$channel = "crunchyroll", [STRING]$filter, [STRING]$locale, $Path) {
    $token = Get-ApiToken -Path $Path
    $tokenType = Get-Content -Path "$Path\token\token_type"
    $res = Invoke-RestMethod -Method Get -Uri "$apiUrl/content/v1/seasons" -Headers @{
        "authorization" = "$tokenType $token"
    } -Body @{
        "channel_id" = $channel
        "id"         = $seriesID
        "filter"     = $filter
        "locale"     = $locale
    }
    return $res
}

Function Movies([STRING]$moviesID, [STRING]$channel = "crunchyroll", [STRING]$filter, [STRING]$locale, $Path) {
    $token = Get-ApiToken -Path $Path
    $tokenType = Get-Content -Path "$Path\token\token_type"
    $res = Invoke-RestMethod -Method Get -Uri "$apiUrl/content/v1/movies" -Headers @{
        "authorization" = "$tokenType $token"
    } -Body @{
        "channel_id" = $channel
        "id"         = $moviesID
        "locale"     = $locale
    }
    return $res
}

Function Media([STRING]$mediaID, [STRING]$channel = "crunchyroll", [STRING]$locale, $Path) {
    $token = Get-ApiToken -Path $Path
    $tokenType = Get-Content -Path "$Path\token\token_type"
    $res = Invoke-RestMethod -Method Get -Uri "$apiUrl/content/v1/media" -Headers @{
        "authorization" = "$tokenType $token"
    } -Body @{
        "channel_id" = $channel
        "id"         = $mediaID
        "locale"     = $locale
    }
    return $res
}

Function Platforms($Path) {
    $token = Get-ApiToken -Path $Path
    $tokenType = Get-Content -Path "$Path\token\token_type"
    $res = Invoke-RestMethod -Method Get -Uri "$apiUrl/auth/v1/platforms" -Headers @{
        "authorization" = "$tokenType $token"
    }
    return $res
}

Function Streams([STRING]$mediaID, [STRING]$channel = "crunchyroll", [STRING]$format, [STRING]$type, $Path) {
    # format: Subtitle Format [ass vtt srt]
    # type: Stream Type 
    # Type	                Description
    # adaptive_hls	        m3u8 format             <-(Default)
    # adaptive_dash	        dash format
    # drm_adaptive_dash	    dash format with drm
    $token = Get-ApiToken -Path $Path
    $tokenType = Get-Content -Path "$Path\token\token_type"

    $res = Invoke-RestMethod -Method Get -Uri "$apiUrl/videos/v1/streams" -Headers @{
        "authorization" = "$tokenType $token"
    } -Body @{
        "id"         = $mediaID
        "channel_id" = $channel
        "format"     = $format
        "type"       = $type
    }    
    return $res
}

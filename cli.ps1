# Kamyroll API PWSH CLI
# Author: Adolar0042
$version = "1.1.3.6"
$configPath = "[CONFIGPATH]"

$oldTitle = $Host.UI.RawUI.WindowTitle
$Host.UI.RawUI.WindowTitle = "Kamyroll CLI"

if (!(Get-InstalledModule -Name PSMenu -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PSMenu Module, this is a necessary dependency of the CLI ..."
    Install-Module PSMenu -ErrorAction Stop
}

Write-Host "Looking for updates ..." -ForegroundColor Yellow
# Updater
$gitRaw = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kamyroll/pwsh-kamyroll/main/cli.ps1"
$newVersion = $gitRaw.Content.Split("`n")[2].Split('"')[1]
# Split the version codes into arrays of integers
$versionArray = $version.Split(".") | ForEach-Object { [Int32]$_ }
$newVersionArray = $newVersion.Split(".") | ForEach-Object { [Int32]$_ }
# Compare the version codes
    # Calculate the difference in length between the arrays
$diffNewCurr = $newVersionArray.Count - $versionArray.Count
$diffCurrNew = $versionArray.Count - $newVersionArray.Count
    # Pad arrays with 0s until it has the same length as the other array
for ($i = 0; $i -lt $diffNewCurr; $i++) {
    $versionArray += 0
}
for ($i = 0; $i -lt $diffCurrNew; $i++) {
    $newVersionArray += 0
}
for ($i = 0; $i -lt $versionArray.Count; $i++) {
    if ($newVersionArray[$i] -gt $versionArray[$i]) {
        Do {
            Write-Host "Old: v$Version New: v$newVersion" -ForegroundColor Yellow
            $ans = Read-Host "New version available! Download? [Y/N]"
        } While ($ans -notin @("Y", "y", "N", "n"))
        if ($ans -in @("Y", "y")) {
            $gitRaw = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kamyroll/pwsh-kamyroll/main/cli.ps1"
            $content = $gitRaw.Content.Replace("[CONFIGPATH]", $configPath)
            Out-File -FilePath "$($PSScriptRoot)\$($MyInvocation.MyCommand.Name)" -InputObject $content -Encoding UTF8
            $apiGitRaw = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kamyroll/pwsh-kamyroll/main/kamyrollAPI.ps1"
            $apiContent = $apiGitRaw.Content
            Out-File -FilePath "$($PSScriptRoot)\kamyrollAPI.ps1" -InputObject $apiContent -Encoding UTF8
            Write-Host "Updated to version $newVersion" -ForegroundColor Green
            break
        }
    }
}
else {
    Write-Host "No updates available" -ForegroundColor Green
}

# Load config.config
Write-Host "Loading config ..." -ForegroundColor Green
$config = Get-Content -Path "$configPath\config.config" -Encoding UTF8
if ($Null -ne $config) {
    foreach ($line in $config) {
        # if the line starts with #, skip it
        if (!$line.StartsWith("#") -and $line.Contains("=")) {
            $name = $line.split(" = ")[0]
            $value = $line.split(" = ")[1]
            Set-Variable -Name $name -Value $value
        }
    }
    Write-Host "Config loaded" -ForegroundColor Green
}
else {
    #First time running the script
    $config = '# Kamyroll API PWSH CLI Config

# Default folder to download to (should also contain kamyrollAPI.ps1)
defaultFolder = [DEFAULTFOLDER]
# Subtitle format (ass, vtt, srt)
subtitleFormat = [SUBTITLEFORMAT]
# Channel
channel = [CHANNEL]
    '
    Clear-Host
    Write-Host "Welcome to Kamyroll CLI!`r`nThis is the first time you're running this script, so we need to set up a few things first." -ForegroundColor Green
    Write-Host "Please enter the path, where downloads should go into" -ForegroundColor Green
    Do { 
        $Path = Read-Host "Path"
        if (!(Test-Path -Path $Path)) {
            Do {
                if (!(Test-Path -Path $Path)) {
                    $ans = Read-Host "The path you entered does not exist, should it be created? [Y/N]"
                    if ($ans -in "Y", "y") {
                        try { 
                            New-Item -Path $Path -ItemType Directory -Force 
                        }
                        catch {
                            Write-Host "Failed to create the path, please try again." -ForegroundColor Red
                            $ans = $Null
                        }
                    }
                }
            }
            While ($ans -notin @("Y", "y", "N", "n"))
        }
    }
    Until(Test-Path -Path $Path)
    # check if path contains old config
    if (Test-Path -Path "$Path\config.config") {
        $config = Get-Content -Path "$Path\config.config" -Encoding UTF8
        foreach ($line in $config) {
            # if the line starts with #, skip it
            if (!$line.StartsWith("#") -and $line.Contains("=")) {
                $name = $line.split(" = ")[0]
                $value = $line.split(" = ")[1]
                Set-Variable -Name $name -Value $value
            }
        }
        # Rebuild script with new config path
        $thisScript = Get-Content "$($PSScriptRoot)\$($MyInvocation.MyCommand.Name)"
        foreach ($line in $thisScript.Split("`n")) {
            if ($line.Contains('$configPath = "[CONFIGPATH]"') -and !($line.Contains("if ("))) {
                $content += '$configPath = ' + """$Path""`n"
            }
            elseif ($line -eq "# End") {
                $content += $line
            }
            else {
                $content += $line + "`n"
            }
        }
        $content | Out-File -FilePath "$($PSScriptRoot)\$($MyInvocation.MyCommand.Name)" -Encoding UTF8 -Force        
        Write-Host "Config loaded" -ForegroundColor Green
    }
    else {
        Clear-Host
        $config = $config.Replace("[DEFAULTFOLDER]", $Path)
        Write-Host "What format should soft subtitles be in?`r`n" -ForegroundColor Green
        $ans = Show-Menu -MenuItems @(
            "ASS - Formatting, position and style are pre-set (recommended)"
            "VTT - Position and style are pre-set, but formatting is not (allows for more customization)"
            "SRT - No formatting, position or style is pre-set"
        ) -ReturnIndex
        $ans = switch ($ans) {
            0 { "ass" }
            1 { "vtt" }
            2 { "srt" }
        }
        $config = $config.Replace("[SUBTITLEFORMAT]", $ans)

        $apiUrl = "https://api.kamyroll.tech"
        $platforms = Invoke-RestMethod -Method Get -Uri "$apiUrl/auth/v1/platforms"
        Clear-Host
        Write-Host "On which channel do you want to use Kamyroll?`r`n" -ForegroundColor Green
        $ans = Show-Menu -MenuItems @(
            $platforms.items
        )
        $config = $config.Replace("[CHANNEL]", $ans)
        $config | Out-File -FilePath "$Path\config.config" -Encoding utf8 -Force

        # Rebuild script with new config path
        $thisScript = Get-Content "$($PSScriptRoot)\$($MyInvocation.MyCommand.Name)"
        foreach ($line in $thisScript.Split("`n")) {
            if ($line.Contains('$configPath = "[CONFIGPATH]"') -and !($line.Contains("if ("))) {
                $content += '$configPath = ' + """$Path""`n"
            }
            elseif ($line -eq "# End") {
                $content += $line
            }
            else {
                $content += $line + "`n"
            }
        }
        $content | Out-File -FilePath "$($PSScriptRoot)\$($MyInvocation.MyCommand.Name)" -Encoding UTF8 -Force

        Write-Host "Config file created, these settings can be changed at any time by editing`r`n   $Path\config.config`r`nComntinuing in 5s ..." -ForegroundColor Green
        Start-Sleep -Seconds 5
        Write-Host "Loading config ..." -ForegroundColor Green
        $config = Get-Content -Path "$configPath\config.config" -Encoding UTF8
        foreach ($line in $config) {
            # if the line starts with #, skip it
            if (!$line.StartsWith("#") -and $line.Contains("=")) {
                $name = $line.split(" = ")[0]
                $value = $line.split(" = ")[1]
                Set-Variable -Name $name -Value $value
            }
        }
        Write-Host "Config loaded" -ForegroundColor Green
    }
}



# Hide Invoke-WebRequest Progress Bar
$ProgressPreference = 'SilentlyContinue'

if (!(Test-Path -Path "$defaultFolder\kamyrollAPI.ps1")) {
    Write-Host "kamyrollAPI.ps1 not found in '$defaultFolder', downloading..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kamyroll/pwsh-kamyroll/main/kamyrollAPI.ps1" -OutFile "$defaultFolder\kamyrollAPI.ps1"
    Do {
        Start-Sleep -Milliseconds 10
    }Until(Test-Path -Path "$defaultFolder\kamyrollAPI.ps1")
}
. "$defaultFolder\kamyrollAPI.ps1"



Function Get-M3U8Resolutions([STRING]$m3u8Url) {
    $i = 0
    $resolutions = @()
    $m3u8 = [System.Text.Encoding]::UTF8.GetString((Invoke-WebRequest -Uri $m3u8Url -UseBasicParsing).Content).Split("`n")
    foreach ($line in $m3u8) {
        $i++
        if ($i -gt 1 -and $line[0] -eq "#") {
            $line = $line.Split(",")
            $res = $line | Where-Object { $_ -match "RESOLUTION" }
            if ($res) {
                $res = $res.Split("=")[1]
                $resolutions += $res
            }
        }
    }
    return $resolutions
}

Function Normalize([STRING]$string) {
    return $string.Replace("/", " ").Replace(":", " ").Replace("*", " ").Replace("<", " ").Replace(">", " ").Replace("|", " ").Replace("""", " ")
}

Function Get-Episode($media) {
    # Episode Select Menu
    Write-Host "Select an episode`r`n" -ForegroundColor Green
    $episode = Show-Menu -MenuItems $media.episodes -Callback {
        $lastTop = [Console]::CursorTop
        [System.Console]::SetCursorPosition(0, 0)
        [System.Console]::SetCursorPosition(0, $lastTop)
    } -MenuItemFormatter { 
        if ($Args.sequence_number -ne "") { $name = "[$($Args.sequence_number)] " }
        $name = if (($name + $Args.title).Length -gt ($Host.UI.RawUI.WindowSize.Width / 3 * 2 - 6)) {
                ($name + $Args.title).Substring(0, ($Host.UI.RawUI.WindowSize.Width / 3 * 2 - 9)) + "..."
        }
        else {
            $name + $Args.title + " " * (($Host.UI.RawUI.WindowSize.Width / 3 * 2 - 6) - ($name + $Args.title).Length)
        }
        $name.Replace("subtitleFormat", "") #TODO: fix. I don't know why the title sometimes has "subtitleFormat" infront, but it does and it's annoying :(
    }

    Clear-Host
    return $episode
}

Function Get-Stream($episode, [BOOLEAN]$isID = $false) {
    Write-Host "Getting streams..." -ForegroundColor Green
    if ($isID -eq $true) {
        $streams = Streams -mediaID $episode -format $subtitleFormat -channel $channel -Path $defaultFolder
    }
    else {
        $streams = Streams -mediaID $episode.id -format $subtitleFormat -channel $channel -Path $defaultFolder
    }
    if ($Null -eq $streams.streams) {
        Write-Host "No streams found" -ForegroundColor Red
        break
    }
    Clear-Host

    # Streams Select Menu (Audio, Subs)
    Write-Host "Select an stream`r`n" -ForegroundColor Green
    $stream = Show-Menu -MenuItems $streams.streams -Callback {
        $lastTop = [Console]::CursorTop
        [System.Console]::SetCursorPosition(0, 0)
        [System.Console]::SetCursorPosition(0, $lastTop)
    } -MenuItemFormatter { 
        "Audio: $($Args.audio_locale) " + $(if ($Args.hardsub_locale -ne "") { "Hardsub: $($Args.hardsub_locale)" }else { "Hardsub: None" })
    }
    Clear-Host
    return $streams, $stream
}

Function Get-ResolutionUrl($streamRes) {
    Write-Host "Choose resolution`r`n" -ForegroundColor Green
    $res = Show-Menu -MenuItems $streamRes -Callback {
        $lastTop = [Console]::CursorTop
        [System.Console]::SetCursorPosition(0, 0)
        Write-Host "Choose resolution`r`n" -ForegroundColor Green
        [System.Console]::SetCursorPosition(0, $lastTop)
    }
    $m3u8 = [System.Text.Encoding]::UTF8.GetString((Invoke-WebRequest -Uri $stream.url -UseBasicParsing).Content).Split("`n")
    $next = $false
    foreach ($line in $m3u8) {
        if ($next -eq $true) {
            $url = $line
            $next = $false
        }
        else {
            if ($line.Contains($res)) {
                $next = $true
            } 
            else {
                $next = $false
            }
        }
    }
    Clear-Host
    return $url
}

Function Get-SoftSubs($streams) {
    $subtitles = $streams.subtitles
    if ($Null -eq $subtitles) {
        Write-Host "No subtitles found" -ForegroundColor Red
        break
    }

    # Subtitles Select Menu
    Write-Host "Select subtitle(s)`r`nSpace -> Select`r`nEnter -> Confirm Selection`r`n" -ForegroundColor Green
    $subtitle = Show-Menu -MenuItems $subtitles -Callback {
        $lastTop = [Console]::CursorTop
        [System.Console]::SetCursorPosition(0, 0)
        [System.Console]::SetCursorPosition(0, $lastTop)
    } -MenuItemFormatter { 
        $Args.locale
    } -MultiSelect
    Clear-Host
    return $subtitle
}

Clear-Host
Write-Host "Kamyroll CLI v$version" -ForegroundColor Green
$query = Read-Host "Search"
if ($query.Split("/")[3] -eq "series") {
    Write-Host "Crunchyroll series link detected"
    $seriesID = $query.Split("/")[4]
}
elseif ($query.Split("/")[3] -eq "watch") {
    Write-Host "Crunchyroll episode link detected"
    $episodeID = $query.Split("/")[4]
}
else {
    Write-Host "Searching for ""$query"" ..."
    $searchResult = Search -query $query -limit 5 -channel $channel -Path $defaultFolder
    [INT]$totalResults = 0
    foreach ($type in $searchResult.items) {
        $totalResults += $type.total
    }
    Remove-Variable -Name i
    if ($totalResults -eq 0) {
        Write-Host "No results found" -ForegroundColor Red
        break
    }
    Clear-Host

    # Search Result Menu
    Write-Host "Searched: ""$query""`r`nTotal Search Results: $totalResults`r`n`r`n" -ForegroundColor Green
    $result = Show-Menu -MenuItems $searchResult.items.items -Callback {
        $lastTop = [Console]::CursorTop
        [System.Console]::SetCursorPosition(0, 0)
        Write-Host "Searched: ""$query""`r`nTotal Search Results: $totalResults`r`n`r`n" -ForegroundColor Green
        [System.Console]::SetCursorPosition(0, $lastTop)
    } -MenuItemFormatter { 
        $name = if ($Args.title.Length -gt ($Host.UI.RawUI.WindowSize.Width / 3 * 2 - 6)) {
            $Args.title.Substring(0, ($Host.UI.RawUI.WindowSize.Width / 3 * 2 - 9)) + "..."
        }
        else {
            $name = "$(if($Args.media_type -eq "movie_listing"){"[Movie] "}elseif($Args.media_type -eq "series"){"[Series]"}) $($Args.title) "
            $name = $name + " " * (($Host.UI.RawUI.WindowSize.Width / 3 * 2 - 6) - $name.Length)
            $name
        }
        $name
    }
    Clear-Host
}

if (($result.media_type -eq "series") -or ($NULL -ne $seriesID)) {
    $id = if ($NULL -ne $seriesID) { $seriesID }else { $result.id }
    Write-Host "Getting seasons ..." -ForegroundColor Green
    $seasons = Seasons -seriesID $id -channel $channel -Path $defaultFolder
    if ($Null -eq $seasons.items) {
        Write-Host "No seasons found" -ForegroundColor Red
        if ($seriesID) {
            Write-Host "Looking for movie instead ..." -ForegroundColor Yellow
        }
        else {
            break
        }
    }
    Clear-Host

    # Season Select Menu
    Write-Host "Select an season`r`n" -ForegroundColor Green
    $season = Show-Menu -MenuItems $seasons.items -Callback {
        $lastTop = [Console]::CursorTop
        [System.Console]::SetCursorPosition(0, 0)
        Write-Host "Select an season`r`n" -ForegroundColor Green
        [System.Console]::SetCursorPosition(0, $lastTop)
    } -MenuItemFormatter { 
        $name = if ($Args.title.Length -gt ($Host.UI.RawUI.WindowSize.Width / 3 * 2 - 6)) {
            $Args.title.Substring(0, ($Host.UI.RawUI.WindowSize.Width / 3 * 2 - 9)) + "..."
        }
        else {
            $Args.title + " " * (($Host.UI.RawUI.WindowSize.Width / 3 * 2 - 6) - $Args.title.Length)
        }
        $name
    }

    $media = $season
    Clear-Host
}
elseif (($result.media_type -eq "movie_listing") -or ($NULL -ne $seriesID)) {
    $media = Movies -moviesID $result.id -channel $channel -Path $defaultFolder

    Clear-Host
    # Get-Streams $media.items $media.items
    $streams, $stream = Get-Stream $media.items
    $streamRes = Get-M3U8Resolutions $stream.url
    $url = Get-ResolutionUrl $streamRes

    New-Item -Path "$defaultFolder\anime\$(Normalize $media.items.title)" -ItemType Directory -Force | Out-Null

    if ($stream.hardsub_locale -eq "") {
        $subtitles = $streams.subtitles
        if ($Null -eq $subtitles) {
            Write-Host "No subtitles found" -ForegroundColor Red
            break
        }
        $subtitle = Get-SoftSubs $streams
        if ($subtitle.count -eq 0 -and $subtitle.url -ne "") {
            $request = Invoke-WebRequest -Uri $subtitle.url
            $request.content | Out-File -LiteralPath "$defaultFolder\anime\$(Normalize $media.items.title)\[$($subtitle.locale)] $(Normalize $media.items.title).$subtitleFormat"
        }
        elseif ($subtitle.count -ne 0) {
            foreach ($sub in $subtitle) {
                $request = Invoke-WebRequest -Uri $sub.url
                $request.content | Out-File -LiteralPath "$defaultFolder\anime\$(Normalize $media.items.title)\[$($sub.locale)] $(Normalize $media.items.title).$subtitleFormat"
            }
        }
    }
    # $url is the url with chosen resolution
    Invoke-WebRequest -Uri $url -OutFile "$defaultFolder\anime\$(Normalize $media.items.title)\$(Normalize $media.items.title).m3u8"
    Invoke-Item "$defaultFolder\anime\$(Normalize $media.items.title)"
    break
}
elseif ($NULL -eq $episodeID -and !($result.media_type -in @("series", "movie_listing"))) {
    Write-Host "Media type '$($result.media_type)' not supported.`r`nFurther information about search result:`r`n`r`n$($result | ConvertTo-Json)" -ForegroundColor Red
    break
}
else {
    Write-Host "No Results Found" -ForegroundColor Red
    break
}


Clear-Host

if ($Null -ne $episodeID) {
    Write-Host "Getting episode info ..." -ForegroundColor Green
    $epMedia = Media -mediaID $episodeID -channel $channel -Path $defaultFolder
    $media = Seasons -seriesID $epMedia.series_id -channel $channel -Path $defaultFolder
    $streams, $stream = Get-Stream $episodeID $true
    $streamRes = Get-M3U8Resolutions $stream.url
    $url = Get-ResolutionUrl $streamRes

    New-Item -Path "$defaultFolder\anime\$(Normalize $epMedia.season_title)\$($epMedia.sequence_number)" -ItemType Directory -Force | Out-Null

    if ($stream.hardsub_locale -eq "") {
        $subtitles = $streams.subtitles
        if ($Null -eq $subtitles) {
            Write-Host "No subtitles found" -ForegroundColor Red
            break
        }
        $subtitle = Get-SoftSubs $streams
        if ($subtitle.count -eq 1 -and $subtitle.url -ne "") {
            $request = Invoke-WebRequest -Uri $subtitle.url 
            $request.content | Out-File -LiteralPath "$defaultFolder\anime\$(Normalize $epMedia.season_title)\$($epMedia.sequence_number)\[$($subtitle.locale)] $(Normalize $epMedia.title).$subtitleFormat"
        }
        elseif ($subtitle.count -gt 1 -and $subtitle.url -ne "") {
            foreach ($sub in $subtitle) {
                $request = Invoke-WebRequest -Uri $sub.url 
                $request.content | Out-File -LiteralPath "$defaultFolder\anime\$(Normalize $epMedia.season_title)\$($epMedia.sequence_number)\[$($sub.locale)] $(Normalize $epMedia.title).$subtitleFormat"
            }
        }
    }
    # $url is the url with chosen resolution
    Invoke-WebRequest -Uri $url -OutFile "$defaultFolder\anime\$(Normalize $epMedia.season_title)\$($epMedia.sequence_number)\$(Normalize $epMedia.title).m3u8"
    Invoke-Item "$defaultFolder\anime\$(Normalize $epMedia.season_title)\$($epMedia.sequence_number)"
}
else {
    if ($Null -eq $media.episodes) {
        Write-Host "No episodes found" -ForegroundColor Red
        break
    }
    Do {
        Clear-Host
        $episode = Get-Episode $media
        $streams, $stream = Get-Stream $episode
        $streamRes = Get-M3U8Resolutions $stream.url
        $url = Get-ResolutionUrl $streamRes
    
        New-Item -Path "$defaultFolder\anime\$(Normalize $media.title)\$($episode.sequence_number)" -ItemType Directory -Force | Out-Null
    
        if ($stream.hardsub_locale -eq "") {
            $subtitles = $streams.subtitles
            if ($Null -eq $subtitles) {
                Write-Host "No subtitles found" -ForegroundColor Red
                break
            }
            $subtitle = Get-SoftSubs $streams
            if ($subtitle.count -eq 1 -and $subtitle.url -ne "") {
                $request = Invoke-WebRequest -Uri $subtitle.url 
                $request.content | Out-File -LiteralPath "$defaultFolder\anime\$(Normalize $media.title)\$($episode.sequence_number)\[$($subtitle.locale)] $(Normalize $episode.title).$subtitleFormat"
            }
            elseif ($subtitle.count -gt 1 -and $subtitle.url -ne "") {
                foreach ($sub in $subtitle) {
                    $request = Invoke-WebRequest -Uri $sub.url 
                    $request.content | Out-File -LiteralPath "$defaultFolder\anime\$(Normalize $media.title)\$($episode.sequence_number)\[$($sub.locale)] $(Normalize $episode.title).$subtitleFormat"
                }
            }
        }
        # $url is the url with chosen resolution
        Invoke-WebRequest -Uri $url -OutFile "$defaultFolder\anime\$(Normalize $media.title)\$($episode.sequence_number)\$(Normalize $episode.title).m3u8"
        Invoke-Item "$defaultFolder\anime\$(Normalize $media.title)\$($episode.sequence_number)"
    }
    While ($true)
}

$Host.UI.RawUI.WindowTitle = $oldTitle
Remove-Variable * -ErrorAction SilentlyContinue
# End
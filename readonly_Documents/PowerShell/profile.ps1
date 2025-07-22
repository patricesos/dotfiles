if (!(Test-Path -Path $PROFILE)) {
  New-Item -ItemType File -Path $PROFILE -Force
}

# My powershell custom function

hugo completion powershell | Out-String | Invoke-Expression

function pw { pwsh -nol }

function moho {
    C:\Program` Files\Moho` 14\Moho.exe
}

function env { .\.venv\Scripts\Activate.ps1 }

function create-env { python` -m` venv` .venv }

function lz { $env:NVIM_APPNAME = "lazy"; nvim }

function nc { $env:NVIM_APPNAME = "nv-code"; nvim }

function anime { fastanime anilist }

function mpv-edit { nvim "F:\mpv\portable_config" }

function ll { eza -al }

function SymLink {
    param ( $Target, $Path )
    New-Item -ItemType SymbolicLink -Path $Path -Target $Target
}

function pipe { python` -m` pip }

function c. { code . }

function audio {
    param($link)
    yt-dlp -o $env:userprofile/downloads/music/"%(title)s.%(ext)s" -x --audio-format mp3 $link
}

function hd {
    param($link)
    yt-dlp -o $env:userprofile/downloads/video/"%(title)s.%(ext)s" -f "140+136" $link
}

function fhd {
    param($link)
    yt-dlp -o $env:userprofile/downloads/video/"%(title)s.%(ext)s" -f "140+137" $link
}

function insta {
    param($link)
    yt-dlp -o $env:userprofile/downloads/video/"%(title)s.%(ext)s" -f "ba+bv" $link --cookies-from-browser firefox
}

function video {
    param($link)
    yt-dlp -o $env:userprofile/downloads/video/"%(title)s.%(ext)s" -f "ba+bv" $link
}

function global {
    $globalVenvPath = "$HOME/.globalVenv"
    if (Test-Path $globalVenvPath) {
        & "$globalVenvPath/Scripts/Activate.ps1"
    } else {
        Write-Output "No virtual environment found in .venv or ~/.globalVenv"
    }
}

function tr {
    param($opt)
    eza --icons=always -G -w 2 --follow-symlinks $opt
}

function gaffer-edit {
    nvim f:/software/gaffer.bat
}

function bt {
  param($opt)
    beet im $opt
}

function conf-edit { chezmoi edit }
function conf-update { chezmoi update }
function conf-apply { chezmoi -v apply }

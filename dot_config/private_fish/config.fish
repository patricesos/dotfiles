if status is-interactive
    fish_config theme choose coolbeans
    # Commands to run in interactive sessions can go here
end

# Initialise Zoxide
zoxide init fish | source

# Initialise starship
starship init fish | source

alias fsf="fastfetch"
alias repo-view="gh repo view --web"

# aliases
abbr --add zj zellij
abbr --add la "ll -a"
abbr --add ll "eza -axl --icons=always --group-directories-first"
abbr --add sdu 'sudo dnf update'
abbr --add sdi 'sudo dnf install'
abbr --add sds "sudo dnf search"
abbr --add sdr "sudo dnf rm"
abbr --add sb "source ~/.bashrc"
abbr --add reset-audio "systemctl --user restart pipewire.service"
abbr --add hyr "hyprctl reload"
abbr --add venv-activate "source .venv/bin/activate"
abbr --add du ncdu
abbr --add venv "source .venv/bin/activate"

abbr --add ce "chezmoi edit"
abbr --add cu "chezmoi update"
abbr --add ca "chezmoi -v apply"
abbr --add ccd "chezmoi cd"
abbr --add emacs "emacsclient -nca 'emacs'"

# YouTube Downloader
abbr --add yt-dlp "yt-dlp -P '~/Downloads' -o '%(title)s.%(ext)s'"
abbr --add video "yt-dlp -P '~/Downloads/video' -o '%(title)s.%(ext)s' --embed-chapters --write-subs --sub-format 'ass'"
abbr --add yt-inst "yt-dlp -P '~/Downloads/YouTube/' -f 'ba+bv' -o '%(title)s%(tags)s.%(ext)s --cookies-from-browser firefox'"

function audio -a link
    yt-dlp -P '~/Downloads/music' -f 140 -o '%(title)s.%(ext)s' $link
end

# Neovim Configuration
abbr --add vi nvim
abbr --add vim nvim

function icat -a name
    kitten icat --use-window-size 1,1,300,1 $name
end

function fish_greeting
    fsf
end

function on_exit --on-event fish_exit
    echo fish is now exiting
end

function repo-create -a name
    git init
    gh repo create --private $name --source . --remote origin
end

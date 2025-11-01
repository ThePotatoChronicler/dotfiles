# Environment
fish_add_path -g "$HOME/.local/bin"
command -q bat && set -x PAGER bat

## Browser
if command -q firefox-developer-edition
    set -x BROWSER firefox-developer-edition
else if command -q firefox
    set -x BROWSER firefox
end

if command -q chromium
    set -x CHROME_EXECUTABLE chromium
end

if command -q kitty
    set -x TERMINAL kitty
else if command -q alacritty
    set -x TERMINAL alacritty
end

command -q dotnet && set -gx DOTNET_CLI_TELEMETRY_OPTOUT 1
command -q pwsh && set -gx POWERSHELL_TELEMETRY_OPTOUT 1

# command -q nvim && set -gx EDITOR nvim
set -l helix (get-helix-editor-name)

if command -q $helix
    set -gx EDITOR $helix
end

test -d "$HOME/Scripts" && fish_add_path -g "$HOME/Scripts"

# If fish is not running interactively, end the script here
if not status is-interactive
    exit
end

# Aliasses and Abbreviations
command -q docker-compose && abbr -ag dcc docker-compose
command -q docker && abbr -ag dkr docker
command -q cargo && abbr -ag cg cargo

if set -q EDITOR
    abbr -ag e $EDITOR
end

if command -q lsd
    abbr -ag ls lsd
    abbr -ag ll lsd -l
    abbr -ag la lsd -A
    abbr -ag lla lsd -lA
end

alias rm='rm -I'

command -q bat && alias cat=bat

if command -q batman
    abbr -ag man batman
    set -x MANPAGER less
end

command -q julia && abbr -ag jl julia

if command -q starship
    starship init fish | source
    enable_transience
end

if not command -q sudo && command -q doas
    alias sudo doas
end

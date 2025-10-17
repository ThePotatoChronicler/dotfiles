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
if command -q helix
    set -gx EDITOR helix
end

test -d "$HOME/Scripts" && fish_add_path -g "$HOME/Scripts"

# If fish is not running interactively, end the script here
if not status is-interactive
    exit
end

# Fish settings
set -g fish_cursor_default block
set -g fish_cursor_insert line
set -g fish_cursor_replace_one underscore
set -g fish_color_normal 00DDDD
set -g fish_color_command 26F7FD
set -g fish_color_keyword C0C
set -g fish_color_redirection FFA500
set -g fish_color_error FF0000
set -g fish_color_param 088
set -g fish_color_valid_path DE3163
set -g fish_color_option 00C000
set -g fish_color_operator FFFF00
set -g fish_color_autosuggestion 477

# Aliasses and Abbreviations
command -q docker-compose && abbr -ag dcc docker-compose
command -q docker && abbr -ag dkr docker
command -q cargo && abbr -ag cg cargo
# if command -q nvim
#     abbr -ag e nvim
#     abbr -ag egdt nvim --listen "$XDG_RUNTIME_DIR/godoteditor"
# else if command -q vim
#     abbr -ag e vim
# end
if command -q helix
    abbr -ag e helix
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

function mkc
    if test (count $argv) -gt 1
        echo "mkc: Expected exactly one argument" >&2
        return 1
    end
    set DIR $argv[1]
    mkdir "$DIR" && cd "$DIR"
end

if command -q starship
    starship init fish | source
    enable_transience
end

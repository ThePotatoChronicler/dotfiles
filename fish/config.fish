# Environment
fish_add_path "$HOME/.local/bin"
command -q bat && set -x PAGER 'bat'
command -q nvim && set -x MANPAGER 'nvim +Man!'

## Browser
if command -q firefox-developer-edition
    set -x BROWSER firefox-developer-edition
else if command -q firefox
    set -x BROWSER firefox
end

if command -q kitty
    set -x TERMINAL kitty
else if command -q alacritty
    set -x TERMINAL alacritty
end

command -q dotnet && set -gx DOTNET_CLI_TELEMETRY_OPTOUT 1

# command -q nvim && set -gx EDITOR nvim
command -q hx && set -gx EDITOR hx
set -gx GEM_HOME "$HOME/.gem/ruby/3.0.0"

# >:[
if command -q ansible && command -q cowsay
    set -gx ANSIBLE_NOCOWS 1
end

# If we're on arch and the file exists
if command -q pacman && test -f /opt/asdf-vm/asdf.fish
    source /opt/asdf-vm/asdf.fish
end

if command -q ros && test -d ~/.roswell/bin
    fish_add_path "$HOME/.roswell/bin"
end

test -d "$HOME/Scripts" && fish_add_path "$HOME/Scripts"

if command -q pnpm
    set -gx PNPM_HOME "$HOME/.local/share/pnpm"
    fish_add_path "$PNPM_HOME"
    [ -f ~/.config/tabtab/fish/__tabtab.fish ]; and . ~/.config/tabtab/fish/__tabtab.fish; or true
end

# Perl stuff
if command -q perl
    set -gx PERL_MB_OPT "--install_base $HOME/.local/lib/perl5"
    set -gx PERL_MM_OPT "INSTALL_BASE=$HOME/.local/lib/perl5"
    set -gx PERL5LIB "$HOME/.local/lib/perl5/lib/perl5"
    set -gx PERL_LOCAL_LIB_ROOT "$HOME/perl5:$PERL_LOCAL_LIB_ROOT"
end

# OCaml stuff
command -q opam && eval (opam env)

# Rust (cargo) stuff
command -q cargo && fish_add_path "$HOME/.cargo/bin"

# pyenv stuff
if command -q pyenv
    set -gx PYENV_ROOT "$HOME/.pyenv"
    fish_add_path "$PYENV_ROOT/bin"
    pyenv init - | source
end

# Ruby stuff
command -q gem && fish_add_path "$HOME/.gem/ruby/3.0.0/bin"

# Nim stuff
if command -q choosenim || command -q nim
    fish_add_path "$HOME/.nimble/bin"
end

# Nix stuff
command -q nix && fish_add_path "$HOME/.nix-profile/bin"

if test -d "$HOME/go/bin"
    fish_add_path "$HOME/go/bin"
end

# If fish is not running interactively, end the script here
if not status is-interactive
    exit
end

# Fish settings
set -g fish_cursor_default block
set -g fish_cursor_insert line
set -g fish_cursor_replace_one underscore

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
else if command -q hx
    abbr -ag e hx
end
command -q pnpm && abbr -ag pn pnpm
command -q http && abbr -ag h http
command -q https && abbr -ag hs https

if command -q lsd
    abbr -ag ls lsd
    abbr -ag ll lsd -l
    abbr -ag la lsd -A
    abbr -ag lla lsd -lA
end

alias nmcli='nmcli --color=auto --ask'
alias wdiff="wdiff -n -w '"\033"[30;41m' -x '"\033"[0m' -y '"\033"[30;42m' -z '"\033"[0m'"

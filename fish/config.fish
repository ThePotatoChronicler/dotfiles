# Environment
command -q bat && set -x PAGER 'bat'
command -q nvim && set -x MANPAGER 'nvim +Man!'
command -q firefox && set -x BROWSER firefox
command -q alacritty && set -x TERMINAL alacritty
set -gx DOTNET_CLI_TELEMETRY_OPTOUT 1
command -q nvim && set -gx EDITOR nvim
set -gx GEM_HOME "$HOME/.gem/ruby/3.0.0"

# >:[
set -gx ANSIBLE_NOCOWS 1

test -d "$HOME/Scripts" && fish_add_path "$HOME/Scripts"

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
fish_add_path "$PNPM_HOME"
[ -f ~/.config/tabtab/fish/__tabtab.fish ]; and . ~/.config/tabtab/fish/__tabtab.fish; or true
# pnpm end

# Perl stuff
set -gx PERL_MB_OPT "--install_base $HOME/.local/lib/perl5"
set -gx PERL_MM_OPT "INSTALL_BASE=$HOME/.local/lib/perl5"
set -gx PERL5LIB "$HOME/.local/lib/perl5/lib/perl5"
set -gx PERL_LOCAL_LIB_ROOT "$HOME/perl5:$PERL_LOCAL_LIB_ROOT"

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
if command -q nvim
    abbr -ag e nvim
else if command -q vim
    abbr -ag e vim
end
command -q pnpm && abbr -ag pn pnpm

command -q lsd && alias ls='lsd'
alias nmcli='nmcli --color=auto --ask'
alias wdiff="wdiff -n -w '"\033"[30;41m' -x '"\033"[0m' -y '"\033"[30;42m' -z '"\033"[0m'"

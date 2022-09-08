# Environment
command -q bat && set -x PAGER 'bat'
command -q nvim && set -x MANPAGER 'nvim +Man!'
command -q firefox && set -x BROWSER firefox
command -q alacritty && set -x TERMINAL alacritty
set -x DOTNET_CLI_TELEMETRY_OPTOUT 1
command -q nvim && set -x EDITOR nvim
set -x GEM_HOME "$HOME/.gem/ruby/3.0.0"

# pnpm
set -gx PNPM_HOME "/home/potato/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
# pnpm end

# Perl stuff
set -x PERL_MB_OPT "--install_base $HOME/.local/lib/perl5"
set -x PERL_MM_OPT "INSTALL_BASE=$HOME/.local/lib/perl5"
set -x PERL5LIB "$HOME/.local/lib/perl5/lib/perl5"
set -x PERL_LOCAL_LIB_ROOT "$HOME/perl5:$PERL_LOCAL_LIB_ROOT"

# Fish settings
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore

# OCaml stuff
eval (opam env)

# If fish is not running interactively, end the script here
if not status is-interactive
    exit
end

# Aliasses
command -q lsd && alias ls='lsd'
command -q nvim && alias v='nvim' || alias v='vim'
alias nmcli='nmcli --color=auto --ask'
alias wdiff="wdiff -n -w '"\033"[30;41m' -x '"\033"[0m' -y '"\033"[30;42m' -z '"\033"[0m'"


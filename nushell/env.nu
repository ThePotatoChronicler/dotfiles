# Check if command is defined
def defined [command: string]: nothing -> bool {
  which $command | is-not-empty
}

if (defined bat) {
  $env.PAGER = "bat"
}

if (defined firefox-developer-edition) {
  $env.BROWSER = "firefox-developer-edition"
}

if (defined dotnet) {
  $env.DOTNET_CLI_TELEMETRY_OPTOUT = 1
}

if (defined pwsh) {
  $env.POWERSHELL_TELEMETRY_OPTOUT = 1
}

if (defined helix) {
  $env.EDITOR = "helix"
}

if (defined carapace) {
  $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
  $env.config.completions.external = {
    enable: true,
    max_results: 10000,
    completer: {|spans| carapace $spans.0 nushell ...$spans | from json}
  }
}

hide defined

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
  carapace _carapace nushell | save --force $"($nu.temp-path)/($nu.pid)-carapace.nu"
}

if (defined starship) {
  starship init nu | save -f $"($nu.temp-path)/($nu.pid)-starship.nu"
}

do --env {
  mut out = ""

  if (defined batman) {
    $out += "alias man = batman\n"
  }

  if (defined bat) {
    $out += "alias cat = bat\n"
  }

  if (not (defined sudo) and (defined doas)) {
    $out += "alias sudo = doas\n"
  }

  if ("EDITOR" in $env) {
    $out += $"alias e = ($env.EDITOR)\n"
  }

  if ($out != "") {
    $out | save -f $"($nu.temp-path)/($nu.pid)-dynamic_aliases.nu"
  }
}

# Hide unnecessary things
hide defined

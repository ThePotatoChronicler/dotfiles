$env.config.show_banner = false

if ("EDITOR" in $env) {
  $env.config.buffer_editor = $env.EDITOR
}

if ($env.HOME | path join "Scripts" | path exists) {
  use std/util "path add"
  path add ($env.HOME | path join "Scripts")
}

if ($nu.is-interactive) {
  # Carapace
  source (if ($"($nu.temp-path)/($nu.pid)-carapace.nu" | path exists) { $"($nu.temp-path)/($nu.pid)-carapace.nu" })
  rm -f $"($nu.temp-path)/($nu.pid)-carapace.nu"

  # Starship
  source (if ($"($nu.temp-path)/($nu.pid)-starship.nu" | path exists) { $"($nu.temp-path)/($nu.pid)-starship.nu" })
  rm -f $"($nu.temp-path)/($nu.pid)-starship.nu"
}

# Dynamic aliases
source (if ($nu.is-interactive and ($"($nu.temp-path)/($nu.pid)-dynamic_aliases.nu" | path exists)) { $"($nu.temp-path)/($nu.pid)-dynamic_aliases.nu" })

if ($nu.is-interactive) {
  # Dynamic aliases (cleanup)
  rm -f $"($nu.temp-path)/($nu.pid)-dynamic_aliases.nu"
}

alias rm = rm -I

use ./potato *

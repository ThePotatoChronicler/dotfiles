$env.config.show_banner = false

if ("EDITOR" in $env) {
  $env.config.buffer_editor = $env.EDITOR
}

if ($env.HOME | path join "Scripts" | path exists) {
  use std/util "path add"
  path add ($env.HOME | path join "Scripts")
}

use (if $nu.is-interactive { "./interactive.nu" }) *

use ./potato *

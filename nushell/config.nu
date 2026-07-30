$env.config.show_banner = false

if ("EDITOR" in $env) {
  $env.config.buffer_editor = $env.EDITOR
}

if ($env.HOME | path join "Scripts" | path exists) {
  use std/util "path add"
  path add ($env.HOME | path join "Scripts")
}

let is_boxed = $env._POTATO_RUNBOXED? == "1"

if $nu.is-interactive {
  use std/util "path add"

  $env.PROMPT_COMMAND = {||
    let dir = match (do -i { $env.PWD | path relative-to $nu.home-dir }) {
      null => $env.PWD
      '' => '~'
      $relative_pwd => ([~ $relative_pwd] | path join)
    }

    let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
    [
      (if $is_boxed {
        $"(ansi blue)[B]"
      })
      $"($path_color)($dir)(ansi reset)"
    ] | compact | str join " "
  }
}

use (if $nu.is-interactive { "./interactive.nu" }) *

use ./potato *

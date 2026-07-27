use ./common.nu *

export def man [page?: string] {
  ^(pick_external batman | default man) ...([] | append $page)
}

export def cat [...files: string] {
  ^(pick_external bat | default cat) ...$files
}

export def btop [] {
  ^bwrap --ro-bind / / --bind ($env.HOME)/.config/btop ($env.HOME)/.config/btop -- btop
}

export alias rm = rm -I

use ./runboxed.nu

export alias r = runboxed

export def e [
  --can-bind-all
  --internet (-i)
  --dbus
  --gpu
  filename?: string
]: nothing -> any {
  (
    runboxed
      --can-bind-all=$can_bind_all
      --internet=$internet
      --dbus=$dbus
      --gpu=$gpu
      --edit-file=$filename
      --setsid
      --args=([$filename] | compact)
      $env.EDITOR
  )
}

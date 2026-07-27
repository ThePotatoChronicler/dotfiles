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

export use ./runboxed.nu *

export def e [
  --can-bind-all
  --internet (-i)
  --dbus
  --gpu
  filename?: string
]: nothing -> any {
  (
    r
      --can-bind-all=$can_bind_all
      --internet=$internet
      --dbus=$dbus
      --gpu=$gpu
      --edit-file=$filename
      --args=([$filename] | compact)
      $env.EDITOR
  )
}

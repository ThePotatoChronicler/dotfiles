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

# use ./runboxed.nu

extern runboxed [
  --can-bind-all      # Allow binding to overly-permissive folders, like /, /home, or $HOME
  --dbus              # Share dbus
  --edit-file: path   # Says that the executable is an editor, about to edit this file
  --gpu               # Share gpu
  --gui               # Shares things possibly necessary to run GUIs
  --internet (-i)     # Enable internet
  --setsid            # Creates new process group session (bwrap --new-session)
  --help (-h)         # Print help
  ...command: string,
]

export alias r = runboxed

export def e [
  --can-bind-all
  --internet (-i)
  --dbus
  --gpu
  filename?: string
]: nothing -> any {
  let args = ([$filename] | compact)

  if $env._POTATO_RUNBOXED? != "1" {
    (
      runboxed
        ...(if $can_bind_all { [--can-bind-all] })
        ...(if $internet { [--internet] })
        ...(if $dbus { [--dbus] })
        ...(if $gpu { [--gpu] })
        ...(if $filename != null {
          [--edit-file $filename]
        })
        --setsid
        --
        $env.EDITOR
        ...$args
    )
  } else {
    ^$env.EDITOR ...$args
  }
}

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
  --no-project        # Avoids binding a project
  --not-special       # Prevents special handling of certain programs  
  --setsid            # Creates new process group session (bwrap --new-session)
  --help (-h)         # Print help
  ...command: string,
]

export alias r = runboxed

export alias e = helix

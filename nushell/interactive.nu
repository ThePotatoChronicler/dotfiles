def defined_external [command: string]: nothing -> bool {
  which $"^($command)" | is-not-empty
}

def pick_external [
  ...commands: string
  ]: nothing -> string {
  $commands | each {|e| $"^($e)"} | which ...$in | get path | first
}

export def man [page?: string] {
  ^(pick_external batman | default man) ...([] | append $page)
}

export def cat [...files: string] {
  ^(pick_external bat | default cat) ...$files
}

def sudo_completer [spans: list<string>]: nothing -> any {
  $spans | to json | each {|e| $e + "\n"} | save --append /tmp/log.txt
  match ($spans | skip 1) {
    [$command] => {
      $command | commandline complete -d | select value? description? style?
    },
    [$command, ..$rest] => {
      [$command, ...$rest] | str join " " | collect | commandline complete -d | select value? description? style?
    }
  }
}

@complete sudo_completer
export def sudo --wrapped [
  command: string
  ...params: string
  ] {
  let cmd = if (not (defined_external sudo) and (defined_external doas)) {
    "doas"
  } else {
    "sudo"
  }

  ^$cmd -- $command ...$params
}

export def btop [] {
  ^bwrap --ro-bind / / --bind ($env.HOME)/.config/btop ($env.HOME)/.config/btop -- btop
}

def extract_project_directory [filename: string]: nothing -> oneof<string, nothing> {
  if (defined_external git) {
    let dir = $filename | path dirname
  
    let git_relative = ^git -C $dir rev-parse --show-cdup | complete

    if $git_relative.exit_code == 0 {
      let git_relative_to_dir = $git_relative.stdout | str replace --regex '\n$' ''
      let git_relative = [ $dir $git_relative_to_dir ] | path join
    
      return ($git_relative | path expand -n)
    }
  }

  if ($filename | path type) == dir {
    return $filename
  }
}

def is_protected_dir [filename: string]: nothing -> bool {
  [$env.HOME / /home] | any {|e| $e == $filename}
}

# FIXME: If files inside the directory, other than the file specified as filename, are symlinks, they won't be resolved
export def e [
  --can-bind-all = false
  filename?: string
] {
  let directory: string = (
    ( extract_project_directory ($filename | default { pwd }) )
    | default { $filename | path dirname }
  )

  let source = $directory | path expand
  let target = $directory | path expand -n

  # print $"Directory: '($directory)', Source: '($source)' Target: '($target)'"

  if not $can_bind_all and (is_protected_dir $source) {
    error make "Binding to $HOME, /home, or / allows the editor to access all your files. To proceed regardless, use --can-bind-all"
  }

  (
    ^bwrap
      --unshare-net
      --unshare-ipc
      --unshare-pid
      --unshare-cgroup-try
      --proc /proc
      --dev /dev
      --ro-bind-try /usr /usr
      --ro-bind-try /lib /lib
      --ro-bind-try /bin /bin
      --ro-bind-try /sbin /sbin
      --ro-bind-try /lib64 /lib64
      --ro-bind-try ($env.HOME)/.config/helix/config.toml ($env.HOME)/.config/helix/config.toml
      --ro-bind-try ($env.HOME)/.config/helix/languages.toml ($env.HOME)/.config/helix/languages.toml

      # For clipboard functionality
      ...(
        if (defined_external wl-copy) and ([ XDG_RUNTIME_DIR WAYLAND_DISPLAY ] | all {|k| $k in $env}) {
          mkdir /tmp/editor-tmp
          [
            --bind-try ($env.XDG_RUNTIME_DIR)/($env.WAYLAND_DISPLAY) ($env.XDG_RUNTIME_DIR)/($env.WAYLAND_DISPLAY)
            --bind /tmp/editor-tmp /.editor-tmp
            --setenv TMPDIR /.editor-tmp
          ]
        }
      )

      ...(
        if $filename != null and ($filename | path type) == symlink {
          # Using path expand here will expand too much,
          # we only need first layer, so we use readlink
          let dir = readlink --  $filename | path dirname

          if not $can_bind_all and (is_protected_dir $dir) {
            error make "Binding to $HOME, /home, or / allows the editor to access all your files. To proceed regardless, use --can-bind-all"
          }

          print $"Binding symlink target dir: '($dir)'"
          
          [--bind $dir $dir]
        }
      )

      --bind $source $target
      --
      $env.EDITOR ...([$filename] | compact)
  )
}

export alias rm = rm -I

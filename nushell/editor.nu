use ./common.nu *

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

def clipboard_opts []: nothing -> oneof<list<any>, nothing> {
  if (defined_external wl-copy) and ([ XDG_RUNTIME_DIR WAYLAND_DISPLAY ] | all {|k| $k in $env}) {
    mkdir /tmp/editor-tmp
    [
      --bind-try ($env.XDG_RUNTIME_DIR)/($env.WAYLAND_DISPLAY) ($env.XDG_RUNTIME_DIR)/($env.WAYLAND_DISPLAY)
      --bind /tmp/editor-tmp /.editor-tmp
      --setenv TMPDIR /.editor-tmp
    ]
  }
}

def symlink_opts [filename: oneof<string, nothing>, can_bind_all: bool]: nothing -> oneof<list<any>, nothing> {
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
}

# FIXME: If files inside the directory, other than the file specified as filename, are symlinks, they won't be resolved
export def e [
  --can-bind-all = false
  --override-executable: string
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

  let rustup_dir = $env.RUSTUP_HOME? | default { ($env.HOME)/.rustup }

  let rustup_path: oneof<string, nothing> = which rustup | get 0?.path

  let container_bin = "/.container_bin"

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

      # Adding a writable directory to path, so we can override commands
      --size (1MiB | into int | into string) --tmpfs $container_bin

      --setenv PATH ($env.PATH | prepend /.container_bin | str join :)

      # Helix editor config
      --ro-bind-try ($env.HOME)/.config/helix/config.toml ($env.HOME)/.config/helix/config.toml
      --ro-bind-try ($env.HOME)/.config/helix/languages.toml ($env.HOME)/.config/helix/languages.toml

      # Rustup
      --ro-bind-try $rustup_dir $rustup_dir
      ...(
        # Work-around for systems which don't have a rust-analyzer symlink proxy to rustup
        # For example, Arch doesn't have one
        if ($rustup_path != null) and not (defined_external rust-analyzer) {
          [
            --symlink $rustup_path ($container_bin | path join rust-analyzer)
          ]
        }
      )

      # Clipboard functionality
      ...(clipboard_opts)

      # Resolving symlinks, if we're editing a symlink file
      ...(symlink_opts $filename $can_bind_all)

      --bind $source $target
      --
      (if $override_executable != null { $override_executable } else $env.EDITOR)
      ...([$filename] | compact)
  )
}
